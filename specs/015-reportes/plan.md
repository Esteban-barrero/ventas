# Plan Técnico: Reportes

- **ID:** 015 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `reportes` en Flutter. Las consultas se hacen con filtros por `empresaId` y rango de
fechas. Para el volumen alto se usan **colecciones de resumen** (agregados) actualizadas por
**Cloud Functions** o en línea. La exportación genera PDF/Excel/CSV. El panel usa `fl_chart`.

## 2. Arquitectura

```
Flutter (reportes_home, filtros, charts, export)
   │
ReportesRepository (data)
   ├─ ventas / cartera / inventario / caja / compras / utilidades
   ├─ panel (KPIs)
   └─ consolidado (Super Admin)

Cloud Functions (opcional)
   └─ generarResumenDiario  -> colecciones de resumen
Exportacion: pdf | excel | csv
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/reportes/
├── data/
│   ├── reportes_repository.dart
│   └── models/{kpi_model,resumen_model}.dart
├── domain/
│   ├── entities/{filtro_reporte,resultado_reporte}.dart
│   └── usecases/{calcular_utilidad,calcular_rotacion,exportar}.dart
└── presentation/
    ├── reportes_home_screen.dart
    ├── ventas_reporte_screen.dart
    ├── cartera_reporte_screen.dart
    ├── inventario_reporte_screen.dart
    ├── caja_reporte_screen.dart
    ├── compras_reporte_screen.dart
    ├── utilidad_reporte_screen.dart
    ├── panel_screen.dart
    ├── consolidado_screen.dart
    └── providers/reportes_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones de resumen: `resumen_ventas_diario`, etc.

## 5. Cálculos (domain)

```
utilidad        = (precioVenta - costo) * cantidad
margenPorcentaje = (precioVenta - costo) / precioVenta * 100
valorizacion    = stock * costo
rotacion        = unidadesVendidas / stockPromedio
carteraVencida  = Σ cuotas vencidas (saldo)
```

## 6. Contratos / Interfaces

Ver [`contracts/reportes-contracts.md`](./contracts/reportes-contracts.md).

- `ReportesRepository.ventas(filtro)`
- `ReportesRepository.cartera(filtro)`
- `ReportesRepository.inventario(filtro)`
- `ReportesRepository.caja(filtro)`
- `ReportesRepository.utilidad(filtro)`
- `ReportesRepository.panel(filtro)`
- `Exportador.exportar(resultado, formato)`

## 7. Reglas de Seguridad

```
match /resumen_ventas_diario/{doc} {
  allow read: if esSuperAdmin() ||
    (request.auth != null && resource.data.empresaId == request.auth.token.empresaId);
  allow write: if false;   // solo Cloud Functions
}
```

> Los reportes se calculan sobre datos ya protegidos; cada consulta filtra por `empresaId`.

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`, `cloud_functions`
- `fl_chart` (gráficos)
- `pdf` + `printing` (PDF)
- `excel` (XLSX), `csv` (CSV), `share_plus`
- `intl`, `flutter_riverpod`

## 9. Estrategia de Pruebas

- **Unit:** utilidad, margen, rotación, valorización, cartera vencida.
- **Widget:** filtros, gráficos, panel.
- **Integration:** consulta por rango de fechas y exportación.

## 10. Riesgos

- Volumen alto → **agregados** y paginación.
- Consistencia de resúmenes → reproceso programado.
- Exportaciones grandes → límites y generación en segundo plano.
- Costo histórico de la venta → guardarlo en la venta para utilidad exacta.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Filtros estándar por `empresaId` + rango de fechas + sucursal.
- **ADR-002:** **Colecciones de resumen** para KPIs y gráficos rápidos.
- **ADR-003:** Exportación **PDF/Excel/CSV**.
- **ADR-004:** El **Vendedor** solo ve sus ventas; el Super Admin ve el **consolidado**.
- **ADR-005:** Guardar el **costo al momento de la venta** para utilidad exacta.
