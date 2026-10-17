/// Dominio de **pedidos** (spec 010): el cliente arma un carrito y hace un
/// pedido; la empresa lo aprueba y se convierte en venta (que entra a
/// Entregas, spec 011).
library;

import '../../catalogo/domain/precio.dart';
import '../../clientes/domain/cliente.dart' show Direccion;
import '../../ventas/domain/venta.dart' show MedioPago, TipoEntrega;

/// Estado del pedido (RF-07). Flujo:
/// pendiente → confirmado → en_preparacion → listo → entregado; y cancelado.
enum EstadoPedido {
  pendiente('pendiente', 'Pendiente'),
  confirmado('confirmado', 'Confirmado'),
  enPreparacion('en_preparacion', 'En preparación'),
  listo('listo', 'Listo'),
  entregado('entregado', 'Entregado'),
  cancelado('cancelado', 'Cancelado');

  const EstadoPedido(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoPedido desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoPedido.pendiente;
  }
}

/// Origen del pedido (RF-05).
enum OrigenPedido {
  cliente('cliente', 'Cliente'),
  invitado('invitado', 'Invitado');

  const OrigenPedido(this.id, this.nombre);

  final String id;
  final String nombre;

  static OrigenPedido desdeId(String? id) {
    for (final o in values) {
      if (o.id == id) return o;
    }
    return OrigenPedido.cliente;
  }
}

/// Línea del pedido (precio y costo **congelados** al crear, RN-04).
class ItemPedido {
  const ItemPedido({
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    this.iva = 0,
    this.costoUnitario = 0,
  });

  final String productoId;
  final String codigo;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double iva;
  final double costoUnitario;

  double get subtotal => cantidad * precioUnitario;

  double get impuesto => subtotal * iva / 100;

