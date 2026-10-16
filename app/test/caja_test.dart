import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/caja/domain/caja.dart';
import 'package:ventas_app/features/caja/domain/calculos_caja.dart';
import 'package:ventas_app/features/ventas/domain/venta.dart' show MedioPago;

void main() {
  group('TipoMovimientoCaja (RF-03, RN-04)', () {
    test('solo el ingreso suma al saldo', () {
      expect(TipoMovimientoCaja.ingreso.suma, isTrue);
      expect(TipoMovimientoCaja.egreso.suma, isFalse);
      expect(TipoMovimientoCaja.retiro.suma, isFalse);
      expect(TipoMovimientoCaja.gasto.suma, isFalse);
    });

    test('desdeId con valor desconocido vuelve a ingreso', () {
      expect(TipoMovimientoCaja.desdeId('retiro'), TipoMovimientoCaja.retiro);
      expect(TipoMovimientoCaja.desdeId('x'), TipoMovimientoCaja.ingreso);
      expect(TipoMovimientoCaja.desdeId(null), TipoMovimientoCaja.ingreso);
    });
  });

  group('MedioPagoCaja (RF-04)', () {
    test('equivale al medio de pago de las ventas', () {
      expect(MedioPagoCaja.desdeVenta(MedioPago.efectivo),
          MedioPagoCaja.efectivo);
      expect(MedioPagoCaja.desdeVenta(MedioPago.tarjeta), MedioPagoCaja.tarjeta);
      expect(MedioPagoCaja.desdeVenta(MedioPago.transferenciaNequi),
          MedioPagoCaja.nequi);
      expect(MedioPagoCaja.desdeVenta(MedioPago.transferenciaBancolombia),
          MedioPagoCaja.bancolombia);
    });
  });

  group('Estados', () {
    test('EstadoCaja.desdeId', () {
      expect(EstadoCaja.desdeId('cerrada'), EstadoCaja.cerrada);
      expect(EstadoCaja.desdeId('otro'), EstadoCaja.abierta);
    });

    test('EstadoDinero.desdeId', () {
      expect(EstadoDinero.desdeId('en_transito'), EstadoDinero.enTransito);
      expect(EstadoDinero.desdeId('nada'), EstadoDinero.enCaja);
    });

    test('ReferenciaCaja.desdeId', () {
      expect(ReferenciaCaja.desdeId('venta'), ReferenciaCaja.venta);
      expect(ReferenciaCaja.desdeId('nada'), ReferenciaCaja.manual);
    });
  });

  group('Cálculos de caja', () {
    test('saldoConMovimiento suma ingresos y resta egresos (RN-04)', () {
      expect(saldoConMovimiento(1000, TipoMovimientoCaja.ingreso, 500), 1500);
      expect(saldoConMovimiento(1000, TipoMovimientoCaja.egreso, 400), 600);
      expect(saldoConMovimiento(1000, TipoMovimientoCaja.retiro, 1000), 0);
      expect(saldoConMovimiento(1000, TipoMovimientoCaja.gasto, 250), 750);
    });

    test('calcularDiferenciaArqueo: sobrante, cuadre y faltante (RN-05)', () {
      expect(calcularDiferenciaArqueo(1200, 1000), 200);
      expect(calcularDiferenciaArqueo(1000, 1000), 0);
      expect(calcularDiferenciaArqueo(900, 1000), -100);
    });
  });

  group('Serialización', () {
    test('Caja ida y vuelta', () {
      final caja = Caja(
        id: 'c1',
        empresaId: 'e1',
        nombre: 'Caja de Ana',
        usuarioUid: 'u1',
        usuarioNombre: 'Ana',
        estado: EstadoCaja.abierta,
        montoInicial: 50000,
        saldo: 70000,
        medioPredominante: MedioPagoCaja.nequi,
        fechaApertura: DateTime.utc(2026, 10, 16, 8),
      );
      final otra = Caja.fromMap('c1', caja.toMap());
      expect(otra.empresaId, 'e1');
      expect(otra.abierta, isTrue);
      expect(otra.saldo, 70000);
      expect(otra.medioPredominante, MedioPagoCaja.nequi);
      expect(otra.fechaApertura?.toUtc(), DateTime.utc(2026, 10, 16, 8));
    });

    test('MovimientoCaja ida y vuelta', () {
      final mov = MovimientoCaja(
        id: 'm1',
        empresaId: 'e1',
        cajaId: 'c1',
        tipo: TipoMovimientoCaja.ingreso,
        concepto: 'Venta contado',
        monto: 30000,
        medioPago: MedioPagoCaja.efectivo,
        referenciaTipo: ReferenciaCaja.venta,
        referenciaId: 'v1',
        responsableUid: 'u1',
        estadoDinero: EstadoDinero.enTransito,
        domiciliario: 'Domi',
        saldoResultante: 100000,
        usuarioUid: 'u1',
        fecha: DateTime.utc(2026, 10, 16, 9),
      );
      final otro = MovimientoCaja.fromMap('m1', mov.toMap());
      expect(otro.tipo, TipoMovimientoCaja.ingreso);
      expect(otro.suma, isTrue);
      expect(otro.monto, 30000);
      expect(otro.referenciaTipo, ReferenciaCaja.venta);
      expect(otro.estadoDinero, EstadoDinero.enTransito);
      expect(otro.domiciliario, 'Domi');
      expect(otro.saldoResultante, 100000);
    });

    test('Arqueo ida y vuelta', () {
      final arqueo = Arqueo(
        id: 'a1',
        empresaId: 'e1',
        cajaId: 'c1',
        fecha: DateTime.utc(2026, 10, 16, 18),
        totalEsperado: 100000,
        totalContado: 95000,
        diferencia: -5000,
        justificacion: 'Faltante de cambio',
        desgloseEfectivo: <String, num>{'50000': 1, '20000': 2},
        usuarioUid: 'u1',
      );
      final otro = Arqueo.fromMap('a1', arqueo.toMap());
      expect(otro.diferencia, -5000);
      expect(otro.justificacion, 'Faltante de cambio');
      expect(otro.desgloseEfectivo['50000'], 1);
      expect(otro.totalContado, 95000);
    });
  });
}
