import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../../catalogo/domain/precio.dart';
import '../../tesoreria/data/tesoreria_repository.dart';
import '../../tesoreria/domain/movimiento_dinero.dart';
import '../../tesoreria/domain/posiciones.dart';
import '../../ventas/data/ventas_repository.dart';
import '../../ventas/domain/venta.dart';
import '../domain/pedido.dart';

/// El pedido no tiene productos.
class PedidoVacioException implements Exception {
  const PedidoVacioException();

  @override
  String toString() => 'El pedido no tiene productos.';
}

/// El pedido no se puede aprobar (cancelado o ya convertido).
class PedidoNoAprobableException implements Exception {
  const PedidoNoAprobableException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Acceso a `pedidos` (spec 010). La aprobación reutiliza [VentasRepository]
/// (spec 005) y registra el dinero en tesorería (spec 016).
class PedidosRepository {
  PedidosRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
    VentasRepository? ventas,
    TesoreriaRepository? tesoreria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository(),
        _ventas = ventas ?? VentasRepository(firestore: firestore),
        _tesoreria = tesoreria ?? TesoreriaRepository(firestore: firestore);

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;
  final VentasRepository _ventas;
  final TesoreriaRepository _tesoreria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pedidos =>
      _db.collection('pedidos');

  CollectionReference<Map<String, dynamic>> get _consecutivos =>
      _db.collection('consecutivos_pedidos');

