/// Dominio de ventas (spec 005).
///
/// Una venta registra productos, cantidades, precios, tipo de pago
/// (contado/crédito), tipo de entrega y medio de pago, con factura consecutiva.
library;

import '../../catalogo/domain/precio.dart';

/// Tipo de entrega de la venta (RF-06).
enum TipoEntrega {
  presencial('presencial', 'Presencial'),
  entregaLocal('entrega_local', 'Entrega local'),
  recogerLocal('recoger_local', 'Recoger en local'),
  envio('envio', 'Envío');

  const TipoEntrega(this.id, this.nombre);

  final String id;
  final String nombre;

  /// RN-03: presencial y recoger en local no cobran envío.
  bool get cobraEnvio => this == TipoEntrega.entregaLocal || this == TipoEntrega.envio;

  static TipoEntrega desdeId(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return TipoEntrega.presencial;
  }
}

/// Medio de pago (RF-07).
enum MedioPago {
  efectivo('efectivo', 'Efectivo'),
  tarjeta('tarjeta', 'Tarjeta'),
  transferenciaNequi('transferencia_nequi', 'Transferencia Nequi'),
  transferenciaBancolombia('transferencia_bancolombia', 'Transferencia Bancolombia');

  const MedioPago(this.id, this.nombre);

  final String id;
  final String nombre;

  static MedioPago desdeId(String? id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return MedioPago.efectivo;
  }
}

/// Estado de la venta (RN-06, anulación lógica).
enum EstadoVenta {
  registrada('registrada', 'Registrada'),
  anulada('anulada', 'Anulada');

  const EstadoVenta(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoVenta desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoVenta.registrada;
  }
}

/// Línea de la venta (`items[]`).
class ItemVenta {
  const ItemVenta({
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  final String productoId;
  final String codigo;
  final String nombre;
  final int cantidad;
  final double precioUnitario;

  /// Subtotal de la línea (`cantidad × precioUnitario`).
  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'productoId': productoId,
        'codigo': codigo,
        'nombre': nombre,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'subtotal': subtotal,
      };

  factory ItemVenta.fromMap(Map<String, dynamic> data) {
    return ItemVenta(
      productoId: (data['productoId'] as String?) ?? '',
      codigo: (data['codigo'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (data['precioUnitario'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Venta (`ventas/{id}`). Spec 005.
class Venta {
  const Venta({
    required this.id,
    required this.empresaId,
    this.numeroFactura = '',
    this.fecha,
    this.vendedorUid = '',
    this.vendedorNombre = '',
    this.clienteId,
    this.clienteNombre = 'Consumidor final',
    this.clienteUid,
    this.items = const <ItemVenta>[],
    this.tipoVenta = TipoPrecio.contado,
    this.tipoEntrega = TipoEntrega.presencial,
    this.medioPago = MedioPago.efectivo,
    this.subtotal = 0,
    this.costoEnvio = 0,
    this.descuento = 0,
    this.impuestos = 0,
    this.total = 0,
    this.empresaEnvio = '',
    this.fechaEnvio,
    this.estadoEnvio = '',
    this.estado = EstadoVenta.registrada,
    this.motivoAnulacion = '',
    this.creditoId,
  });

  final String id;
  final String empresaId;
  final String numeroFactura;
  final DateTime? fecha;
  final String vendedorUid;
  final String vendedorNombre;

  /// Cliente. Vacío/nulo = consumidor final (venta rápida).
  final String? clienteId;
  final String clienteNombre;
  final String? clienteUid;

  final List<ItemVenta> items;

  /// Tipo de pago: contado o crédito (reutiliza `TipoPrecio` del catálogo).
  final TipoPrecio tipoVenta;
  final TipoEntrega tipoEntrega;
  final MedioPago medioPago;

  final double subtotal;
  final double costoEnvio;
  final double descuento;
  final double impuestos;
  final double total;

  final String empresaEnvio;
  final DateTime? fechaEnvio;
  final String estadoEnvio;

  final EstadoVenta estado;
  final String motivoAnulacion;
  final String? creditoId;

  bool get anulada => estado == EstadoVenta.anulada;
  bool get esCredito => tipoVenta == TipoPrecio.credito;

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'numeroFactura': numeroFactura,
        'fecha': (fecha ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'vendedorUid': vendedorUid,
        'vendedorNombre': vendedorNombre,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'clienteUid': clienteUid,
        'items': items.map((ItemVenta i) => i.toMap()).toList(growable: false),
        'tipoVenta': tipoVenta.id,
        'tipoEntrega': tipoEntrega.id,
        'medioPago': medioPago.id,
        'subtotal': subtotal,
        'costoEnvio': costoEnvio,
        'descuento': descuento,
        'impuestos': impuestos,
        'total': total,
        'empresaEnvio': empresaEnvio,
        'fechaEnvio': fechaEnvio?.toUtc().toIso8601String(),
        'estadoEnvio': estadoEnvio,
        'estado': estado.id,
        'motivoAnulacion': motivoAnulacion,
        'creditoId': creditoId,
      };

  factory Venta.fromMap(String id, Map<String, dynamic> data) {
    return Venta(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      numeroFactura: (data['numeroFactura'] as String?) ?? '',
      fecha: _aFecha(data['fecha']),
      vendedorUid: (data['vendedorUid'] as String?) ?? '',
      vendedorNombre: (data['vendedorNombre'] as String?) ?? '',
      clienteId: data['clienteId'] as String?,
      clienteNombre: (data['clienteNombre'] as String?) ?? 'Consumidor final',
      clienteUid: data['clienteUid'] as String?,
      items: (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              ItemVenta.fromMap(m.cast<String, dynamic>()))
          .toList(growable: false),
      tipoVenta: TipoPrecio.desdeId(data['tipoVenta'] as String?),
      tipoEntrega: TipoEntrega.desdeId(data['tipoEntrega'] as String?),
      medioPago: MedioPago.desdeId(data['medioPago'] as String?),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      costoEnvio: (data['costoEnvio'] as num?)?.toDouble() ?? 0,
      descuento: (data['descuento'] as num?)?.toDouble() ?? 0,
      impuestos: (data['impuestos'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      empresaEnvio: (data['empresaEnvio'] as String?) ?? '',
      fechaEnvio: _aFecha(data['fechaEnvio']),
      estadoEnvio: (data['estadoEnvio'] as String?) ?? '',
      estado: EstadoVenta.desdeId(data['estado'] as String?),
      motivoAnulacion: (data['motivoAnulacion'] as String?) ?? '',
      creditoId: data['creditoId'] as String?,
    );
  }
}

/// Convierte un valor de Firestore (ISO string o Timestamp) a fecha.
DateTime? _aFecha(dynamic valor) {
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
