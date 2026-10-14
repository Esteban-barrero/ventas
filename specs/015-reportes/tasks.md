# Tareas: Reportes

- **ID:** 015 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de `features/reportes`
- [ ] T002 Definir entidades `FiltroReporte` y `ResultadoReporte`
- [ ] T003 Definir las fórmulas (utilidad, margen, rotación, valorización)

## Fase 2 — Lógica de Reportes

- [ ] T010 Implementar reporte de **ventas** (fecha, vendedor, cliente, producto, tipo)
- [ ] T011 Implementar reporte de **cartera/créditos** (saldos, mora, recaudo)
- [ ] T012 Implementar reporte de **inventario** (valorización, bajo stock, rotación)
- [ ] T013 Implementar reporte de **caja** (medios de pago, arqueos, diferencias)
- [ ] T014 Implementar reporte de **compras** y cuentas por pagar
- [ ] T015 Implementar reporte de **utilidades** (margen)
- [ ] T016 Implementar reporte de **pedidos y envíos**
- [ ] T017 Implementar **panel** de KPIs y **consolidado** (Super Admin)

## Fase 3 — Agregados y Rendimiento

- [ ] T020 Implementar colecciones de **resumen** (diario/mensual)
- [ ] T021 Cloud Function `generarResumenDiario`
- [ ] T022 Paginación y límites en consultas grandes

## Fase 4 — Interfaz y Exportación

- [ ] T030 Pantalla de reportes con filtros
- [ ] T031 Gráficos (barras, líneas, torta)
- [ ] T032 Exportación a **PDF**
- [ ] T033 Exportación a **Excel**
- [ ] T034 Exportación a **CSV**
- [ ] T035 Reportes programados y envío por correo (opcional)

## Fase 5 — Seguridad y Cierre

- [ ] T040 Reglas de Firestore por rol y empresa
- [ ] T041 Restringir al Vendedor a sus propias ventas
- [ ] T042 Registrar auditoría de exportaciones (opcional)
- [ ] T043 Pruebas unitarias, de widget e integración
- [ ] T044 Ejecutar `flutter analyze`, `flutter test` y pruebas de Functions
- [ ] T045 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Reportes, panel y exportaciones verificados
- [ ] Commit y push realizados
