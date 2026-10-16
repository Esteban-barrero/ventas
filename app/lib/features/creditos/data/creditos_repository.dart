import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../../ventas/domain/venta.dart' show MedioPago;
import '../domain/credito.dart';

/// Acceso a `creditos`, su subcolección `cuotas` y `pagos_credito` (spec 006).
///
/// La creación desde una venta y cada **pago** corren en una **transacción**
/// (ADR-002): actualizan cuotas, crédito y registran el pago de forma atómica.
/// Las cuotas usan ids deterministas (`c001`, `c002`, …) para poder leerlas por
/// id dentro de la transacción.
class CreditosRepository {
  CreditosRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _creditos =>
      _db.collection('creditos');
  CollectionReference<Map<String, dynamic>> get _pagos =>
      _db.collection('pagos_credito');

  /// Id determinista de una cuota (`c001`, `c002`, …).
  static String idCuota(int numero) => 'c${numero.toString().padLeft(3, '0')}';

  /// Escucha, en tiempo real, los créditos de una empresa.
  Stream<List<Credito>> escuchar(String empresaId) {
    return _creditos
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map(_aLista);
  }

  /// Lista los créditos de una empresa con filtros opcionales.
  Future<List<Credito>> listar(
    String empresaId, {
    String? busqueda,
    EstadoCredito? estado,
    String? clienteId,
  }) async {
    final snap = await _creditos.where('empresaId', isEqualTo: empresaId).get();
    return filtrar(_aLista(snap),
        busqueda: busqueda, estado: estado, clienteId: clienteId);
  }

