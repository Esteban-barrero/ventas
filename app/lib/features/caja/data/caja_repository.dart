import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../../tesoreria/data/tesoreria_repository.dart';
import '../../tesoreria/domain/movimiento_dinero.dart';
import '../domain/caja.dart';

/// Ya hay una caja abierta para el usuario (RN-03).
class CajaYaAbiertaException implements Exception {
  const CajaYaAbiertaException();

  @override
  String toString() => 'Ya tienes una caja abierta.';
}

/// La caja no está abierta (RN-02, RN-08).
class CajaCerradaException implements Exception {
  const CajaCerradaException();

  @override
  String toString() => 'No hay una caja abierta para registrar el movimiento.';
}

/// El cierre con diferencia exige justificación (RN-05).
class JustificacionRequeridaException implements Exception {
  const JustificacionRequeridaException();

  @override
  String toString() => 'Debes justificar la diferencia del arqueo.';
}

/// Caja por turno (spec 009) sobre el **libro único** `movimientos_dinero`
/// (spec 016). Las lecturas filtran por `empresaId` y refinan en el cliente.
class CajaRepository {
  CajaRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
    TesoreriaRepository? tesoreria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository(),
        _tesoreria = tesoreria ?? TesoreriaRepository(firestore: firestore);

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;
  final TesoreriaRepository _tesoreria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _cajas =>
      _db.collection('cajas');
  CollectionReference<Map<String, dynamic>> get _arqueos =>
      _db.collection('arqueos');

  /// Escucha la **caja abierta** del usuario (o `null` si no tiene).
  Stream<Caja?> escucharAbierta(String empresaId, String usuarioUid) {
    return _cajas
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) {
      for (final Caja c in _aListaCajas(snap)) {
        if (c.usuarioUid == usuarioUid && c.abierta) return c;
      }
      return null;
    });
  }

  /// Caja abierta del usuario (o `null`).
  Future<Caja?> cajaAbierta(String empresaId, String usuarioUid) async {
    for (final Caja c in await _leerCajas(empresaId)) {
      if (c.usuarioUid == usuarioUid && c.abierta) return c;
    }
    return null;
  }

  /// Abre una caja con monto inicial (RF-01). Falla si el usuario ya tiene una
  /// abierta (RN-03).
  Future<String> abrirCaja({
    required String empresaId,
    required String usuarioUid,
    required String usuarioNombre,
    required double montoInicial,
    MedioDinero medioPredominante = MedioDinero.efectivo,
  }) async {
    if (await cajaAbierta(empresaId, usuarioUid) != null) {
      throw const CajaYaAbiertaException();
    }
    final ref = _cajas.doc();
    final caja = Caja(
      id: ref.id,
      empresaId: empresaId,
      nombre: 'Caja de ${usuarioNombre.isEmpty ? 'usuario' : usuarioNombre}',
      usuarioUid: usuarioUid,
      usuarioNombre: usuarioNombre,
      estado: EstadoCaja.abierta,
      montoInicial: montoInicial,
      saldo: montoInicial,
      medioPredominante: medioPredominante,
      fechaApertura: DateTime.now(),
    );
    await ref.set(caja.toMap());
    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'cajas',
      documentoId: ref.id,
      datos: <String, dynamic>{'montoInicial': montoInicial},
    );
    return ref.id;
  }

  /// Registra un **movimiento** del turno (ingreso/egreso) en el libro único,
  /// actualizando el saldo en la misma transacción (RF-03, spec 016).
  Future<void> registrarMovimiento({
    required String empresaId,
    required String cajaId,
    required TipoMovimientoDinero tipo,
    required String concepto,
    required double monto,
    required MedioDinero medioPago,
    required ReferenciaDinero referenciaTipo,
    required String usuarioUid,
    String usuarioNombre = '',
    String responsableUid = '',
    String responsableNombre = '',
    String referenciaId = '',
  }) async {
    await _tesoreria.registrarMovimiento(
      empresaId: empresaId,
      tipo: tipo,
      monto: monto,
      ubicacion: UbicacionDinero.cajaFisica,
      medioPago: medioPago,
      referenciaTipo: referenciaTipo,
      usuarioUid: usuarioUid,
      usuarioNombre: usuarioNombre,
      responsableUid: responsableUid,
      responsableNombre: responsableNombre,
      descripcion: concepto,
      referenciaId: referenciaId,
      cajaId: cajaId,
    );
  }

  /// Cierra la caja con **arqueo** y diferencia (RF-02, RF-08, RF-09).
  Future<Arqueo> cerrarCaja({
    required String empresaId,
    required String cajaId,
    required double totalContado,
    required String usuarioUid,
    String justificacion = '',
    Map<String, num> desglose = const <String, num>{},
  }) async {
    final cajaRef = _cajas.doc(cajaId);
    final arqueoRef = _arqueos.doc();
    Arqueo? arqueo;

    await _db.runTransaction((Transaction tx) async {
      final snap = await tx.get(cajaRef);
      final data = snap.data();
      if (data == null) throw StateError('La caja no existe.');
      final caja = Caja.fromMap(cajaId, data);
      if (!caja.abierta) throw const CajaCerradaException();

      final esperado = caja.saldo;
      final diferencia = totalContado - esperado;
      if (diferencia.abs() > 0.001 && justificacion.trim().isEmpty) {
        throw const JustificacionRequeridaException();
      }

      arqueo = Arqueo(
        id: arqueoRef.id,
        empresaId: empresaId,
        cajaId: cajaId,
        fecha: DateTime.now(),
        totalEsperado: esperado,
        totalContado: totalContado,
        diferencia: diferencia,
        justificacion: justificacion,
        desglose: desglose,
        usuarioUid: usuarioUid,
      );
      tx.set(arqueoRef, arqueo!.toMap());
      tx.update(cajaRef, <String, dynamic>{
        'estado': EstadoCaja.cerrada.id,
        'fechaCierre': DateTime.now().toUtc().toIso8601String(),
        'cerradoPor': usuarioUid,
        'diferenciaCierre': diferencia,
      });
    });

    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'arqueos',
      documentoId: arqueoRef.id,
      datos: <String, dynamic>{
        'cajaId': cajaId,
        'totalContado': totalContado,
        'justificacion': justificacion,
      },
    );
    return arqueo!;
  }

  /// Movimientos del libro (opcionalmente de un turno).
  Stream<List<MovimientoDinero>> movimientos(String empresaId, {String? cajaId}) {
    if (cajaId == null || cajaId.isEmpty) {
      return _tesoreria.escucharMovimientos(empresaId);
    }
    return _tesoreria.escucharDeCaja(empresaId, cajaId);
  }

  /// Saldo consolidado de las cajas **abiertas**.
  Future<double> saldoConsolidado(String empresaId) async {
    final cajas = await _leerCajas(empresaId);
    return cajas
        .where((Caja c) => c.abierta)
        .fold<double>(0, (double a, Caja c) => a + c.saldo);
  }

  Future<List<Caja>> _leerCajas(String empresaId) async {
    final snap = await _cajas.where('empresaId', isEqualTo: empresaId).get();
    return _aListaCajas(snap);
  }

  List<Caja> _aListaCajas(QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
      .map((DocumentSnapshot<Map<String, dynamic>> d) =>
          Caja.fromMap(d.id, d.data()!))
      .toList(growable: false);
}
