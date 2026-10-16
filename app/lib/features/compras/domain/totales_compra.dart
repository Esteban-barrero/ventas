import 'compra.dart';

/// Totales de una compra (RF-03): subtotal, IVA y **retenciones**.
class TotalesCompra {
  const TotalesCompra({
    required this.subtotal,
    required this.iva,
    required this.retencionFuente,
    required this.retencionIva,
    required this.retencionIca,
    required this.total,
  });

  final double subtotal;
  final double iva;
  final double retencionFuente;
  final double retencionIva;
  final double retencionIca;

  /// Total a pagar al proveedor.
  final double total;

  double get retenciones => retencionFuente + retencionIva + retencionIca;
}

/// Suma de los subtotales de las líneas.
double subtotalCompra(List<ItemCompra> items) =>
    items.fold(0.0, (double a, ItemCompra i) => a + i.subtotal);

/// Suma del IVA de las líneas (según el IVA de cada producto).
double ivaCompra(List<ItemCompra> items) =>
    items.fold(0.0, (double a, ItemCompra i) => a + i.impuesto);

/// Calcula los totales de la compra:
/// `total a pagar = subtotal + IVA − retenciónFuente − reteIVA − reteICA`.
TotalesCompra calcularTotalesCompra(
  List<ItemCompra> items, {
  double retencionFuente = 0,
  double retencionIva = 0,
  double retencionIca = 0,
}) {
  final sub = subtotalCompra(items);
  final iva = ivaCompra(items);
  final rf = retencionFuente > 0 ? retencionFuente : 0.0;
  final ri = retencionIva > 0 ? retencionIva : 0.0;
  final rc = retencionIca > 0 ? retencionIca : 0.0;
  final total = sub + iva - rf - ri - rc;
  return TotalesCompra(
    subtotal: sub,
    iva: iva,
    retencionFuente: rf,
    retencionIva: ri,
    retencionIca: rc,
    total: total < 0 ? 0 : total,
  );
}
