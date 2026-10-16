import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/movimiento_dinero.dart';
import '../domain/posiciones.dart';
import '../domain/rendicion.dart';

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

  CollectionReference<Map<String, dynamic>> get _rendiciones =>
      _db.collection('rendiciones');

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

  /// **Declara** una rendición de efectivo (el domiciliario dice cuánto tiene).
  /// El dinero **no** se mueve hasta que se confirme.
  Future<String> declararRendicion({
    required String empresaId,
    required String domiciliarioUid,
    required String domiciliarioNombre,
    required double montoDeclarado,
    String recibidoPorUid = '',
    String recibidoPorNombre = '',
    String observaciones = '',
  }) async {
    if (montoDeclarado <= 0) {
      throw ArgumentError('El monto debe ser mayor que cero.');
    }
    final ref = _rendiciones.doc();
    final r = Rendicion(
      id: ref.id,
      empresaId: empresaId,
      fecha: DateTime.now(),
      domiciliarioUid: domiciliarioUid,
      domiciliarioNombre: domiciliarioNombre,
      montoDeclarado: montoDeclarado,
      estado: EstadoRendicion.pendiente,
      recibidoPorUid: recibidoPorUid,
      recibidoPorNombre: recibidoPorNombre,
      observaciones: observaciones,
    );
    await ref.set(r.toMap());
    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'rendiciones',
      documentoId: ref.id,
      datos: <String, dynamic>{
        'domiciliarioUid': domiciliarioUid,
        'montoDeclarado': montoDeclarado,
      },
    );
    return ref.id;
  }

  /// Escucha las rendiciones de la empresa (opcionalmente por estado).
  Stream<List<Rendicion>> escucharRendiciones(
    String empresaId, {
    EstadoRendicion? estado,
    String? domiciliarioUid,
  }) {
    return _rendiciones
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) {
      final lista = snap.docs
          .map((DocumentSnapshot<Map<String, dynamic>> d) =>
              Rendicion.fromMap(d.id, d.data()!))
          .where((Rendicion r) {
        if (estado != null && r.estado != estado) return false;
        if (domiciliarioUid != null && r.domiciliarioUid != domiciliarioUid) {
          return false;
        }
        return true;
      }).toList();
      lista.sort((Rendicion a, Rendicion b) =>
          (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
      return lista;
    });
  }

  /// **Confirma** una rendición (el responsable cuenta el efectivo). Mueve el
  /// dinero `vendedorEfectivo` → `cajaFisica` por el monto **contado** y deja
  /// constancia de quién recibió (RF-05). Exige justificar la diferencia.
  Future<void> confirmarRendicion({
    required String rendicionId,
    required String empresaId,
    required String recibidoPorUid,
    required String recibidoPorNombre,
    required double montoContado,
    String justificacion = '',
  }) async {
    final ref = _rendiciones.doc(rendicionId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw StateError('La rendición no existe.');
    final r = Rendicion.fromMap(rendicionId, data);
    if (!r.pendiente) {
      throw StateError('La rendición ya fue procesada.');
    }
    final diferencia = r.montoDeclarado - montoContado;
    if (diferencia.abs() > 0.001 && justificacion.trim().isEmpty) {
      throw ArgumentError('Debes justificar la diferencia de la rendición.');
    }
    if (montoContado > 0) {
      await trasladar(
        empresaId: empresaId,
        monto: montoContado,
        origen: UbicacionDinero.vendedorEfectivo,
        destino: UbicacionDinero.cajaFisica,
        usuarioUid: recibidoPorUid,
        usuarioNombre: recibidoPorNombre,
        responsableUid: r.domiciliarioUid,
        responsableNombre: r.domiciliarioNombre,
        descripcion: 'Rendición de ${r.domiciliarioNombre}',
        referenciaId: rendicionId,
      );
    }
    await ref.update(<String, dynamic>{
      'estado': EstadoRendicion.confirmada.id,
      'recibidoPorUid': recibidoPorUid,
      'recibidoPorNombre': recibidoPorNombre,
      'montoContado': montoContado,
      'diferencia': diferencia,
      'justificacion': justificacion,
      'fechaConfirmacion': DateTime.now().toUtc().toIso8601String(),
    });
    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.update,
      tabla: 'rendiciones',
      documentoId: rendicionId,
      datos: <String, dynamic>{
        'estado': EstadoRendicion.confirmada.id,
        'recibidoPorUid': recibidoPorUid,
        'montoContado': montoContado,
        'diferencia': diferencia,
      },
    );
  }

  /// **Rechaza** una rendición (el responsable no la acepta).
  Future<void> rechazarRendicion({
    required String rendicionId,
    required String empresaId,
    required String usuarioUid,
    String motivo = '',
  }) async {
    await _rendiciones.doc(rendicionId).update(<String, dynamic>{
      'estado': EstadoRendicion.rechazada.id,
      'justificacion': motivo,
      'fechaConfirmacion': DateTime.now().toUtc().toIso8601String(),
    });
    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.update,
      tabla: 'rendiciones',
      documentoId: rendicionId,
      datos: <String, dynamic>{
        'estado': EstadoRendicion.rechazada.id,
        'porUid': usuarioUid,
      },
    );
  }

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
