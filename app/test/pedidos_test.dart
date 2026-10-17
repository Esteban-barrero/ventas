import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/catalogo/domain/precio.dart';
import 'package:ventas_app/features/clientes/domain/cliente.dart' show Direccion;
import 'package:ventas_app/features/pedidos/domain/pedido.dart';
import 'package:ventas_app/features/ventas/domain/venta.dart'
    show MedioPago, TipoEntrega;

void main() {
  const item = ItemPedido(
    productoId: 'p1',
    codigo: 'A-1',
    nombre: 'Camiseta',
    cantidad: 2,
    precioUnitario: 1500,
    iva: 19,
    costoUnitario: 1000,
  );

  Pedido pedido({EstadoPedido estado = EstadoPedido.pendiente}) => Pedido(
        id: 'p1',
        empresaId: 'e1',
        numero: 'PED-000001',
        clienteUid: 'u1',
        clienteNombre: 'Ana',
        cedula: '123',
        telefono: '300',
        direccion: const Direccion(ciudad: 'Bogotá', direccion: 'Calle 1'),
        items: const <ItemPedido>[item],
        subtotal: 3000,
        costoEnvio: 500,
        impuestos: 570,
        total: 4070,
        tipoEntrega: TipoEntrega.entregaLocal,
        medioPago: MedioPago.efectivo,
        estado: estado,
      );

  group('ItemPedido (RN-04)', () {
    test('subtotal, impuesto y utilidad', () {
      expect(item.subtotal, 3000);
      expect(item.impuesto, closeTo(570, 0.001));
      expect(item.utilidad, 1000);
    });
  });

  group('Pedido: totales y utilidad', () {
    test('costo, utilidad y margen', () {
      final p = pedido();
      expect(p.costoTotal, 2000);
      expect(p.utilidadTotal, 1000);
      expect(p.margenPct, closeTo(33.333, 0.01));
    });

    test('estados base', () {
      expect(pedido().pendiente, isTrue);
      expect(pedido().aprobado, isFalse);
      expect(pedido(estado: EstadoPedido.cancelado).cancelado, isTrue);
    });
  });

  group('Estados y origen', () {
    test('EstadoPedido.desdeId', () {
      expect(EstadoPedido.desdeId('confirmado'), EstadoPedido.confirmado);
      expect(EstadoPedido.desdeId('cancelado'), EstadoPedido.cancelado);
      expect(EstadoPedido.desdeId('x'), EstadoPedido.pendiente);
    });

    test('OrigenPedido.desdeId', () {
      expect(OrigenPedido.desdeId('invitado'), OrigenPedido.invitado);
      expect(OrigenPedido.desdeId('x'), OrigenPedido.cliente);
    });
  });

  group('Serialización', () {
    test('Pedido ida y vuelta', () {
      final original = pedido();
      final copia = Pedido.fromMap('p1', original.toMap());
      expect(copia.numero, 'PED-000001');
      expect(copia.clienteNombre, 'Ana');
      expect(copia.direccion.ciudad, 'Bogotá');
      expect(copia.items.single.cantidad, 2);
      expect(copia.total, 4070);
      expect(copia.tipoEntrega, TipoEntrega.entregaLocal);
      expect(copia.medioPago, MedioPago.efectivo);
      expect(copia.tipoPago, TipoPrecio.contado);
      expect(copia.estado, EstadoPedido.pendiente);
    });
  });
}
