# Tareas: Inventario

- **ID:** 008 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/inventario`
- [ ] T002 Definir entidades `MovimientoInventario` y `ConteoInventario`
- [ ] T003 Definir la lógica de cálculo de stock y valorización (`domain`)

## Fase 2 — Lógica de Negocio

- [ ] T010 Implementar consulta de stock y kardex por producto
- [ ] T011 Implementar entrada automática desde compras (spec 007)
- [ ] T012 Implementar salida automática desde ventas (spec 005)
- [ ] T013 Implementar ajuste manual (positivo/negativo) con motivo
- [ ] T014 Implementar regla de no stock negativo
- [ ] T015 Implementar reversos por anulación (compra/venta)
- [ ] T016 Implementar valorización del inventario
- [ ] T017 Implementar alertas de stock mínimo y agotado

## Fase 3 — Conteo Físico

- [ ] T020 Implementar registro de conteo físico
- [ ] T021 Implementar cálculo de diferencias y generación de ajustes
- [ ] T022 Implementar cierre de conteo con aprobación

## Fase 4 — Interfaz de Usuario

- [ ] T030 Listado de inventario con filtros (bajo stock, agotado)
- [ ] T031 Pantalla de kardex de un producto
- [ ] T032 Pantalla de ajuste de inventario
- [ ] T033 Pantalla de conteo físico
- [ ] T034 Indicadores/alertas en el panel principal

## Fase 5 — Seguridad y Cierre

- [ ] T040 Reglas de Firestore (kardex inmutable)
- [ ] T041 Registrar auditoría en ajustes y conteos
- [ ] T042 Pruebas unitarias, de widget e integración
- [ ] T043 Ejecutar `flutter analyze` y `flutter test`
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Kardex, ajustes y valorización verificados
- [ ] Commit y push realizados
