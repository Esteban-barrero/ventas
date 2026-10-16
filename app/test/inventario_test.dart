import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/catalogo/data/productos_repository.dart';
import 'package:ventas_app/features/catalogo/domain/producto.dart';
import 'package:ventas_app/features/inventario/domain/conteo_inventario.dart';
import 'package:ventas_app/features/inventario/domain/movimiento_inventario.dart';
import 'package:ventas_app/features/inventario/domain/valorizacion.dart';
import 'package:ventas_app/features/inventario/presentation/inventario_list_screen.dart';

/// Repositorio de productos en memoria para la prueba de widget.
class _FakeProductos extends ProductosRepository {
  _FakeProductos(this.items);

  final List<Producto> items;

  @override
  Stream<List<Producto>> escuchar(String empresaId) => Stream.value(items);
}

const _p1 = Producto(
  id: 'p1',
  empresaId: 'e',
  codigo: 'A-1',
  nombre: 'Camiseta',
  costo: 2000,
  stock: 10,
  stockMinimo: 5,
);

void main() {
  group('valorización (RF-09, RN-07)', () {
    test('valoriza un producto y el inventario', () {
      expect(valorizarProducto(_p1), 20000);
      expect(valorizarInventario(const <Producto>[_p1]), 20000);
    });
  });

  group('alertas de stock (RF-07, RF-08)', () {
    test('bajo stock cuando stock <= mínimo', () {
      const bajo = Producto(
        id: 'p',
        empresaId: 'e',
        codigo: 'C',
        nombre: 'N',
        stock: 5,
        stockMinimo: 5,
      );
      expect(bajoStockDe(const <Producto>[_p1, bajo]).map((p) => p.id),
          <String>['p']);
    });

    test('agotado cuando stock <= 0', () {
      const agotado = Producto(
        id: 'a',
        empresaId: 'e',
        codigo: 'C',
        nombre: 'N',
        stock: 0,
      );
      expect(agotadosDe(const <Producto>[_p1, agotado]).map((p) => p.id),
          <String>['a']);
    });
  });

  group('conteo físico', () {
    test('calcula la diferencia por línea', () {
      const item = ItemConteo(
        productoId: 'p',
        nombre: 'N',
        stockSistema: 10,
        stockFisico: 7,
      );
      expect(item.diferencia, -3);
    });

    test('cuenta los ítems con diferencia', () {
      const conteo = ConteoInventario(
        id: 'c',
        empresaId: 'e',
        items: <ItemConteo>[
          ItemConteo(productoId: 'a', stockSistema: 10, stockFisico: 10),
          ItemConteo(productoId: 'b', stockSistema: 5, stockFisico: 3),
        ],
      );
      expect(conteo.itemsConDiferencia, 1);
    });
  });

  group('serialización del movimiento', () {
    test('guarda y recupera un movimiento del kardex', () {
      final m = MovimientoInventario(
        id: 'm1',
        empresaId: 'e',
        productoId: 'p1',
        codigo: 'A-1',
        nombre: 'Camiseta',
        tipo: TipoMovimiento.salida,
        cantidad: 2,
        stockAnterior: 10,
        stockResultante: 8,
        referenciaTipo: ReferenciaTipo.venta,
        referenciaId: 'FV-000001',
      );
      final vuelta = MovimientoInventario.fromMap('m1', <String, dynamic>{
        'id': m.id,
        'empresaId': m.empresaId,
        'productoId': m.productoId,
        'nombre': m.nombre,
        'tipo': m.tipo.id,
        'cantidad': m.cantidad,
        'stockAnterior': m.stockAnterior,
        'stockResultante': m.stockResultante,
        'referenciaTipo': m.referenciaTipo.id,
      });
      expect(vuelta.tipo, TipoMovimiento.salida);
      expect(vuelta.stockResultante, 8);
      expect(vuelta.suma, isFalse);
    });
  });

  testWidgets('el inventario muestra stock y valorización',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u1',
      nombre: 'Admin',
      email: 'a@ejemplo.com',
      empresaId: 'e',
      roles: <String>['administrador'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: InventarioListScreen(
          usuario: usuario,
          productosRepository: _FakeProductos(const <Producto>[_p1]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Camiseta'), findsOneWidget);
    expect(find.text('Nuevo conteo'), findsOneWidget);
    expect(find.text('Valorización'), findsOneWidget);
  });
}
