import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/catalogo/domain/precio.dart';
import 'package:ventas_app/features/catalogo/domain/producto.dart';
import 'package:ventas_app/features/creditos/domain/credito.dart';
import 'package:ventas_app/features/pedidos/domain/pedido.dart';
import 'package:ventas_app/features/reportes/domain/reportes.dart';
import 'package:ventas_app/features/tesoreria/domain/movimiento_dinero.dart';
import 'package:ventas_app/features/ventas/domain/venta.dart';

void main() {
  final ahora = DateTime(2026, 10, 15, 12);
  final rangoMes = RangoFechas.mes(ahora);
  final enMes = DateTime(2026, 10, 10);
  final fuera = DateTime(2026, 9, 10);

  group('RangoFechas', () {
    test('incluye dentro y excluye fuera', () {
      expect(rangoMes.incluye(enMes), isTrue);
      expect(rangoMes.incluye(fuera), isFalse);
      expect(rangoMes.incluye(null), isFalse);
    });

    test('todo incluye cualquier fecha', () {
      expect(RangoFechas.todo.incluye(fuera), isTrue);
    });
  });

  group('calcularResumenVentas (RF-01, RF-06)', () {
    Venta venta({
      required String id,
      required double total,
      required double utilidad,
      TipoPrecio tipo = TipoPrecio.contado,
      MedioPago medio = MedioPago.efectivo,
      DateTime? fecha,
      EstadoVenta estado = EstadoVenta.registrada,
    }) =>
        Venta(
          id: id,
          empresaId: 'e1',
          vendedorNombre: 'Ana',
          total: total,
          utilidadTotal: utilidad,
          tipoVenta: tipo,
          medioPago: medio,
          fecha: fecha ?? enMes,
          estado: estado,
        );

    test('suma totales, utilidad, medios y excluye anuladas/fuera de rango', () {
      final r = calcularResumenVentas(<Venta>[
        venta(id: 'v1', total: 1000, utilidad: 200),
        venta(
            id: 'v2',
            total: 2000,
            utilidad: 500,
            tipo: TipoPrecio.credito,
            medio: MedioPago.transferenciaNequi),
        venta(id: 'v3', total: 5000, utilidad: 1000, estado: EstadoVenta.anulada),
        venta(id: 'v4', total: 9000, utilidad: 100, fecha: fuera),
      ], rangoMes);

      expect(r.total, 3000);
      expect(r.contado, 1000);
      expect(r.credito, 2000);
      expect(r.utilidad, 700);
      expect(r.numero, 2);
      expect(r.porMedio['Efectivo'], 1000);
      expect(r.porMedio['Transferencia Nequi'], 2000);
      expect(r.porVendedor['Ana'], 3000);
    });
  });

  group('calcularResumenInventario (RF-03, RN-06)', () {
    Producto p({required int stock, required double costo, int min = 0}) =>
        Producto(
          id: 'p$stock$costo',
          empresaId: 'e1',
          codigo: 'C',
          nombre: 'N',
          stock: stock,
          costo: costo,
          stockMinimo: min,
        );

    test('valorización, bajo stock y agotados', () {
      final r = calcularResumenInventario(<Producto>[
        p(stock: 10, costo: 100),
        p(stock: 2, costo: 50, min: 3),
        p(stock: 0, costo: 30),
      ]);
      expect(r.valorizacion, 1000 + 100);
      expect(r.productos, 3);
      expect(r.bajoStock, 1);
      expect(r.agotados, 1);
    });
  });

  group('calcularResumenCartera (RF-02)', () {
    Credito c({required double saldo, int mora = 0, EstadoCredito estado = EstadoCredito.activo}) =>
        Credito(
          id: 'c${saldo}mora',
          empresaId: 'e1',
          clienteId: 'cli',
          saldoActual: saldo,
          diasMora: mora,
          estado: estado,
        );

    test('saldo, vencida y morosos', () {
      final r = calcularResumenCartera(<Credito>[
        c(saldo: 1000),
        c(saldo: 2000, mora: 5),
        c(saldo: 500, estado: EstadoCredito.pagado),
        c(saldo: 0),
      ]);
      expect(r.total, 3000);
      expect(r.vencida, 2000);
      expect(r.morosos, 1);
      expect(r.creditos, 2);
    });
  });

  group('calcularResumenDinero (RF-04)', () {
    test('ingresos y egresos; los traslados no cambian el total', () {
      final r = calcularResumenDinero(<MovimientoDinero>[
        MovimientoDinero(
            id: 'm1',
            empresaId: 'e1',
            tipo: TipoMovimientoDinero.ingreso,
            monto: 1000,
            fecha: enMes),
        MovimientoDinero(
            id: 'm2',
            empresaId: 'e1',
            tipo: TipoMovimientoDinero.egreso,
            monto: 300,
            fecha: enMes),
        MovimientoDinero(
            id: 'm3',
            empresaId: 'e1',
            tipo: TipoMovimientoDinero.traslado,
            monto: 200,
            ubicacionDestino: UbicacionDinero.banco,
            fecha: enMes),
      ], rangoMes);
      expect(r.ingresos, 1000);
      expect(r.egresos, 300);
      expect(r.neto, 700);
    });
  });

  group('calcularResumenPedidos (RF-07)', () {
    test('cuenta por estado', () {
      final r = calcularResumenPedidos(<Pedido>[
        Pedido(id: 'p1', empresaId: 'e1', fechaCreacion: enMes),
        Pedido(
            id: 'p2',
            empresaId: 'e1',
            estado: EstadoPedido.confirmado,
            fechaCreacion: enMes),
        Pedido(
            id: 'p3',
            empresaId: 'e1',
            estado: EstadoPedido.cancelado,
            fechaCreacion: enMes),
        Pedido(id: 'p4', empresaId: 'e1', fechaCreacion: fuera),
      ], rangoMes);
      expect(r.total, 3);
      expect(r.pendientes, 1);
      expect(r.confirmados, 1);
      expect(r.cancelados, 1);
    });
  });
}
