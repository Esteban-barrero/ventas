import '../../ventas/domain/venta.dart' show MedioPago, TipoEntrega;
import 'movimiento_dinero.dart';

/// Cálculos de tesorería (spec 016). Aislados para poder probarlos.

/// Calcula el **saldo por ubicación** a partir del libro de movimientos
/// (RF-03, RN-02).
///
/// - `ingreso`: suma en su ubicación.
/// - `egreso`: resta en su ubicación.
/// - `traslado`: resta en el origen y suma en el destino (neto 0).
Map<UbicacionDinero, double> calcularPosiciones(List<MovimientoDinero> movimientos) {
  final saldo = <UbicacionDinero, double>{};
  for (final MovimientoDinero m in movimientos) {
    switch (m.tipo) {
      case TipoMovimientoDinero.ingreso:
        saldo[m.ubicacion] = (saldo[m.ubicacion] ?? 0) + m.monto;
      case TipoMovimientoDinero.egreso:
        saldo[m.ubicacion] = (saldo[m.ubicacion] ?? 0) - m.monto;
      case TipoMovimientoDinero.traslado:
        final destino = m.ubicacionDestino;
        saldo[m.ubicacion] = (saldo[m.ubicacion] ?? 0) - m.monto;
        if (destino != null) {
          saldo[destino] = (saldo[destino] ?? 0) + m.monto;
        }
    }
  }
  return saldo;
}

/// Suma de todas las ubicaciones: el **total del dinero** de la empresa (RF-03).
double totalDePosiciones(Map<UbicacionDinero, double> posiciones) =>
    posiciones.values.fold(0.0, (double a, double b) => a + b);

/// Saldo por ubicación **y responsable** (RF-02, RF-04): responde "cuánto hay y
/// quién lo tiene".
Map<UbicacionDinero, Map<String, double>> posicionesPorResponsable(
  List<MovimientoDinero> movimientos,
) {
  final res = <UbicacionDinero, Map<String, double>>{};
  void add(UbicacionDinero u, String r, double v) {
    final porResp = res.putIfAbsent(u, () => <String, double>{});
    porResp[r] = (porResp[r] ?? 0) + v;
  }

  for (final MovimientoDinero m in movimientos) {
    final r = m.responsableNombre.isNotEmpty
        ? m.responsableNombre
        : (m.responsableUid.isNotEmpty ? m.responsableUid : 'Sin responsable');
    switch (m.tipo) {
      case TipoMovimientoDinero.ingreso:
        add(m.ubicacion, r, m.monto);
      case TipoMovimientoDinero.egreso:
        add(m.ubicacion, r, -m.monto);
      case TipoMovimientoDinero.traslado:
        add(m.ubicacion, r, -m.monto);
        final destino = m.ubicacionDestino;
        if (destino != null) add(destino, r, m.monto);
    }
  }
  return res;
}

/// Ubicación del dinero de un **cobro** de crédito (RN-04).
///
/// El efectivo queda **con el cobrador** (vendedor) hasta que lo entregue; las
/// transferencias y la tarjeta van a Nequi, banco y "tarjeta por consignar".
UbicacionDinero ubicacionDeCobro(MedioPago medio) => switch (medio) {
      MedioPago.efectivo => UbicacionDinero.vendedorEfectivo,
      MedioPago.transferenciaNequi => UbicacionDinero.nequi,
      MedioPago.transferenciaBancolombia => UbicacionDinero.banco,
      MedioPago.tarjeta => UbicacionDinero.tarjetaPorConsignar,
    };

/// Ubicación del dinero de una **venta de contado** (RN-04).
///
/// El efectivo va a la caja física si es presencial; si es a domicilio o contra
/// entrega, queda en tránsito con el vendedor. Las transferencias y la tarjeta
/// van a Nequi, banco y "tarjeta por consignar".
UbicacionDinero ubicacionDeVenta(MedioPago medio, TipoEntrega entrega) {
  if (medio == MedioPago.efectivo) {
    final aDomicilio = entrega == TipoEntrega.entregaLocal ||
        entrega == TipoEntrega.envio;
    return aDomicilio
        ? UbicacionDinero.contraEntrega
        : UbicacionDinero.cajaFisica;
  }
  return switch (medio) {
    MedioPago.transferenciaNequi => UbicacionDinero.nequi,
    MedioPago.transferenciaBancolombia => UbicacionDinero.banco,
    MedioPago.tarjeta => UbicacionDinero.tarjetaPorConsignar,
    MedioPago.efectivo => UbicacionDinero.cajaFisica,
  };
}
