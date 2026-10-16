import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/movimiento_dinero.dart';
import '../domain/posiciones.dart';

/// El saldo de la ubicación de origen no alcanza para el traslado (RN-03).
class SaldoInsuficienteException implements Exception {
  const SaldoInsuficienteException(this.ubicacion);

  final UbicacionDinero ubicacion;

  @override
  String toString() =>
      'No hay dinero suficiente en "${ubicacion.nombre}" para el traslado.';
}

/// Acceso al **libro único del dinero** `movimientos_dinero` (spec 016).
///
/// Las lecturas filtran por `empresaId` (lo exigen las reglas de Firestore) y
/// el cálculo de posiciones se hace en el cliente.
class TesoreriaRepository {
  TesoreriaRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _movs =>
      _db.collection('movimientos_dinero');

  CollectionReference<Map<String, dynamic>> get _cajas => _db.collection('cajas');

  /// Escucha el libro de movimientos de la empresa (más recientes primero).
  Stream<List<MovimientoDinero>> escucharMovimientos(String empresaId) {
    return _movs
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) => _aLista(snap));
  }

  /// Lee el libro de movimientos de la empresa.
  Future<List<MovimientoDinero>> movimientos(String empresaId) async {
    final snap = await _movs.where('empresaId', isEqualTo: empresaId).get();
    return _aLista(snap);
  }

  /// Movimientos de un **turno de caja** (spec 009).
  Stream<List<MovimientoDinero>> escucharDeCaja(String empresaId, String cajaId) {
    return escucharMovimientos(empresaId).map(
      (List<MovimientoDinero> lista) => lista
          .where((MovimientoDinero m) => m.cajaId == cajaId)
          .toList(growable: false),
    );
  }

  /// Saldo por ubicación (RF-03).
  Future<Map<UbicacionDinero, double>> posiciones(String empresaId) async =>
      calcularPosiciones(await movimientos(empresaId));

  /// Total del dinero de la empresa (RF-03).
  Future<double> total(String empresaId) async =>
      totalDePosiciones(await posiciones(empresaId));

  /// Registra un movimiento de dinero (RF-01). El movimiento es inmutable.
  ///
  /// Si se indica `cajaId` (turno, ubicación `cajaFisica`), actualiza el saldo
  /// del turno en la misma transacción.
  Future<String> registrarMovimiento({
    required String empresaId,
    required TipoMovimientoDinero tipo,
    required double monto,
    required UbicacionDinero ubicacion,
    UbicacionDinero? ubicacionDestino,
    required MedioDinero medioPago,
    required ReferenciaDinero referenciaTipo,
    required String usuarioUid,
    String referenciaId = '',
    String responsableUid = '',
    String responsableNombre = '',
    String descripcion = '',
    String cajaId = '',
    String usuarioNombre = '',
  }) async {
    if (monto <= 0) {
      throw ArgumentError('El monto debe ser mayor que cero.');
    }
    // Si el dinero entra/sale de la caja física y el usuario tiene un turno
    // abierto, el movimiento se asocia a ese turno (spec 009).
    var cajaEfectiva = cajaId;
    if (cajaEfectiva.isEmpty && ubicacion == UbicacionDinero.cajaFisica) {
      cajaEfectiva = await _cajaAbiertaDe(empresaId, usuarioUid);
    }

    final ref = _movs.doc();
    final mov = MovimientoDinero(
      id: ref.id,
      empresaId: empresaId,
      fecha: DateTime.now(),
      tipo: tipo,
      monto: monto,
      medioPago: medioPago,
      ubicacion: ubicacion,
      ubicacionDestino: ubicacionDestino,
      responsableUid: responsableUid,
      responsableNombre: responsableNombre,
      descripcion: descripcion,
      referenciaTipo: referenciaTipo,
      referenciaId: referenciaId,
      cajaId: cajaEfectiva,
      usuarioUid: usuarioUid,
      usuarioNombre: usuarioNombre,
    );

    if (cajaEfectiva.isEmpty) {
      await ref.set(mov.toMap());
    } else {
      final cajaRef = _cajas.doc(cajaEfectiva);
      await _db.runTransaction((Transaction tx) async {
        final snap = await tx.get(cajaRef);
        final data = snap.data();
        if (data == null) throw StateError('La caja no existe.');
        if ((data['estado'] as String?) == 'cerrada') {
          throw StateError('La caja está cerrada.');
        }
        final saldo = (data['saldo'] as num?)?.toDouble() ?? 0;
        final delta = tipo == TipoMovimientoDinero.ingreso ? monto : -monto;
        tx.set(ref, mov.toMap());
        tx.update(cajaRef, <String, dynamic>{'saldo': saldo + delta});
      });
    }

    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'movimientos_dinero',
      documentoId: ref.id,
      datos: <String, dynamic>{
        'tipo': tipo.id,
        'monto': monto,
        'ubicacion': ubicacion.id,
        'referenciaTipo': referenciaTipo.id,
      },
    );
    return ref.id;
  }

  /// **Traslada** dinero entre ubicaciones (RF-05, RN-02, RN-03). El total no
  /// cambia; el saldo del origen no puede quedar negativo.
  Future<String> trasladar({
    required String empresaId,
    required double monto,
    required UbicacionDinero origen,
    required UbicacionDinero destino,
    required String usuarioUid,
    String descripcion = '',
    String usuarioNombre = '',
    String responsableUid = '',
    String responsableNombre = '',
    String referenciaId = '',
  }) async {
    if (origen == destino) {
      throw ArgumentError('El origen y el destino deben ser diferentes.');
    }
    final actuales = await posiciones(empresaId);
    if ((actuales[origen] ?? 0) + 0.001 < monto) {
      throw SaldoInsuficienteException(origen);
    }
    return registrarMovimiento(
      empresaId: empresaId,
      tipo: TipoMovimientoDinero.traslado,
      monto: monto,
      ubicacion: origen,
      ubicacionDestino: destino,
      medioPago: MedioDinero.efectivo,
      referenciaTipo: ReferenciaDinero.traslado,
      usuarioUid: usuarioUid,
      usuarioNombre: usuarioNombre,
      responsableUid: responsableUid,
      responsableNombre: responsableNombre,
      descripcion: descripcion,
      referenciaId: referenciaId,
    );
  }

  /// Caja (turno) abierta del usuario, o cadena vacía si no tiene.
  Future<String> _cajaAbiertaDe(String empresaId, String usuarioUid) async {
    if (usuarioUid.isEmpty) return '';
    final snap = await _cajas.where('empresaId', isEqualTo: empresaId).get();
    for (final DocumentSnapshot<Map<String, dynamic>> d in snap.docs) {
      final data = d.data() ?? const <String, dynamic>{};
      if ((data['estado'] as String?) == 'abierta' &&
          (data['usuarioUid'] as String?) == usuarioUid) {
        return d.id;
      }
    }
    return '';
  }

  List<MovimientoDinero> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            MovimientoDinero.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((MovimientoDinero a, MovimientoDinero b) =>
        (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
    return lista;
  }
}