  double get utilidad => cantidad * (precioUnitario - costoUnitario);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'productoId': productoId,
        'codigo': codigo,
        'nombre': nombre,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'iva': iva,
        'costoUnitario': costoUnitario,
        'subtotal': subtotal,
        'impuesto': impuesto,
      };

  factory ItemPedido.fromMap(Map<String, dynamic> data) {
    return ItemPedido(
      productoId: (data['productoId'] as String?) ?? '',
      codigo: (data['codigo'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (data['precioUnitario'] as num?)?.toDouble() ?? 0,
      iva: (data['iva'] as num?)?.toDouble() ?? 0,
      costoUnitario: (data['costoUnitario'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Pedido (`pedidos/{id}`). Spec 010.
class Pedido {
  const Pedido({
    required this.id,
    required this.empresaId,
    this.numero = '',
    this.origen = OrigenPedido.cliente,
    this.clienteUid,
    this.clienteId,
    this.clienteNombre = '',
    this.cedula = '',
    this.telefono = '',
    this.direccion = const Direccion(),
    this.items = const <ItemPedido>[],
    this.subtotal = 0,
    this.costoEnvio = 0,
    this.impuestos = 0,
    this.total = 0,
    this.tipoEntrega = TipoEntrega.entregaLocal,
    this.medioPago = MedioPago.efectivo,
    this.tipoPago = TipoPrecio.contado,
    this.observaciones = '',
    this.estado = EstadoPedido.pendiente,
    this.ventaId = '',
    this.motivoCancelacion = '',
    this.aprobadoPorUid = '',
    this.aprobadoPorNombre = '',
    this.fechaCreacion,
    this.fechaActualizacion,
    this.fechaAprobacion,
  });

  final String id;
  final String empresaId;
  final String numero;
  final OrigenPedido origen;

  /// Cliente registrado (uid/id). `null` si es invitado.
  final String? clienteUid;
  final String? clienteId;
  final String clienteNombre;

  /// Datos de contacto y entrega (obligatorios para el pedido).
  final String cedula;
  final String telefono;
  final Direccion direccion;

  final List<ItemPedido> items;
  final double subtotal;
  final double costoEnvio;
  final double impuestos;
  final double total;

  final TipoEntrega tipoEntrega;
  final MedioPago medioPago;
  final TipoPrecio tipoPago;
  final String observaciones;

  final EstadoPedido estado;

  /// Venta generada al aprobar el pedido (spec 005).
  final String ventaId;

  final String motivoCancelacion;
  final String aprobadoPorUid;
  final String aprobadoPorNombre;

  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final DateTime? fechaAprobacion;

  bool get pendiente => estado == EstadoPedido.pendiente;
  bool get cancelado => estado == EstadoPedido.cancelado;
  bool get aprobado => ventaId.isNotEmpty;

  /// Costo total de la mercancía (para la utilidad de la venta).
  double get costoTotal =>
      items.fold(0.0, (double a, ItemPedido i) => a + i.cantidad * i.costoUnitario);

  /// Utilidad total del pedido.
  double get utilidadTotal =>
      items.fold(0.0, (double a, ItemPedido i) => a + i.utilidad);

  /// Margen promedio (`utilidad / subtotal × 100`).
  double get margenPct => subtotal > 0 ? utilidadTotal / subtotal * 100 : 0.0;

  Pedido copyWith({
    EstadoPedido? estado,
    String? ventaId,
    String? motivoCancelacion,
    String? aprobadoPorUid,
    String? aprobadoPorNombre,
    DateTime? fechaAprobacion,
    DateTime? fechaActualizacion,
  }) {
    return Pedido(
      id: id,
      empresaId: empresaId,
      numero: numero,
      origen: origen,
      clienteUid: clienteUid,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      cedula: cedula,
      telefono: telefono,
      direccion: direccion,
      items: items,
      subtotal: subtotal,
      costoEnvio: costoEnvio,
      impuestos: impuestos,
      total: total,
      tipoEntrega: tipoEntrega,
      medioPago: medioPago,
      tipoPago: tipoPago,
      observaciones: observaciones,
      estado: estado ?? this.estado,
      ventaId: ventaId ?? this.ventaId,
      motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
      aprobadoPorUid: aprobadoPorUid ?? this.aprobadoPorUid,
      aprobadoPorNombre: aprobadoPorNombre ?? this.aprobadoPorNombre,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
    );
  }

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'numero': numero,
        'origen': origen.id,
        'clienteUid': clienteUid,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'cedula': cedula,
        'telefono': telefono,
        'direccion': direccion.toMap(),
        'items': items.map((ItemPedido i) => i.toMap()).toList(growable: false),
        'subtotal': subtotal,
        'costoEnvio': costoEnvio,
        'impuestos': impuestos,
        'total': total,
        'tipoEntrega': tipoEntrega.id,
        'medioPago': medioPago.id,
        'tipoPago': tipoPago.id,
        'observaciones': observaciones,
        'estado': estado.id,
        'ventaId': ventaId,
        'motivoCancelacion': motivoCancelacion,
        'aprobadoPorUid': aprobadoPorUid,
        'aprobadoPorNombre': aprobadoPorNombre,
        'fechaCreacion':
            (fechaCreacion ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'fechaActualizacion':
            (fechaActualizacion ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'fechaAprobacion': fechaAprobacion?.toUtc().toIso8601String(),
      };

  factory Pedido.fromMap(String id, Map<String, dynamic> data) {
    return Pedido(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      numero: (data['numero'] as String?) ?? '',
      origen: OrigenPedido.desdeId(data['origen'] as String?),
      clienteUid: data['clienteUid'] as String?,
      clienteId: data['clienteId'] as String?,
      clienteNombre: (data['clienteNombre'] as String?) ?? '',
      cedula: (data['cedula'] as String?) ?? '',
      telefono: (data['telefono'] as String?) ?? '',
      direccion: Direccion.fromMap(
          (data['direccion'] as Map?)?.cast<String, dynamic>()),
      items: (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              ItemPedido.fromMap(m.cast<String, dynamic>()))
          .toList(growable: false),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      costoEnvio: (data['costoEnvio'] as num?)?.toDouble() ?? 0,
      impuestos: (data['impuestos'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      tipoEntrega: TipoEntrega.desdeId(data['tipoEntrega'] as String?),
      medioPago: MedioPago.desdeId(data['medioPago'] as String?),
      tipoPago: TipoPrecio.desdeId(data['tipoPago'] as String?),
      observaciones: (data['observaciones'] as String?) ?? '',
      estado: EstadoPedido.desdeId(data['estado'] as String?),
      ventaId: (data['ventaId'] as String?) ?? '',
      motivoCancelacion: (data['motivoCancelacion'] as String?) ?? '',
      aprobadoPorUid: (data['aprobadoPorUid'] as String?) ?? '',
      aprobadoPorNombre: (data['aprobadoPorNombre'] as String?) ?? '',
      fechaCreacion: aFechaPedido(data['fechaCreacion']),
      fechaActualizacion: aFechaPedido(data['fechaActualizacion']),
      fechaAprobacion: aFechaPedido(data['fechaAprobacion']),
    );
  }
}

/// Convierte un valor de Firestore (ISO string o Timestamp) a fecha.
DateTime? aFechaPedido(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor;
  if (valor is String) return DateTime.tryParse(valor);
  try {
    final dynamic fecha = (valor as dynamic).toDate();
    if (fecha is DateTime) return fecha;
  } catch (_) {
    // Tipo desconocido; se ignora.
  }
  return null;
}
