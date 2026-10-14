# Contratos: Reportes

- **ID:** 015 | **Fecha:** 2026-10-14

---

## 1. Interfaz `ReportesRepository` (Dart)

```dart
abstract class ReportesRepository {
  Future<ResultadoReporte> ventas(FiltroReporte f);
  Future<ResultadoReporte> cartera(FiltroReporte f);
  Future<ResultadoReporte> inventario(FiltroReporte f);
  Future<ResultadoReporte> caja(FiltroReporte f);
  Future<ResultadoReporte> compras(FiltroReporte f);
  Future<ResultadoReporte> utilidad(FiltroReporte f);
  Future<ResultadoReporte> pedidosEnvios(FiltroReporte f);
  Future<PanelKpi> panel(FiltroReporte f);
  Future<List<PanelKpi>> consolidado(FiltroReporte f);   // Super Admin
}
```

---

## 2. Exportador

```dart
abstract class Exportador {
  Future<Uint8List> aPdf(ResultadoReporte r, String titulo);
  Future<Uint8List> aExcel(ResultadoReporte r);
  Future<Uint8List> aCsv(ResultadoReporte r);
}
```

---

## 3. Cálculo de utilidad (Dart)

```dart
double utilidad(ItemVenta i, double costoMomento) =>
    (i.precioUnitario - costoMomento) * i.cantidad;

double margenPorcentaje(double precio, double costo) =>
    precio == 0 ? 0 : (precio - costo) / precio * 100;
```

---

## 4. Consulta de ventas con filtro (Dart)

```dart
Future<ResultadoReporte> ventas(FiltroReporte f) async {
  Query q = firestore.collection('ventas')
    .where('empresaId', isEqualTo: f.empresaId)
    .where('fecha', isGreaterThanOrEqualTo: f.desde)
    .where('fecha', isLessThanOrEqualTo: f.hasta);

  if (f.vendedorUid != null) q = q.where('vendedorUid', isEqualTo: f.vendedorUid);
  if (f.clienteId != null)   q = q.where('clienteId', isEqualTo: f.clienteId);
  if (f.tipoVenta != null)   q = q.where('tipoVenta', isEqualTo: f.tipoVenta);

  final snap = await q.orderBy('fecha', descending: true).get();
  final ventas = snap.docs.map((d) => Venta.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();

  final total = ventas.fold<double>(0, (a, v) => a + v.total);
  final util = ventas.fold<double>(0, (a, v) =>
      a + v.items.fold<double>(0, (b, i) => b + utilidad(i, v.costoMomento(i.productoId))));

  return ResultadoReporte(filas: ventas.map((v) => v.toRow()).toList(),
      totales: {'total': total, 'utilidad': util});
}
```

---

## 5. Cloud Function: resumen diario

```typescript
export const generarResumenDiario = functions.pubsub
  .schedule('every day 01:00')
  .timeZone('America/Bogota')
  .onRun(async () => {
    const ayer = fechaAyer();   // YYYY-MM-DD
    const empresas = await admin.firestore().collection('empresas').get();

    for (const emp of empresas.docs) {
      const ventas = await admin.firestore().collection('ventas')
        .where('empresaId', '==', emp.id)
        .where('fecha', '>=', inicioDelDia(ayer))
        .where('fecha', '<', finDelDia(ayer)).get();

      let total = 0, contado = 0, credito = 0, utilidad = 0;
      const porVendedor: Record<string, number> = {};
      const porMedioPago: Record<string, number> = {};

      ventas.forEach((v) => {
        const d = v.data();
        total += d.total;
        if (d.tipoVenta === 'contado') contado += d.total; else credito += d.total;
        utilidad += (d.utilidad ?? 0);
        porVendedor[d.vendedorUid] = (porVendedor[d.vendedorUid] ?? 0) + d.total;
        porMedioPago[d.medioPago] = (porMedioPago[d.medioPago] ?? 0) + d.total;
      });

      await admin.firestore().collection('resumen_ventas_diario')
        .doc(`${emp.id}_${ayer}`)
        .set({
          empresaId: emp.id, fecha: ayer, totalVentas: total,
          numeroVentas: ventas.size, totalContado: contado, totalCredito: credito,
          utilidad, porVendedor, porMedioPago,
          fechaCalculo: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
  });
```

> Requiere que cada venta guarde el campo `utilidad` (o el `costoMomento` por ítem) al registrarse.

---

## 6. Reglas de Firestore

```
match /resumen_ventas_diario/{doc} {
  allow read: if esSuperAdmin() ||
    (request.auth != null && resource.data.empresaId == request.auth.token.empresaId);
  allow write: if false;   // solo Cloud Functions
}
```

> Las consultas de detalle (ventas, créditos, etc.) respetan las reglas de cada colección y el
> aislamiento por `empresaId`.

---

## 7. Entidades (resumen)

```dart
class FiltroReporte {
  String empresaId;
  DateTime desde, hasta;
  String? vendedorUid, clienteId, productoId, tipoVenta, bodegaId;
}

class ResultadoReporte {
  List<Map<String, dynamic>> filas;
  Map<String, num> totales;
  Map<String, dynamic>? grafico;   // datos para fl_chart
}

class PanelKpi {
  String empresaId;
  double ventasMes, utilidadMes, carteraTotal, carteraVencida, valorizacionInventario;
  int numeroVentas, clientesMorosos, itemsBajoStock;
}
```
