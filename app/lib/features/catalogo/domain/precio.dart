/// Cálculo de precios del catálogo (spec 003, RN-03, ADR-001).
///
/// El precio se deriva del costo y el margen: `precio = costo * (1 + margen/100)`.
/// El margen es **dual** (contado y crédito) y esta lógica es compartida por
/// Catálogo, Ventas y Carrito, por eso vive en `domain`.
library;

/// Forma de pago que determina el margen aplicado (spec 003, RN-02).
enum TipoPrecio {
  contado('contado', 'Contado'),
  credito('credito', 'Crédito');

  const TipoPrecio(this.id, this.nombre);

  /// Identificador persistido en Firestore.
  final String id;

  /// Nombre visible para el usuario.
  final String nombre;

  /// Interpreta el id persistido (por defecto `contado`).
  static TipoPrecio desdeId(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return TipoPrecio.contado;
  }
}

/// Calcula el precio de venta: `costo * (1 + margen/100)` (RN-03).
///
/// Un margen negativo se trata como 0 para no vender por debajo del costo por
/// un error de captura.
double calcularPrecio(double costo, double margenPct) {
  final margen = margenPct < 0 ? 0.0 : margenPct;
  return costo * (1 + margen / 100);
}
