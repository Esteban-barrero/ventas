/// Dominio de **reportes** (spec 015): cálculos puros sobre los datos de los
/// demás módulos (ventas, cartera, inventario, dinero y pedidos). Al ser
/// funciones puras, son fáciles de probar.
library;

import '../../catalogo/domain/producto.dart';
import '../../creditos/domain/credito.dart';
import '../../pedidos/domain/pedido.dart';
import '../../tesoreria/domain/movimiento_dinero.dart';
import '../../ventas/domain/venta.dart';

/// Rango de fechas de un reporte (inclusive). `null` = sin límite.
class RangoFechas {
  const RangoFechas({this.desde, this.hasta});

  final DateTime? desde;
  final DateTime? hasta;

  /// `true` si la fecha cae dentro del rango.
  bool incluye(DateTime? fecha) {
    if (fecha == null) return false;
    final d = DateTime(fecha.year, fecha.month, fecha.day);
    if (desde != null) {
      final i = DateTime(desde!.year, desde!.month, desde!.day);
      if (d.isBefore(i)) return false;
    }
    if (hasta != null) {
      final f = DateTime(hasta!.year, hasta!.month, hasta!.day);
      if (d.isAfter(f)) return false;
    }
    return true;
  }

  static const RangoFechas todo = RangoFechas();

  static RangoFechas hoy([DateTime? ahora]) {
    final h = ahora ?? DateTime.now();
    return RangoFechas(desde: h, hasta: h);
  }

  static RangoFechas semana([DateTime? ahora]) {
    final h = ahora ?? DateTime.now();
    final inicio = h.subtract(Duration(days: h.weekday - 1));
    return RangoFechas(desde: inicio, hasta: h);
  }

  static RangoFechas mes([DateTime? ahora]) {
    final h = ahora ?? DateTime.now();
    return RangoFechas(
      desde: DateTime(h.year, h.month, 1),
      hasta: DateTime(h.year, h.month + 1, 0),
    );
  }

  static RangoFechas anio([DateTime? ahora]) {
    final h = ahora ?? DateTime.now();
    return RangoFechas(desde: DateTime(h.year, 1, 1), hasta: DateTime(h.year, 12, 31));
  }
}

/// Producto con su agregado en las ventas del período.
class ProductoVendido {
  const ProductoVendido({
    required this.nombre,
    required this.unidades,
    required this.total,
    required this.utilidad,
  });

  final String nombre;
  final int unidades;
  final double total;
  final double utilidad;
}

/// Resumen del reporte de ventas (RF-01, RF-06).
class ResumenVentas {
  const ResumenVentas({
    required this.total,
    required this.contado,
    required this.credito,
    required this.utilidad,
    required this.numero,
    required this.porMedio,
    required this.porVendedor,
    required this.topProductos,
  });

  final double total;
  final double contado;
  final double credito;
  final double utilidad;
  final int numero;
  final Map<String, double> porMedio;
  final Map<String, double> porVendedor;
  final List<ProductoVendido> topProductos;
}

/// Calcula el resumen de ventas del rango (excluye anuladas).
ResumenVentas calcularResumenVentas(List<Venta> ventas, RangoFechas rango) {
  final validas =
      ventas.where((Venta v) => !v.anulada && rango.incluye(v.fecha)).toList();

  double total = 0;
  double contado = 0;
  double credito = 0;
  double utilidad = 0;
  final porMedio = <String, double>{};
  final porVendedor = <String, double>{};
  final productos = <String, ProductoVendido>{};

  for (final Venta v in validas) {
    total += v.total;
    if (v.esCredito) {
      credito += v.total;
    } else {
      contado += v.total;
    }
    utilidad += v.utilidadTotal;
    porMedio[v.medioPago.nombre] = (porMedio[v.medioPago.nombre] ?? 0) + v.total;
    final vendedor = v.vendedorNombre.trim().isEmpty
        ? 'Sin vendedor'
        : v.vendedorNombre.trim();
    porVendedor[vendedor] = (porVendedor[vendedor] ?? 0) + v.total;

    for (final ItemVenta it in v.items) {
      final prev = productos[it.productoId];
      productos[it.productoId] = ProductoVendido(
        nombre: it.nombre,
        unidades: (prev?.unidades ?? 0) + it.cantidad,
        total: (prev?.total ?? 0) + it.subtotal,
        utilidad: (prev?.utilidad ?? 0) + it.utilidad,
      );
    }
  }

  final top = productos.values.toList()
    ..sort((ProductoVendido a, ProductoVendido b) =>
        b.utilidad.compareTo(a.utilidad));

  return ResumenVentas(
    total: total,
    contado: contado,
    credito: credito,
    utilidad: utilidad,
    numero: validas.length,
    porMedio: porMedio,
    porVendedor: porVendedor,
    topProductos: top.take(10).toList(growable: false),
  );
}

