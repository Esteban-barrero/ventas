import '../../catalogo/domain/producto.dart';

/// Valor de un producto en inventario (costo × existencias).
double valorizarProducto(Producto producto) => producto.stock * producto.costo;

/// Valorización total del inventario (RF-09).
double valorizarInventario(List<Producto> productos) =>
    productos.fold(0.0, (double a, Producto p) => a + valorizarProducto(p));

/// Productos en o por debajo del stock mínimo (RF-07).
List<Producto> bajoStockDe(List<Producto> productos) =>
    productos.where((Producto p) => p.stock <= p.stockMinimo).toList(growable: false);

/// Productos agotados (stock ≤ 0, RF-08).
List<Producto> agotadosDe(List<Producto> productos) =>
    productos.where((Producto p) => p.stock <= 0).toList(growable: false);
