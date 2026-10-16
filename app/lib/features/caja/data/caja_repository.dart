import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/caja.dart';
import '../domain/calculos_caja.dart';

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

/// Acceso a `cajas`, `movimientos_caja` y `arqueos` (spec 009).
///
/// Las lecturas filtran por `empresaId` (lo exigen las reglas de Firestore) y
/// refinan en el cliente (usuario/estado/caja), sin índices compuestos.
class CajaRepository {
  CajaRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _cajas =>
      _db.collection('cajas');
  CollectionReference<Map<String, dynamic>> get _movimientos =>
      _db.collection('movimientos_caja');
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
    MedioPagoCaja medioPredominante = MedioPagoCaja.efectivo,
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

  /// Registra un **movimiento** en una caja abierta y recalcula el saldo
  /// (RF-03, ADR-005). El movimiento es inmutable (ADR-002).
  Future<void> registrarMovimiento({
    required String empresaId,
    required String cajaId,
    required TipoMovimientoCaja tipo,
    required String concepto,
    required double monto,
    required MedioPagoCaja medioPago,
    required ReferenciaCaja referenciaTipo,
    required String usuarioUid,
    String referenciaId = '',
    String responsableUid = '',
    EstadoDinero estadoDinero = EstadoDinero.enCaja,
    String empresaEnvio = '',
    String domiciliario = '',
  }) async {
    if (monto <= 0) {
      throw ArgumentError('El monto debe ser mayor que cero.');
    }
    final cajaRef = _cajas.doc(cajaId);
    final movRef = _movimientos.doc();

    await _db.runTransaction((Transaction tx) async {
      final snap = await tx.get(cajaRef);
      final data = snap.data();
      if (data == null) throw StateError('La caja no existe.');
      final caja = Caja.fromMap(cajaId, data);
      if (!caja.abierta) throw const CajaCerradaException();

      final saldoResultante = saldoConMovimiento(caja.saldo, tipo, monto);
      tx.update(cajaRef, <String, dynamic>{'saldo': saldoResultante});

      final mov = MovimientoCaja(
        id: movRef.id,
        empresaId: empresaId,
        cajaId: cajaId,
        tipo: tipo,
        concepto: concepto,
        monto: monto,
        medioPago: medioPago,
        referenciaTipo: referenciaTipo,
        referenciaId: referenciaId,
        responsableUid: responsableUid.isEmpty ? usuarioUid : responsableUid,
        estadoDinero: estadoDinero,
        empresaEnvio: empresaEnvio,
        domiciliario: domiciliario,
        saldoResultante: saldoResultante,
        usuarioUid: usuarioUid,
        fecha: DateTime.now(),
      );
      tx.set(movRef, mov.toMap());
    });

    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'movimientos_caja',
      documentoId: movRef.id,
      datos: <String, dynamic>{
        'tipo': tipo.id,
        'monto': monto,
        'concepto': concepto,
      },
    );
  }

  /// **Integración:** registra un **ingreso** si el usuario tiene caja abierta.
  ///
  /// Devuelve `true` si se registró (había caja abierta) o `false` si no
  /// (no bloquea la operación de origen). Ver nota en `tasks.md`.
  Future<bool> registrarIngresoSiAbierta({
    required String empresaId,
    required String usuarioUid,
    required double monto,
    required String concepto,
    required MedioPagoCaja medioPago,
    required ReferenciaCaja referenciaTipo,
    String referenciaId = '',
  }) async {
    if (monto <= 0) return false;
    final caja = await cajaAbierta(empresaId, usuarioUid);
    if (caja == null) return false;
    await registrarMovimiento(
      empresaId: empresaId,
      cajaId: caja.id,
      tipo: TipoMovimientoCaja.ingreso,
      concepto: concepto,
      monto: monto,
      medioPago: medioPago,
      referenciaTipo: referenciaTipo,
      referenciaId: referenciaId,
      usuarioUid: usuarioUid,
    );
    return true;
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
      final diferencia = calcularDiferenciaArqueo(totalContado, esperado);
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
        desgloseEfectivo: desglose,
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

  /// Movimientos de caja de una empresa (más recientes primero).
  Stream<List<MovimientoCaja>> movimientos(
    String empresaId, {
    String? cajaId,
  }) {
    return _movimientos
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) {
      final lista = _aListaMovs(snap);
      if (cajaId == null || cajaId.isEmpty) return lista;
      return lista
          .where((MovimientoCaja m) => m.cajaId == cajaId)
          .toList(growable: false);
    });
  }

  /// Movimientos para la **trazabilidad del dinero** (RF-10).
  Future<List<MovimientoCaja>> trazabilidad(
    String empresaId, {
    EstadoDinero? estadoDinero,
    String? responsableUid,
  }) async {
    final snap =
        await _movimientos.where('empresaId', isEqualTo: empresaId).get();
    return _aListaMovs(snap).where((MovimientoCaja m) {
      if (estadoDinero != null && m.estadoDinero != estadoDinero) return false;
      if (responsableUid != null &&
          responsableUid.isNotEmpty &&
          m.responsableUid != responsableUid) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Saldo consolidado de las cajas **abiertas** (RF-10).
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

  List<MovimientoCaja> _aListaMovs(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            MovimientoCaja.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((MovimientoCaja a, MovimientoCaja b) =>
        (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
    return lista;
  }
}
