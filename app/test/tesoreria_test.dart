import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/caja/domain/caja.dart';
import 'package:ventas_app/features/tesoreria/domain/movimiento_dinero.dart';
import 'package:ventas_app/features/tesoreria/domain/posiciones.dart';
import 'package:ventas_app/features/tesoreria/domain/rendicion.dart';
import 'package:ventas_app/features/ventas/domain/venta.dart'
    show MedioPago, TipoEntrega;

void main() {
  group('Tipos y ubicaciones (spec 016)', () {
    test('solo el ingreso suma a la ubicación de origen', () {
      expect(TipoMovimientoDinero.ingreso.suma, isTrue);
      expect(TipoMovimientoDinero.egreso.suma, isFalse);
      expect(TipoMovimientoDinero.traslado.suma, isFalse);
    });

    test('UbicacionDinero.desdeId', () {
      expect(UbicacionDinero.desdeId('nequi'), UbicacionDinero.nequi);
      expect(UbicacionDinero.desdeId('otro'), UbicacionDinero.cajaFisica);
    });

    test('MedioDinero equivale al medio de pago de ventas', () {
      expect(MedioDinero.desdeVenta(MedioPago.efectivo), MedioDinero.efectivo);
      expect(MedioDinero.desdeVenta(MedioPago.tarjeta), MedioDinero.tarjeta);
      expect(MedioDinero.desdeVenta(MedioPago.transferenciaNequi),
          MedioDinero.nequi);
      expect(MedioDinero.desdeVenta(MedioPago.transferenciaBancolombia),
          MedioDinero.bancolombia);
    });
  });

  group('Posiciones del dinero (RF-03)', () {
    MovimientoDinero mov(
      TipoMovimientoDinero tipo,
      double monto,
      UbicacionDinero ubicacion, {
      UbicacionDinero? destino,
    }) =>
        MovimientoDinero(
          id: 'm',
          empresaId: 'e1',
          tipo: tipo,
          monto: monto,
          ubicacion: ubicacion,
          ubicacionDestino: destino,
        );

    test('ingresos y egresos por ubicación', () {
      final pos = calcularPosiciones(<MovimientoDinero>[
        mov(TipoMovimientoDinero.ingreso, 1000, UbicacionDinero.cajaFisica),
        mov(TipoMovimientoDinero.ingreso, 500, UbicacionDinero.cajaFisica),
        mov(TipoMovimientoDinero.egreso, 300, UbicacionDinero.cajaFisica),
        mov(TipoMovimientoDinero.ingreso, 250, UbicacionDinero.nequi),
      ]);
      expect(pos[UbicacionDinero.cajaFisica], 1200);
      expect(pos[UbicacionDinero.nequi], 250);
      expect(totalDePosiciones(pos), 1450);
    });

    test('el traslado no cambia el total (RN-02)', () {
      final base = <MovimientoDinero>[
        mov(TipoMovimientoDinero.ingreso, 1000, UbicacionDinero.nequi),
      ];
      final conTraslado = <MovimientoDinero>[
        ...base,
        mov(TipoMovimientoDinero.traslado, 400, UbicacionDinero.nequi,
            destino: UbicacionDinero.cajaFisica),
      ];
      final pos = calcularPosiciones(conTraslado);
      expect(pos[UbicacionDinero.nequi], 600);
      expect(pos[UbicacionDinero.cajaFisica], 400);
      expect(totalDePosiciones(pos), totalDePosiciones(calcularPosiciones(base)));
      expect(totalDePosiciones(pos), 1000);
    });

    test('desglose por responsable (RF-02)', () {
      final porResp = posicionesPorResponsable(<MovimientoDinero>[
        MovimientoDinero(
          id: 'a',
          empresaId: 'e1',
          tipo: TipoMovimientoDinero.ingreso,
          monto: 20000,
          ubicacion: UbicacionDinero.contraEntrega,
          responsableNombre: 'Pepito',
        ),
        MovimientoDinero(
          id: 'b',
          empresaId: 'e1',
          tipo: TipoMovimientoDinero.ingreso,
          monto: 50000,
          ubicacion: UbicacionDinero.nequi,
          responsableNombre: 'Marta',
        ),
      ]);
      expect(porResp[UbicacionDinero.contraEntrega]?['Pepito'], 20000);
      expect(porResp[UbicacionDinero.nequi]?['Marta'], 50000);
    });
  });

  group('Ubicación del dinero (RN-04)', () {
    test('venta de contado según medio y entrega', () {
      expect(ubicacionDeVenta(MedioPago.efectivo, TipoEntrega.presencial),
          UbicacionDinero.cajaFisica);
      expect(ubicacionDeVenta(MedioPago.efectivo, TipoEntrega.envio),
          UbicacionDinero.contraEntrega);
      expect(ubicacionDeVenta(MedioPago.transferenciaNequi, TipoEntrega.presencial),
          UbicacionDinero.nequi);
      expect(
          ubicacionDeVenta(MedioPago.transferenciaBancolombia, TipoEntrega.presencial),
          UbicacionDinero.banco);
      expect(ubicacionDeVenta(MedioPago.tarjeta, TipoEntrega.presencial),
          UbicacionDinero.tarjetaPorConsignar);
    });

    test('cobro de crédito en efectivo queda con el cobrador', () {
      expect(ubicacionDeCobro(MedioPago.efectivo),
          UbicacionDinero.vendedorEfectivo);
      expect(ubicacionDeCobro(MedioPago.transferenciaNequi),
          UbicacionDinero.nequi);
    });
  });

  group('Serialización', () {
    test('MovimientoDinero ida y vuelta', () {
      final mov = MovimientoDinero(
        id: 'm1',
        empresaId: 'e1',
        tipo: TipoMovimientoDinero.traslado,
        monto: 30000,
        medioPago: MedioDinero.efectivo,
        ubicacion: UbicacionDinero.vendedorEfectivo,
        ubicacionDestino: UbicacionDinero.cajaFisica,
        responsableUid: 'u1',
        responsableNombre: 'Pepito',
        descripcion: 'Entrega de recaudo',
        referenciaTipo: ReferenciaDinero.traslado,
        cajaId: 'c1',
        usuarioUid: 'u1',
        fecha: DateTime.utc(2026, 10, 16, 9),
      );
      final otro = MovimientoDinero.fromMap('m1', mov.toMap());
      expect(otro.tipo, TipoMovimientoDinero.traslado);
      expect(otro.ubicacion, UbicacionDinero.vendedorEfectivo);
      expect(otro.ubicacionDestino, UbicacionDinero.cajaFisica);
      expect(otro.responsableNombre, 'Pepito');
      expect(otro.monto, 30000);
    });

    test('Caja ida y vuelta', () {
      final caja = Caja(
        id: 'c1',
        empresaId: 'e1',
        nombre: 'Caja de Ana',
        usuarioUid: 'u1',
        usuarioNombre: 'Ana',
        montoInicial: 50000,
        saldo: 70000,
        medioPredominante: MedioDinero.nequi,
        fechaApertura: DateTime.utc(2026, 10, 16, 8),
      );
      final otra = Caja.fromMap('c1', caja.toMap());
      expect(otra.abierta, isTrue);
      expect(otra.saldo, 70000);
      expect(otra.medioPredominante, MedioDinero.nequi);
    });
  });

  group('Rendición de efectivo (spec 016, RF-05)', () {
    test('EstadoRendicion.desdeId con valor desconocido vuelve a pendiente', () {
      expect(EstadoRendicion.desdeId('confirmada'), EstadoRendicion.confirmada);
      expect(EstadoRendicion.desdeId('rechazada'), EstadoRendicion.rechazada);
      expect(EstadoRendicion.desdeId('x'), EstadoRendicion.pendiente);
      expect(EstadoRendicion.desdeId(null), EstadoRendicion.pendiente);
    });

    test('serializa entrega, recepción y diferencia', () {
      final r = Rendicion(
        id: 'r1',
        empresaId: 'e1',
        fecha: DateTime.utc(2026, 10, 16, 9),
        domiciliarioUid: 'u9',
        domiciliarioNombre: 'Pepito',
        montoDeclarado: 50000,
        estado: EstadoRendicion.pendiente,
      );
      expect(r.pendiente, isTrue);
      final copia = Rendicion.fromMap('r1', r.toMap());
      expect(copia.domiciliarioNombre, 'Pepito');
      expect(copia.montoDeclarado, 50000);
      expect(copia.estado, EstadoRendicion.pendiente);
    });

    test('la diferencia es declarado − contado (faltante o sobrante)', () {
      final faltante = Rendicion(
        id: 'r2',
        empresaId: 'e1',
        montoDeclarado: 50000,
        montoContado: 48000,
        diferencia: 50000 - 48000,
        estado: EstadoRendicion.confirmada,
      );
      expect(faltante.diferencia, 2000);
      expect(faltante.pendiente, isFalse);
      final sobrante = Rendicion(
        id: 'r3',
        empresaId: 'e1',
        montoDeclarado: 50000,
        montoContado: 52000,
        diferencia: 50000 - 52000,
      );
      expect(sobrante.diferencia, -2000);
    });
  });
}
