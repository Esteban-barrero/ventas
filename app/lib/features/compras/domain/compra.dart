import 'proveedor.dart' show aFecha;

/// Forma de pago de la compra (RF-07).
enum FormaPagoCompra {
  contado('contado', 'Contado'),
  credito('credito', 'Crédito'),
  transferencia('transferencia', 'Transferencia');

  const FormaPagoCompra(this.id, this.nombre);

  final String id;
  final String nombre;

  static FormaPagoCompra desdeId(String? id) {
    for (final f in values) {
      if (f.id == id) return f;
    }
    return FormaPagoCompra.contado;
  }
}

/// Estado de la compra (RF-08).
enum EstadoCompra {
  pendiente('pendiente', 'Pendiente'),
  pagada('pagada', 'Pagada'),
  anulada('anulada', 'Anulada');

  const EstadoCompra(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoCompra desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoCompra.pendiente;
  }
}

/// Línea de la compra (`items[]`).
class ItemCompra {
  const ItemCompra({
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.costoUnitario,
    this.iva = 0,
  });

  final String productoId;
  final String codigo;
  final String nombre;
  final int cantidad;
  final double costoUnitario;
  final double iva;

  double get subtotal => cantidad * costoUnitario;

  /// IVA de la línea (según el IVA del producto).
  double get impuesto => subtotal * iva / 100;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'productoId': productoId,
        'codigo': codigo,
        'nombre': nombre,
        'cantidad': cantidad,
        'costoUnitario': costoUnitario,
        'iva': iva,
        'subtotal': subtotal,
      };

  factory ItemCompra.fromMap(Map<String, dynamic> data) {
    return ItemCompra(
      productoId: (data['productoId'] as String?) ?? '',
      codigo: (data['codigo'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
      costoUnitario: (data['costoUnitario'] as num?)?.toDouble() ?? 0,
      iva: (data['iva'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Compra (`compras/{id}`). Spec 007.
class Compra {
  const Compra({
    required this.id,
    required this.empresaId,
    this.numeroOrden = '',
    this.fecha,
    this.proveedorId = '',
    this.proveedorNombre = '',
    this.items = const <ItemCompra>[],
    this.subtotal = 0,
    this.iva = 0,
    this.retencionFuente = 0,
    this.retencionIva = 0,
    this.retencionIca = 0,
    this.valorTotal = 0,
    this.formaPago = FormaPagoCompra.contado,
    this.estado = EstadoCompra.pendiente,
    this.actualizaCosto = false,
    this.observaciones = '',
    this.motivoAnulacion = '',
    this.fechaCreacion,
  });

  final String id;
  final String empresaId;
  final String numeroOrden;
  final DateTime? fecha;
  final String proveedorId;
  final String proveedorNombre;
  final List<ItemCompra> items;

  final double subtotal;
  final double iva;
  final double retencionFuente;
  final double retencionIva;
  final double retencionIca;

  /// Total a pagar = subtotal + IVA − retenciones.
  final double valorTotal;

  final FormaPagoCompra formaPago;
  final EstadoCompra estado;

  /// Si al confirmar la compra se actualiza el costo del producto (RN-03).
  final bool actualizaCosto;

  final String observaciones;
  final String motivoAnulacion;
  final DateTime? fechaCreacion;

  bool get anulada => estado == EstadoCompra.anulada;
  double get retenciones => retencionFuente + retencionIva + retencionIca;

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'numeroOrden': numeroOrden,
        'fecha': (fecha ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'proveedorId': proveedorId,
        'proveedorNombre': proveedorNombre,
        'items': items.map((ItemCompra i) => i.toMap()).toList(growable: false),
        'subtotal': subtotal,
        'iva': iva,
        'retencionFuente': retencionFuente,
        'retencionIva': retencionIva,
        'retencionIca': retencionIca,
        'valorTotal': valorTotal,
        'formaPago': formaPago.id,
        'estado': estado.id,
        'actualizaCosto': actualizaCosto,
        'observaciones': observaciones,
        'motivoAnulacion': motivoAnulacion,
        'fechaCreacion':
            (fechaCreacion ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory Compra.fromMap(String id, Map<String, dynamic> data) {
    return Compra(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      numeroOrden: (data['numeroOrden'] as String?) ?? '',
      fecha: aFecha(data['fecha']),
      proveedorId: (data['proveedorId'] as String?) ?? '',
      proveedorNombre: (data['proveedorNombre'] as String?) ?? '',
      items: (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              ItemCompra.fromMap(m.cast<String, dynamic>()))
          .toList(growable: false),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      iva: (data['iva'] as num?)?.toDouble() ?? 0,
      retencionFuente: (data['retencionFuente'] as num?)?.toDouble() ?? 0,
      retencionIva: (data['retencionIva'] as num?)?.toDouble() ?? 0,
      retencionIca: (data['retencionIca'] as num?)?.toDouble() ?? 0,
      valorTotal: (data['valorTotal'] as num?)?.toDouble() ?? 0,
      formaPago: FormaPagoCompra.desdeId(data['formaPago'] as String?),
      estado: EstadoCompra.desdeId(data['estado'] as String?),
      actualizaCosto: (data['actualizaCosto'] as bool?) ?? false,
      observaciones: (data['observaciones'] as String?) ?? '',
      motivoAnulacion: (data['motivoAnulacion'] as String?) ?? '',
      fechaCreacion: aFecha(data['fechaCreacion']),
    );
  }
}
