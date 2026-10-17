import 'package:cloud_firestore/cloud_firestore.dart';

import '../../catalogo/data/productos_repository.dart';
import '../../catalogo/domain/producto.dart';
import '../../creditos/data/creditos_repository.dart';
import '../../creditos/domain/credito.dart';
import '../../pedidos/data/pedidos_repository.dart';
import '../../pedidos/domain/pedido.dart';
import '../../tesoreria/data/tesoreria_repository.dart';
import '../../tesoreria/domain/movimiento_dinero.dart';
import '../../ventas/data/ventas_repository.dart';
import '../../ventas/domain/venta.dart';

/// Datos crudos (de una empresa) con los que se calculan los reportes (spec 015).
class DatosReportes {
  const DatosReportes({
    required this.ventas,
    required this.productos,
    required this.creditos,
    required this.movimientos,
    required this.pedidos,
  });

  final List<Venta> ventas;
  final List<Producto> productos;
  final List<Credito> creditos;
  final List<MovimientoDinero> movimientos;
  final List<Pedido> pedidos;
}

/// Carga los datos de los reportes reutilizando los repositorios de cada módulo.
class ReportesRepository {
  ReportesRepository({
    FirebaseFirestore? firestore,
    VentasRepository? ventas,
    ProductosRepository? productos,
    CreditosRepository? creditos,
    TesoreriaRepository? tesoreria,
    PedidosRepository? pedidos,
  })  : _ventas = ventas ?? VentasRepository(firestore: firestore),
        _productos = productos ?? ProductosRepository(firestore: firestore),
        _creditos = creditos ?? CreditosRepository(firestore: firestore),
        _tesoreria = tesoreria ?? TesoreriaRepository(firestore: firestore),
        _pedidos = pedidos ?? PedidosRepository(firestore: firestore);

  final VentasRepository _ventas;
  final ProductosRepository _productos;
  final CreditosRepository _creditos;
  final TesoreriaRepository _tesoreria;
  final PedidosRepository _pedidos;

  /// Carga ventas, productos, créditos, movimientos de dinero y pedidos.
  Future<DatosReportes> cargar(String empresaId) async {
    final ventas = await _ventas.listar(empresaId);
    final productos = await _productos.listar(empresaId);
    final creditos = await _creditos.listar(empresaId);
    final movimientos = await _tesoreria.movimientos(empresaId);
    final pedidos = await _pedidos.escuchar(empresaId).first;
    return DatosReportes(
      ventas: ventas,
      productos: productos,
      creditos: creditos,
      movimientos: movimientos,
      pedidos: pedidos,
    );
  }
}