  /// Escucha los pedidos de la empresa (opcionalmente por estado).
  Stream<List<Pedido>> escuchar(String empresaId, {EstadoPedido? estado}) {
    return _pedidos
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) {
      final lista = _aLista(snap);
      if (estado == null) return lista;
      return lista
          .where((Pedido p) => p.estado == estado)
          .toList(growable: false);
    });
  }

  /// Escucha los pedidos de un cliente (spec 010, RF-08).
  ///
  /// Se consulta por `clienteUid` (no por `empresaId`) porque las reglas exigen
  /// que la consulta incluya ese campo para autorizar al cliente.
  Stream<List<Pedido>> escucharMisPedidos(String empresaId, String clienteUid) {
    return _pedidos
        .where('clienteUid', isEqualTo: clienteUid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) => _aLista(snap)
            .where((Pedido p) =>
                p.clienteUid == clienteUid &&
                (empresaId.isEmpty || p.empresaId == empresaId))
            .toList(growable: false));
  }

  /// Crea un pedido con su número consecutivo (RF-04). No descuenta stock
  /// (RN-03): eso ocurre al aprobarlo y convertirlo en venta.
  Future<String> crear(Pedido pedido) async {
    if (pedido.items.isEmpty) throw const PedidoVacioException();

    final ref = _pedidos.doc();
    final consRef = _consecutivos.doc(pedido.empresaId);
    var numero = pedido.numero;

    await _db.runTransaction((Transaction tx) async {
      final snap = await tx.get(consRef);
      final actual = (snap.data()?['pedidoActual'] as num?)?.toInt() ?? 0;
      final prefijo = (snap.data()?['prefijo'] as String?) ?? 'PED-';
      final siguiente = actual + 1;
      numero = '$prefijo${siguiente.toString().padLeft(6, '0')}';

      tx.set(
        consRef,
        <String, dynamic>{
          'empresaId': pedido.empresaId,
          'pedidoActual': siguiente,
          'prefijo': prefijo,
        },
        SetOptions(merge: true),
      );
      tx.set(ref, <String, dynamic>{
        ...pedido.toMap(),
        'id': ref.id,
        'numero': numero,
        'estado': EstadoPedido.pendiente.id,
      });
    });

    await _auditoria.registrarEvento(
      empresaId: pedido.empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'pedidos',
      documentoId: ref.id,
      datos: <String, dynamic>{
        'numero': numero,
        'total': pedido.total,
        'cliente': pedido.clienteNombre,
      },
    );
    return ref.id;
  }

  /// Cambia el estado de un pedido (RF-07) y deja auditoría.
  Future<void> cambiarEstado(
    String pedidoId,
    EstadoPedido estado, {
    required String empresaId,
    String motivo = '',
    String usuarioUid = '',
  }) async {
    await _pedidos.doc(pedidoId).update(<String, dynamic>{
      'estado': estado.id,
      if (motivo.isNotEmpty) 'motivoCancelacion': motivo,
      'fechaActualizacion': DateTime.now().toUtc().toIso8601String(),
    });
    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.update,
      tabla: 'pedidos',
      documentoId: pedidoId,
      datos: <String, dynamic>{'estado': estado.id, 'porUid': usuarioUid},
    );
  }

  /// **Aprueba** el pedido: lo convierte en venta (spec 005), registra el dinero
  /// de contado en tesorería (spec 016) y marca el pedido como `confirmado`.
  ///
  /// La venta queda con `tipoEntrega`; si es entrega local o envío, aparece en
  /// **Entregas** (spec 011) automáticamente.
  Future<String> aprobar(
    Pedido pedido, {
    required String usuarioUid,
    required String usuarioNombre,
  }) async {
    if (pedido.cancelado) {
      throw const PedidoNoAprobableException('El pedido está cancelado.');
    }
    if (pedido.aprobado) return pedido.ventaId;

    final items = pedido.items
        .map((ItemPedido i) => ItemVenta(
              productoId: i.productoId,
              codigo: i.codigo,
              nombre: i.nombre,
              cantidad: i.cantidad,
              precioUnitario: i.precioUnitario,
              iva: i.iva,
              costoUnitario: i.costoUnitario,
            ))
        .toList(growable: false);

    final venta = Venta(
      id: '',
      empresaId: pedido.empresaId,
      vendedorUid: usuarioUid,
      vendedorNombre: usuarioNombre,
      clienteId: pedido.clienteId,
      clienteNombre:
          pedido.clienteNombre.isEmpty ? 'Consumidor final' : pedido.clienteNombre,
      clienteUid: pedido.clienteUid,
      items: items,
      tipoVenta: pedido.tipoPago,
      tipoEntrega: pedido.tipoEntrega,
      medioPago: pedido.medioPago,
      subtotal: pedido.subtotal,
      costoEnvio: pedido.costoEnvio,
      impuestos: pedido.impuestos,
      total: pedido.total,
      costoTotal: pedido.costoTotal,
      utilidadTotal: pedido.utilidadTotal,
      margenPct: pedido.margenPct,
    );

    final ventaId = await _ventas.registrar(venta);

    // Dinero de contado → tesorería.
    if (pedido.tipoPago == TipoPrecio.contado && pedido.total > 0) {
      try {
        await _tesoreria.registrarMovimiento(
          empresaId: pedido.empresaId,
          tipo: TipoMovimientoDinero.ingreso,
          monto: pedido.total,
          ubicacion: ubicacionDeVenta(pedido.medioPago, pedido.tipoEntrega),
          medioPago: MedioDinero.desdeVenta(pedido.medioPago),
          referenciaTipo: ReferenciaDinero.venta,
          referenciaId: ventaId,
          usuarioUid: usuarioUid,
          usuarioNombre: usuarioNombre,
          responsableUid: usuarioUid,
          responsableNombre: usuarioNombre,
          descripcion: 'Pedido ${pedido.numero}',
        );
      } catch (_) {
        // El pedido queda aprobado aunque falle el registro del dinero.
      }
    }

    final ahora = DateTime.now().toUtc().toIso8601String();
    await _pedidos.doc(pedido.id).update(<String, dynamic>{
      'estado': EstadoPedido.confirmado.id,
      'ventaId': ventaId,
      'aprobadoPorUid': usuarioUid,
      'aprobadoPorNombre': usuarioNombre,
      'fechaAprobacion': ahora,
      'fechaActualizacion': ahora,
    });

    await _auditoria.registrarEvento(
      empresaId: pedido.empresaId,
      operacion: OperacionAuditoria.update,
      tabla: 'pedidos',
      documentoId: pedido.id,
      datos: <String, dynamic>{
        'estado': EstadoPedido.confirmado.id,
        'ventaId': ventaId,
        'aprobadoPorUid': usuarioUid,
      },
    );
    return ventaId;
  }

  List<Pedido> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            Pedido.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((Pedido a, Pedido b) =>
        (b.fechaCreacion ?? DateTime(0)).compareTo(a.fechaCreacion ?? DateTime(0)));
    return lista;
  }
}
