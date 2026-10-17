import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auditoria.dart';

/// Escribe registros en la colección `_auditoria` (spec 001, T033).
///
/// Nota de seguridad: la colección es de solo inserción (las reglas de
/// Firestore no permiten editar ni borrar). Cuando las Cloud Functions estén
/// desplegadas, el trigger del servidor también registrará la auditoría de
/// forma autoritativa; aquí se cubre el cambio hecho desde el cliente.
class AuditoriaRepository {
  AuditoriaRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestoreOverride = firestore,
        _authOverride = auth;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseAuth? _authOverride;

  FirebaseFirestore get _db =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _coleccion =>
      _db.collection('_auditoria');

  /// Registra los campos que cambiaron entre `antes` y `despues`.
  ///
  /// Devuelve la cantidad de registros escritos.
  Future<int> registrarCambios({
    required String empresaId,
    required String tabla,
    required String documentoId,
    required Map<String, dynamic> antes,
    required Map<String, dynamic> despues,
    String? autor,
  }) async {
    final cambios = calcularCambios(antes, despues);
    if (cambios.isEmpty) return 0;

    final batch = _db.batch();
    for (final cambio in cambios) {
      batch.set(
        _coleccion.doc(),
        _registro(
          empresaId: empresaId,
          operacion: OperacionAuditoria.update,
          tabla: tabla,
          documentoId: documentoId,
          campo: cambio.campo,
          valorViejo: cambio.valorViejo,
          valorNuevo: cambio.valorNuevo,
          autor: autor,
        ),
      );
    }
    await batch.commit();
    return cambios.length;
  }

  /// Registra un alta ([OperacionAuditoria.insert]) o baja (delete) completa.
  Future<void> registrarEvento({
    required String empresaId,
    required OperacionAuditoria operacion,
    required String tabla,
    required String documentoId,
    required Map<String, dynamic> datos,
    String? autor,
  }) async {
    await _coleccion.add(
      _registro(
        empresaId: empresaId,
        operacion: operacion,
        tabla: tabla,
        documentoId: documentoId,
        valorNuevo: operacion == OperacionAuditoria.delete ? null : datos,
        valorViejo: operacion == OperacionAuditoria.delete ? datos : null,
        autor: autor,
      ),
    );
  }

  /// Escucha los registros de auditoría de una empresa (más recientes primero).
  Stream<List<RegistroAuditoria>> escuchar(String empresaId) {
    return _coleccion
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map(_aLista);
  }

  /// Lista la auditoría de una empresa con filtros (spec 012, RF-07).
  Future<List<RegistroAuditoria>> listar(
    String empresaId, {
    String? busqueda,
    String? operacion,
    String? tabla,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final snap =
        await _coleccion.where('empresaId', isEqualTo: empresaId).get();
    return filtrar(
      _aLista(snap),
      busqueda: busqueda,
      operacion: operacion,
      tabla: tabla,
      desde: desde,
      hasta: hasta,
    );
  }

  /// Filtra por texto, operación, tabla y rango de fechas.
  static List<RegistroAuditoria> filtrar(
    List<RegistroAuditoria> registros, {
    String? busqueda,
    String? operacion,
    String? tabla,
    DateTime? desde,
    DateTime? hasta,
  }) {
    final q = (busqueda ?? '').trim().toLowerCase();
    return registros.where((RegistroAuditoria r) {
      if (operacion != null &&
          operacion.isNotEmpty &&
          r.operacion != operacion) {
        return false;
      }
      if (tabla != null && tabla.isNotEmpty && r.tabla != tabla) return false;
      if (desde != null &&
          (r.fecha == null || r.fecha!.isBefore(_dia(desde)))) {
        return false;
      }
      if (hasta != null) {
        final limite = _dia(hasta).add(const Duration(days: 1));
        if (r.fecha == null || !r.fecha!.isBefore(limite)) return false;
      }
      if (q.isNotEmpty) {
        final texto = '${r.usuario} ${r.tabla} ${r.documentoId} ${r.campo} '
                '${textoValor(r.valorViejo)} ${textoValor(r.valorNuevo)}'
            .toLowerCase();
        if (!texto.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  List<RegistroAuditoria> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            RegistroAuditoria.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((RegistroAuditoria a, RegistroAuditoria b) =>
        (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
    return lista;
  }

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<String, dynamic> _registro({
    required String empresaId,
    required OperacionAuditoria operacion,
    required String tabla,
    required String documentoId,
    String? campo,
    dynamic valorViejo,
    dynamic valorNuevo,
    String? autor,
  }) {
    return <String, dynamic>{
      'empresaId': empresaId,
      'usuario': autor ?? _auth.currentUser?.uid ?? 'desconocido',
      'fecha': FieldValue.serverTimestamp(),
      'operacion': operacion.id,
      'tabla': tabla,
      'documentoId': documentoId,
      'campo': campo,
      'valorViejo': valorViejo,
      'valorNuevo': valorNuevo,
    };
  }
}
