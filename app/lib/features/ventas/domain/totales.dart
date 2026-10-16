import 'venta.dart';

/// Resultado del cálculo de totales de una venta (RF-09, RN-08).
class TotalesVenta {
  const TotalesVenta({
    required this.subtotal,
    required this.envio,
    required this.descuento,
    required this.impuestos,
    required this.total,
  });

  final double subtotal;
  final double envio;
  final double descuento;
  final double impuestos;
  final double total;
}

/// Suma de los subtotales de las líneas.
double subtotalDe(List<ItemVenta> items) =>
    items.fold(0.0, (double a, ItemVenta i) => a + i.subtotal);

/// Impuestos según el **IVA** configurado en la empresa (porcentaje).
///
/// El IVA se aplica sobre el subtotal de los productos (no sobre el envío).
double impuestosPorIva(double subtotal, double ivaPct) =>
    ivaPct <= 0 ? 0.0 : subtotal * ivaPct / 100;

/// Calcula los totales de la venta (RN-03, RN-08):
///
/// - El **envío** solo aplica en `entrega_local` y `envio` (0 si presencial o
///   recoger en local).
/// - **total = subtotal + envío − descuento + impuestos**, nunca negativo.
TotalesVenta calcularTotales({
  required List<ItemVenta> items,
  required TipoEntrega tipoEntrega,
  double costoEnvio = 0,
  double descuento = 0,
  double impuestos = 0,
}) {
  final subtotal = subtotalDe(items);
  final envio =
      tipoEntrega.cobraEnvio && costoEnvio > 0 ? costoEnvio : 0.0;
  final desc = descuento > 0 ? descuento : 0.0;
  final imp = impuestos > 0 ? impuestos : 0.0;
  final total = subtotal + envio - desc + imp;
  return TotalesVenta(
    subtotal: subtotal,
    envio: envio,
    descuento: desc,
    impuestos: imp,
    total: total < 0 ? 0 : total,
  );
}
