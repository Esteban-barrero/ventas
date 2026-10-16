import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/catalogo/domain/precio.dart';
import 'package:ventas_app/features/ventas/data/ventas_repository.dart';
import 'package:ventas_app/features/ventas/domain/totales.dart';
import 'package:ventas_app/features/ventas/domain/venta.dart';
import 'package:ventas_app/features/ventas/presentation/ventas_list_screen.dart';

/// Repositorio de ventas en memoria para la prueba de widget.
class _FakeVentas extends VentasRepository {
  _FakeVentas(this.items);

  final List<Venta> items;

  @override
  Stream<List<Venta>> escuchar(String empresaId) => Stream.value(items);
}

const _itemA = ItemVenta(
  productoId: 'p1',
  codigo: 'A-1',
  nombre: 'Camiseta',
  cantidad: 2,
  precioUnitario: 30000,
);
const _itemB = ItemVenta(
  productoId: 'p2',
  codigo: 'B-2',
  nombre: 'Gorra',
  cantidad: 1,
  precioUnitario: 20000,
);

void main() {
  group('regla de envío (RN-03)', () {
    test('presencial y recoger en local no cobran envío', () {
      expect(TipoEntrega.presencial.cobraEnvio, isFalse);
      expect(TipoEntrega.recogerLocal.cobraEnvio, isFalse);
    });
    test('entrega local y envío sí cobran', () {
      expect(TipoEntrega.entregaLocal.cobraEnvio, isTrue);
      expect(TipoEntrega.envio.cobraEnvio, isTrue);
    });
  });

  group('calcularTotales (RF-09, RN-08)', () {
    test('suma subtotales y aplica envío', () {
      final t = calcularTotales(
        items: <ItemVenta>[_itemA, _itemB],
        tipoEntrega: TipoEntrega.envio,
        costoEnvio: 5000,
      );
      expect(t.subtotal, 80000);
      expect(t.envio, 5000);
      expect(t.total, 85000);
    });

    test('ignora el envío en presencial', () {
      final t = calcularTotales(
        items: <ItemVenta>[_itemA],
        tipoEntrega: TipoEntrega.presencial,
        costoEnvio: 5000,
      );
      expect(t.envio, 0);
      expect(t.total, 60000);
    });

    test('resta el descuento y suma impuestos', () {
      final t = calcularTotales(
        items: <ItemVenta>[_itemA, _itemB],
        tipoEntrega: TipoEntrega.presencial,
        descuento: 10000,
        impuestos: 5000,
      );
      expect(t.total, 75000);
    });

    test('el total nunca es negativo', () {
      final t = calcularTotales(
        items: <ItemVenta>[_itemB],
        tipoEntrega: TipoEntrega.presencial,
        descuento: 999999,
      );
      expect(t.total, 0);
    });
  });

  group('serialización de la venta', () {
    test('guarda y recupera ítems, tipo y totales', () {
      final venta = Venta(
        id: 'v1',
        empresaId: 'e',
        numeroFactura: 'FV-000001',
        items: const <ItemVenta>[_itemA, _itemB],
        tipoVenta: TipoPrecio.credito,
        tipoEntrega: TipoEntrega.entregaLocal,
        medioPago: MedioPago.transferenciaNequi,
        subtotal: 80000,
        costoEnvio: 5000,
        total: 85000,
      );
      final vuelta = Venta.fromMap('v1', venta.toMap());
      expect(vuelta.numeroFactura, 'FV-000001');
      expect(vuelta.items.length, 2);
      expect(vuelta.items.first.nombre, 'Camiseta');
      expect(vuelta.tipoVenta, TipoPrecio.credito);
      expect(vuelta.tipoEntrega, TipoEntrega.entregaLocal);
      expect(vuelta.medioPago, MedioPago.transferenciaNequi);
      expect(vuelta.total, 85000);
      expect(vuelta.esCredito, isTrue);
    });
  });

  group('filtros de ventas', () {
    final ventas = <Venta>[
      Venta(
        id: '1',
        empresaId: 'e',
        numeroFactura: 'FV-000001',
        clienteNombre: 'Ana',
        vendedorUid: 'u1',
      ),
      Venta(
        id: '2',
        empresaId: 'e',
        numeroFactura: 'FV-000002',
        clienteNombre: 'Beto',
        vendedorUid: 'u2',
        estado: EstadoVenta.anulada,
      ),
    ];

    test('busca por factura y por cliente', () {
      expect(
        VentasRepository.filtrar(ventas, busqueda: '000002').map((v) => v.id),
        <String>['2'],
      );
      expect(
        VentasRepository.filtrar(ventas, busqueda: 'ana').map((v) => v.id),
        <String>['1'],
      );
    });

    test('filtra por estado y por vendedor', () {
      expect(
        VentasRepository.filtrar(ventas, estado: EstadoVenta.anulada)
            .map((v) => v.id),
        <String>['2'],
      );
      expect(
        VentasRepository.filtrar(ventas, vendedorUid: 'u1').map((v) => v.id),
        <String>['1'],
      );
    });
  });

  testWidgets('el listado muestra las ventas de la empresa',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u1',
      nombre: 'Vendedor',
      email: 'v@ejemplo.com',
      empresaId: 'e',
      roles: <String>['vendedor'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VentasListScreen(
          usuario: usuario,
          ventasRepository: _FakeVentas(<Venta>[
            Venta(
              id: '1',
              empresaId: 'e',
              numeroFactura: 'FV-000001',
              clienteNombre: 'María Pérez',
              total: 30000,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('FV-000001'), findsOneWidget);
    expect(find.text('Nueva venta'), findsOneWidget);
  });
}
