import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/compras/data/compras_repository.dart';
import 'package:ventas_app/features/compras/data/proveedores_repository.dart';
import 'package:ventas_app/features/compras/domain/compra.dart';
import 'package:ventas_app/features/compras/domain/proveedor.dart';
import 'package:ventas_app/features/compras/domain/totales_compra.dart';
import 'package:ventas_app/features/compras/presentation/compras_list_screen.dart';

/// Repositorio de compras en memoria para la prueba de widget.
class _FakeCompras extends ComprasRepository {
  _FakeCompras(this.items);

  final List<Compra> items;

  @override
  Stream<List<Compra>> escuchar(String empresaId) => Stream.value(items);
}

const _item = ItemCompra(
  productoId: 'p1',
  codigo: 'A-1',
  nombre: 'Camiseta',
  cantidad: 2,
  costoUnitario: 1000,
  iva: 19,
);

void main() {
  group('calcularTotalesCompra (RF-03)', () {
    test('subtotal e IVA por línea', () {
      final t = calcularTotalesCompra(<ItemCompra>[_item]);
      expect(t.subtotal, 2000);
      expect(t.iva, closeTo(380, 0.001));
      expect(t.total, closeTo(2380, 0.001));
    });

    test('resta las retenciones del total a pagar', () {
      final t = calcularTotalesCompra(
        <ItemCompra>[_item],
        retencionFuente: 100,
        retencionIva: 38,
        retencionIca: 20,
      );
      expect(t.retenciones, 158);
      expect(t.total, closeTo(2000 + 380 - 158, 0.001));
    });

    test('el total nunca es negativo', () {
      final t = calcularTotalesCompra(
        <ItemCompra>[_item],
        retencionFuente: 999999,
      );
      expect(t.total, 0);
    });
  });

  group('filtros de proveedores (RF-01)', () {
    const proveedores = <Proveedor>[
      Proveedor(id: '1', empresaId: 'e', nombre: 'Distribuidora X', nit: '900'),
      Proveedor(
        id: '2',
        empresaId: 'e',
        nombre: 'Otro',
        nit: '800',
        activo: false,
      ),
    ];

    test('busca por nombre o NIT', () {
      expect(
        ProveedoresRepository.filtrar(proveedores, busqueda: 'distri')
            .map((p) => p.id),
        <String>['1'],
      );
      expect(
        ProveedoresRepository.filtrar(proveedores, busqueda: '800')
            .map((p) => p.id),
        <String>['2'],
      );
    });

    test('soloActivos excluye los inactivos', () {
      expect(
        ProveedoresRepository.filtrar(proveedores, soloActivos: true)
            .map((p) => p.id),
        <String>['1'],
      );
    });
  });

  group('serialización de la compra', () {
    test('guarda y recupera ítems, forma de pago y totales', () {
      final compra = Compra(
        id: 'c1',
        empresaId: 'e',
        numeroOrden: 'OC-000001',
        proveedorId: 'prov1',
        proveedorNombre: 'Distribuidora X',
        items: const <ItemCompra>[_item],
        subtotal: 2000,
        iva: 380,
        retencionFuente: 100,
        valorTotal: 2280,
        formaPago: FormaPagoCompra.credito,
      );
      final vuelta = Compra.fromMap('c1', compra.toMap());
      expect(vuelta.numeroOrden, 'OC-000001');
      expect(vuelta.items.length, 1);
      expect(vuelta.formaPago, FormaPagoCompra.credito);
      expect(vuelta.valorTotal, 2280);
      expect(vuelta.retencionFuente, 100);
    });
  });

  testWidgets('el listado muestra las compras de la empresa',
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
        home: ComprasListScreen(
          usuario: usuario,
          comprasRepository: _FakeCompras(<Compra>[
            Compra(
              id: '1',
              empresaId: 'e',
              numeroOrden: 'OC-000001',
              proveedorNombre: 'Distribuidora X',
              valorTotal: 100000,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('OC-000001'), findsOneWidget);
    expect(find.text('Nueva compra'), findsOneWidget);
  });
}
