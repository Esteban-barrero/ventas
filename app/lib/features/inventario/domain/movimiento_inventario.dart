/// Dominio de inventario (spec 008): kardex inmutable y conteos.
library;

/// Tipo de movimiento del kardex (§5 del plan).
enum TipoMovimiento {
  entrada('entrada', 'Entrada'),
  salida('salida', 'Salida'),
  ajustePositivo('ajuste_positivo', 'Ajuste +'),
  ajusteNegativo('ajuste_negativo', 'Ajuste −'),
  reverso('reverso', 'Reverso');

  const TipoMovimiento(this.id, this.nombre);

  final String id;
  final String nombre;

  static TipoMovimiento desdeId(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return TipoMovimiento.entrada;
  }
}

/// Documento de origen del movimiento.
enum ReferenciaTipo {
  venta('venta', 'Venta'),
  compra('compra', 'Compra'),
  ajuste('ajuste', 'Ajuste'),
  conteo('conteo', 'Conteo'),
  anulacion('anulacion', 'Anulación');

  const ReferenciaTipo(this.id, this.nombre);

  final String id;
  final String nombre;

  static ReferenciaTipo desdeId(String? id) {
    for (final r in values) {
      if (r.id == id) return r;
    }
    return ReferenciaTipo.ajuste;
  }
}

/// Un movimiento del kardex (`movimientos_inventario/{id}`). Inmutable (RN-06).
class MovimientoInventario {
  const MovimientoInventario({
    required this.id,
    required this.empresaId,
    required this.productoId,
    this.codigo = '',
    this.nombre = '',
    this.tipo = TipoMovimiento.entrada,
    this.cantidad = 0,
    this.stockAnterior = 0,
    this.stockResultante = 0,
    this.motivo = '',
    this.referenciaTipo = ReferenciaTipo.ajuste,
    this.referenciaId = '',
    this.bodegaId = 'principal',
    this.usuarioUid = '',
    this.fecha,
  });

  final String id;
  final String empresaId;
  final String productoId;
  final String codigo;
  final String nombre;
  final TipoMovimiento tipo;
  final int cantidad;
  final int stockAnterior;
  final int stockResultante;
  final String motivo;
  final ReferenciaTipo referenciaTipo;
  final String referenciaId;
  final String bodegaId;
  final String usuarioUid;
  final DateTime? fecha;

  /// `true` si el movimiento aumenta el stock.
  bool get suma => stockResultante >= stockAnterior;

  factory MovimientoInventario.fromMap(String id, Map<String, dynamic> data) {
    return MovimientoInventario(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      productoId: (data['productoId'] as String?) ?? '',
      codigo: (data['codigo'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      tipo: TipoMovimiento.desdeId(data['tipo'] as String?),
      cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
      stockAnterior: (data['stockAnterior'] as num?)?.toInt() ?? 0,
      stockResultante: (data['stockResultante'] as num?)?.toInt() ?? 0,
      motivo: (data['motivo'] as String?) ?? '',
      referenciaTipo: ReferenciaTipo.desdeId(data['referenciaTipo'] as String?),
      referenciaId: (data['referenciaId'] as String?) ?? '',
      bodegaId: (data['bodegaId'] as String?) ?? 'principal',
      usuarioUid: (data['usuarioUid'] as String?) ?? '',
      fecha: aFechaInventario(data['fecha']),
    );
  }
}

/// Convierte un valor de Firestore (ISO string o Timestamp) a fecha.
DateTime? aFechaInventario(dynamic valor) {
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