/// Resumen del inventario (RF-03, RN-06).
class ResumenInventario {
  const ResumenInventario({
    required this.valorizacion,
    required this.productos,
    required this.bajoStock,
    required this.agotados,
  });

  final double valorizacion;
  final int productos;
  final int bajoStock;
  final int agotados;
}

/// Valorización (`stock × costo`), bajo stock y agotados.
ResumenInventario calcularResumenInventario(List<Producto> productos) {
  double valorizacion = 0;
  var bajoStock = 0;
  var agotados = 0;
  for (final Producto p in productos) {
    valorizacion += p.stock * p.costo;
    if (p.stock <= 0) {
      agotados += 1;
    } else if (p.stock <= p.stockMinimo) {
      bajoStock += 1;
    }
  }
  return ResumenInventario(
    valorizacion: valorizacion,
    productos: productos.length,
    bajoStock: bajoStock,
    agotados: agotados,
  );
}

/// Resumen de cartera/créditos (RF-02).
class ResumenCartera {
  const ResumenCartera({
    required this.total,
    required this.vencida,
    required this.morosos,
    required this.creditos,
  });

  final double total;
  final double vencida;
  final int morosos;
  final int creditos;
}

/// Saldo total, cartera vencida y clientes en mora.
ResumenCartera calcularResumenCartera(List<Credito> creditos) {
  double total = 0;
  double vencida = 0;
  var morosos = 0;
  var activos = 0;
  for (final Credito c in creditos) {
    if (c.pagado || c.estado.id == 'cancelado') continue;
    if (c.saldoActual <= 0) continue;
    activos += 1;
    total += c.saldoActual;
    if (c.diasMora > 0) {
      vencida += c.saldoActual;
      morosos += 1;
    }
  }
  return ResumenCartera(
    total: total,
    vencida: vencida,
    morosos: morosos,
    creditos: activos,
  );
}

/// Resumen del dinero (ingresos/egresos) en el rango (RF-04).
class ResumenDinero {
  const ResumenDinero({
    required this.ingresos,
    required this.egresos,
    required this.porMedio,
  });

  final double ingresos;
  final double egresos;
  final Map<String, double> porMedio;

  double get neto => ingresos - egresos;
}

/// Ingresos y egresos por medio de pago (los traslados no cambian el total).
ResumenDinero calcularResumenDinero(
  List<MovimientoDinero> movimientos,
  RangoFechas rango,
) {
  double ingresos = 0;
  double egresos = 0;
  final porMedio = <String, double>{};
  for (final MovimientoDinero m in movimientos) {
    if (!rango.incluye(m.fecha)) continue;
    switch (m.tipo) {
      case TipoMovimientoDinero.ingreso:
        ingresos += m.monto;
        porMedio[m.medioPago.nombre] =
            (porMedio[m.medioPago.nombre] ?? 0) + m.monto;
      case TipoMovimientoDinero.egreso:
        egresos += m.monto;
      case TipoMovimientoDinero.traslado:
        break;
    }
  }
  return ResumenDinero(ingresos: ingresos, egresos: egresos, porMedio: porMedio);
}

/// Resumen de pedidos por estado (RF-07).
class ResumenPedidos {
  const ResumenPedidos({
    required this.total,
    required this.pendientes,
    required this.confirmados,
    required this.cancelados,
  });

  final int total;
  final int pendientes;
  final int confirmados;
  final int cancelados;
}

/// Cuenta los pedidos por estado en el rango.
ResumenPedidos calcularResumenPedidos(List<Pedido> pedidos, RangoFechas rango) {
  var pendientes = 0;
  var confirmados = 0;
  var cancelados = 0;
  for (final Pedido p in pedidos) {
    if (!rango.incluye(p.fechaCreacion)) continue;
    switch (p.estado) {
      case EstadoPedido.pendiente:
        pendientes += 1;
      case EstadoPedido.cancelado:
        cancelados += 1;
      default:
        confirmados += 1;
    }
  }
  return ResumenPedidos(
    total: pendientes + confirmados + cancelados,
    pendientes: pendientes,
    confirmados: confirmados,
    cancelados: cancelados,
  );
}
