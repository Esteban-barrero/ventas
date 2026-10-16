import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/proveedor.dart';

/// Ya existe un proveedor con ese NIT en la empresa (RN-07).
class NitDuplicadoException implements Exception {
  const NitDuplicadoException(this.nit);

  final String nit;

  @override
  String toString() => 'Ya existe un proveedor con el NIT "$nit".';
}

/// Acceso a la colección `proveedores` (spec 007). Multi-tenant.
class ProveedoresRepository {
  ProveedoresRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _proveedores =>
      _db.collection('proveedores');

  String nuevoId() => _proveedores.doc().id;

  Stream<List<Proveedor>> escuchar(String empresaId) {
    return _proveedores
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map(_aLista);
  }

  Future<List<Proveedor>> listar(
    String empresaId, {
    String? busqueda,
    bool soloActivos = false,
  }) async {
    final snap =
        await _proveedores.where('empresaId', isEqualTo: empresaId).get();
    return filtrar(_aLista(snap), busqueda: busqueda, soloActivos: soloActivos);
  }

  static List<Proveedor> filtrar(
    List<Proveedor> proveedores, {
    String? busqueda,
    bool soloActivos = false,
  }) {
    final q = (busqueda ?? '').trim().toLowerCase();
    return proveedores.where((Proveedor p) {
      if (soloActivos && !p.activo) return false;
      if (q.isNotEmpty) {
        final nombre = p.nombre.toLowerCase();
        final nit = p.nit.toLowerCase();
        if (!nombre.contains(q) && !nit.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  Future<Proveedor?> obtener(String proveedorId) async {
    final doc = await _proveedores.doc(proveedorId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Proveedor.fromMap(doc.id, doc.data()!);
  }

  /// Busca un proveedor por NIT dentro de una empresa.
  Future<Proveedor?> porNit(String empresaId, String nit) async {
    final objetivo = nit.trim().toLowerCase();
    if (objetivo.isEmpty) return null;
    final lista = await listar(empresaId);
    for (final p in lista) {
      if (p.nit.trim().toLowerCase() == objetivo) return p;
    }
    return null;
  }

  Future<String> crear(Proveedor proveedor) async {
    if (proveedor.nombre.trim().isEmpty) {
      throw ArgumentError('El nombre del proveedor es obligatorio.');
    }
    final nit = proveedor.nit.trim();
    if (nit.isNotEmpty &&
        await porNit(proveedor.empresaId, nit) != null) {
      throw NitDuplicadoException(nit);
    }
    final ref = proveedor.id.isNotEmpty
        ? _proveedores.doc(proveedor.id)
        : _proveedores.doc();
    final datos = proveedor.toMap()..['id'] = ref.id;
    await ref.set(datos);
    await _auditoria.registrarEvento(
      empresaId: proveedor.empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'proveedores',
      documentoId: ref.id,
      datos: datos,
    );
    return ref.id;
  }

  Future<void> actualizar(Proveedor proveedor) async {
    final ref = _proveedores.doc(proveedor.id);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};
    final despues = proveedor.toMap();
    final antesParcial = <String, dynamic>{
      for (final clave in despues.keys) clave: antes[clave],
    };
    await ref.set(despues, SetOptions(merge: true));
    await _auditoria.registrarCambios(
      empresaId: proveedor.empresaId,
      tabla: 'proveedores',
      documentoId: proveedor.id,
      antes: antesParcial,
      despues: despues,
    );
  }

  Future<void> activar(String proveedorId, bool activo, {String? empresaId}) async {
    final ref = _proveedores.doc(proveedorId);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};
    final empresa = empresaId ?? (antes['empresaId'] as String?) ?? '';
    final despues = <String, dynamic>{'activo': activo};
    await ref.update(despues);
    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'proveedores',
      documentoId: proveedorId,
      antes: <String, dynamic>{'activo': antes['activo']},
      despues: despues,
    );
  }

  List<Proveedor> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            Proveedor.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((Proveedor a, Proveedor b) =>
        a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }
}
