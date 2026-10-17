# Tareas: Reportes

- **ID:** 015 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14
- **Estado:** implementado el **panel de reportes** (ventas, utilidad, cartera,
  inventario, dinero y pedidos) con filtro por fechas. Exportaciones, gráficos y
  consolidado del Super Admin quedan pendientes.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de `features/reportes`
- [x] T002 Definir `RangoFechas` y los resúmenes (`domain/reportes.dart`)
- [x] T003 Definir las fórmulas (utilidad, margen, valorización)

## Fase 2 — Lógica de Reportes

- [x] T010 Reporte de **ventas** (total, contado/crédito, por medio y vendedor)
- [x] T011 Reporte de **cartera/créditos** (saldo, vencida, morosos)
- [x] T012 Reporte de **inventario** (valorización, bajo stock, agotados)
- [x] T013 Reporte de **dinero** (ingresos/egresos por medio)
- [ ] T014 Reporte de **compras** y cuentas por pagar (pendiente)
- [x] T015 Reporte de **utilidades** (por producto y total)
- [x] T016 Reporte de **pedidos** por estado
- [x] T017 **Panel** de KPIs (consolidado Super Admin pendiente)

## Fase 3 — Agregados y Rendimiento

- [ ] T020 Colecciones de resumen (pendiente)
- [ ] T021 Cloud Function `generarResumenDiario` (pendiente)
- [ ] T022 Paginación y límites (pendiente)

## Fase 4 — Interfaz y Exportación

- [x] T030 Pantalla de reportes con filtros (Hoy/Semana/Mes/Año/Todo)
- [ ] T031 Gráficos (pendiente)
- [ ] T032 Exportación a PDF (pendiente)
- [ ] T033 Exportación a Excel (pendiente)
- [ ] T034 Exportación a CSV (pendiente)
- [ ] T035 Reportes programados por correo (pendiente)

## Fase 5 — Seguridad y Cierre

- [x] T040 Reglas: se reutilizan las de cada colección (por empresa)
- [ ] T041 Restringir al Vendedor a sus propias ventas (pendiente)
- [ ] T042 Auditoría de exportaciones (pendiente)
- [x] T043 Pruebas unitarias del dominio de reportes
- [x] T044 Ejecutar `flutter analyze` y `flutter test`
- [x] T045 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [x] Panel y reportes principales
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando
- [x] Commit y push realizados