  /// Filtra créditos por búsqueda (cliente), estado y cliente.
  static List<Credito> filtrar(
    List<Credito> creditos, {
    String? busqueda,
    EstadoCredito? estado,
    String? clienteId,
  }) {
    final q = (busqueda ?? '').trim().toLowerCase();
    return creditos.where((Credito c) {
      if (estado != null && c.estado != estado) return false;
      if (clienteId != null && clienteId.isNotEmpty && c.clienteId != clienteId) {
        return false;
      }
      if (q.isNotEmpty && !c.clienteNombre.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Obtiene un crédito por su id.
  Future<Credito?> obtener(String creditoId) async {
    final doc = await _creditos.doc(creditoId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Credito.fromMap(doc.id, doc.data()!);
  }

  /// Escucha las cuotas de un crédito, ordenadas por número.
  Stream<List<Cuota>> escucharCuotas(String creditoId) {
    return _creditos
        .doc(creditoId)
        .collection('cuotas')
        .orderBy('numero')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
            .map((DocumentSnapshot<Map<String, dynamic>> d) =>
                Cuota.fromMap(d.data()!))
            .toList(growable: false));
  }

  /// Crea el crédito (y su plan de cuotas) a partir de una **venta a crédito**
  /// (RF-01, CA-01). Actualiza `venta.creditoId`. Devuelve el id del crédito.
  Future<String> crearDesdeVenta(
    String ventaId, {
    required int numeroCuotas,
    required Periodicidad periodicidad,
    double tasaInteres = 0,
    DateTime? fechaPrimerPago,
  }) async {
    final ventaRef = _db.collection('ventas').doc(ventaId);
    final creditoRef = _creditos.doc();
    var empresa = '';

    await _db.runTransaction((Transaction tx) async {
      final ventaSnap = await tx.get(ventaRef);
      final venta = ventaSnap.data();
      if (venta == null) throw StateError('La venta no existe.');
      empresa = (venta['empresaId'] as String?) ?? '';
      final total = (venta['total'] as num?)?.toDouble() ?? 0;
      final primer =
          fechaPrimerPago ?? sumarPeriodicidad(DateTime.now(), 1, periodicidad);

      final cuotas = generarCuotas(
        monto: total,
        numeroCuotas: numeroCuotas,
        periodicidad: periodicidad,
        fechaPrimerPago: primer,
        tasaInteres: tasaInteres,
      );
      final conInteres = cuotas.fold<double>(0, (double a, Cuota c) => a + c.monto);

      final credito = Credito(
        id: creditoRef.id,
        empresaId: empresa,
        clienteId: (venta['clienteId'] as String?) ?? '',
        clienteNombre: (venta['clienteNombre'] as String?) ?? 'Consumidor final',
        clienteUid: venta['clienteUid'] as String?,
        ventaId: ventaId,
        montoTotal: total,
        tasaInteres: tasaInteres,
        montoConInteres: conInteres,
        numeroCuotas: numeroCuotas,
        periodicidad: periodicidad,
        fechaPrimerPago: primer,
        saldoActual: conInteres,
        aprobado: false,
        estado: EstadoCredito.activo,
      );

      tx.set(creditoRef, credito.toMap());
      for (final c in cuotas) {
        tx.set(creditoRef.collection('cuotas').doc(idCuota(c.numero)), c.toMap());
      }
      tx.update(ventaRef, <String, dynamic>{'creditoId': creditoRef.id});
    });

    await _auditoria.registrarEvento(
      empresaId: empresa,
      operacion: OperacionAuditoria.insert,
      tabla: 'creditos',
      documentoId: creditoRef.id,
      datos: <String, dynamic>{
        'ventaId': ventaId,
        'numeroCuotas': numeroCuotas,
        'periodicidad': periodicidad.id,
        'tasaInteres': tasaInteres,
      },
    );
    return creditoRef.id;
  }

  /// Aprueba (o rechaza) un crédito (RF-04, CA-03).
  Future<void> aprobar(String creditoId, {required String aprobadoPor}) async {
    final ref = _creditos.doc(creditoId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw StateError('El crédito no existe.');
    final empresa = (data['empresaId'] as String?) ?? '';
    final cambios = <String, dynamic>{
      'aprobado': true,
      'aprobadoPor': aprobadoPor,
      'fechaAprobacion': DateTime.now().toUtc().toIso8601String(),
    };
    await ref.update(cambios);
    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'creditos',
      documentoId: creditoId,
      antes: <String, dynamic>{'aprobado': data['aprobado']},
      despues: cambios,
    );
  }

  /// Registra un pago o abono (RF-05). Aplica a las cuotas más antiguas, baja el
  /// saldo y marca el crédito como pagado si queda en cero (CA-04, CA-06).
  Future<void> registrarPago(
    String creditoId,
    double monto,
    MedioPago medioPago, {
    String cobradorUid = '',
    String notas = '',
  }) async {
    if (monto <= 0) throw ArgumentError('El monto debe ser mayor que cero.');
    final creditoRef = _creditos.doc(creditoId);
    final pagoRef = _pagos.doc();
    var empresa = '';
    var clienteId = '';

    await _db.runTransaction((Transaction tx) async {
      final creditoSnap = await tx.get(creditoRef);
      final data = creditoSnap.data();
      if (data == null) throw StateError('El crédito no existe.');
      final credito = Credito.fromMap(creditoId, data);
      empresa = credito.empresaId;
      clienteId = credito.clienteId;
      if (credito.pagado) throw StateError('El crédito ya está pagado.');
      if (credito.cancelado) throw StateError('El crédito está cancelado.');

      // Leer cuotas por id determinista.
      final refs = <DocumentReference<Map<String, dynamic>>>[];
      final cuotas = <Cuota>[];
      for (var i = 1; i <= credito.numeroCuotas; i++) {
        final ref = creditoRef.collection('cuotas').doc(idCuota(i));
        final snap = await tx.get(ref);
        if (!snap.exists) continue;
        refs.add(ref);
        cuotas.add(Cuota.fromMap(snap.data()!));
      }

      var restante = monto;
      var aplicado = 0.0;
      for (var i = 0; i < cuotas.length; i++) {
        final cuota = cuotas[i];
        if (cuota.estaPagada || restante <= 0) continue;
        final aplicar = restante >= cuota.saldo ? cuota.saldo : restante;
        final nuevoPagado = cuota.pagado + aplicar;
        final quedaPagada = (cuota.monto - nuevoPagado) <= 0.001;
        final nuevoEstado =
            quedaPagada ? EstadoCuota.pagada : EstadoCuota.parcial;
        tx.update(refs[i], <String, dynamic>{
          'pagado': nuevoPagado,
          'saldo': (cuota.monto - nuevoPagado) < 0 ? 0 : cuota.monto - nuevoPagado,
          'estado': nuevoEstado.id,
          'fechaPago': DateTime.now().toUtc().toIso8601String(),
        });
        restante -= aplicar;
        aplicado += aplicar;
        cuotas[i] = cuota.copyWith(pagado: nuevoPagado, estado: nuevoEstado);
      }

      if (restante > 0.01) {
        throw StateError('El pago supera el saldo pendiente.');
      }

      final pagadas =
          cuotas.where((Cuota c) => c.estaPagada).length;
      final nuevoSaldo =
          (credito.saldoActual - aplicado) < 0.001 ? 0.0 : credito.saldoActual - aplicado;
      final nuevoEstado =
          nuevoSaldo <= 0.001 ? EstadoCredito.pagado : EstadoCredito.activo;

      tx.update(creditoRef, <String, dynamic>{
        'saldoActual': nuevoSaldo,
        'cuotasPagadas': pagadas,
        'estado': nuevoEstado.id,
      });

      tx.set(pagoRef, <String, dynamic>{
        'id': pagoRef.id,
        'empresaId': empresa,
        'creditoId': creditoId,
        'clienteId': clienteId,
        'monto': aplicado,
        'medioPago': medioPago.id,
        'fecha': DateTime.now().toUtc().toIso8601String(),
        'cobradorUid': cobradorUid,
        'notas': notas,
      });
    });

    await _auditoria.registrarEvento(
      empresaId: empresa,
      operacion: OperacionAuditoria.insert,
      tabla: 'pagos_credito',
      documentoId: pagoRef.id,
      datos: <String, dynamic>{
        'creditoId': creditoId,
        'monto': monto,
        'medioPago': medioPago.id,
        'cobradorUid': cobradorUid,
      },
    );
  }

  /// Cancela un crédito (RF-08).
  Future<void> cancelar(String creditoId, String motivo) async {
    final ref = _creditos.doc(creditoId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw StateError('El crédito no existe.');
    final empresa = (data['empresaId'] as String?) ?? '';
    final cambios = <String, dynamic>{
      'estado': EstadoCredito.cancelado.id,
      'motivoCancelacion': motivo,
    };
    await ref.update(cambios);
    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'creditos',
      documentoId: creditoId,
      antes: <String, dynamic>{'estado': data['estado']},
      despues: cambios,
    );
  }

  List<Credito> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            Credito.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((Credito a, Credito b) =>
        (b.fechaInicio ?? DateTime(0)).compareTo(a.fechaInicio ?? DateTime(0)));
    return lista;
  }
}
