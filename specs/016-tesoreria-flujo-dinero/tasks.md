# Tareas: Tesorería y flujo del dinero

- **ID:** 016 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-16

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de `features/tesoreria`
- [x] T002 Definir `MovimientoDinero`, `UbicacionDinero` y tipos
- [x] T003 Definir el cálculo de posiciones por ubicación (`domain/posiciones.dart`)

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar registro de movimientos (ingreso/egreso)
- [x] T011 Implementar **traslados** entre ubicaciones
- [x] T012 Implementar la posición total y por ubicación/responsable
- [x] T013 Integrar **ventas de contado** (ubicación según medio/entrega)
- [x] T014 Integrar **cobros** de crédito
- [x] T015 Unificar la **caja por turno** (009) en el mismo libro
- [x] T016 Snapshot de **costo, utilidad y margen** en ventas

## Fase 3 — Interfaz de Usuario

- [x] T020 Pantalla de Tesorería (total + desglose)
- [x] T021 Lista de movimientos
- [x] T022 Diálogo de movimiento (ingreso/egreso/gasto/retiro)
- [x] T023 Diálogo de traslado
- [x] T024 Módulo en el home

## Fase 4 — Seguridad y Auditoría

- [x] T030 Reglas de Firestore (inmutable)
- [x] T031 Auditoría de movimientos y traslados

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de posiciones y traslados
- [x] T041 Pruebas de serialización
- [x] T042 Ejecutar `flutter analyze` y `flutter test`
- [x] T043 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [x] Criterios de aceptación de `spec.md` cumplidos
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando
- [x] Total, ubicaciones y trazabilidad verificados
- [x] Commit y push realizados

---

## Pendientes / fuera de alcance (documentados)

- **Traslados y turnos:** un traslado a/desde `caja_fisica` no ajusta el `saldo`
  del turno si no se indica `cajaId` (los movimientos del turno se asocian por
  `cajaId`).
- **Pago a proveedor:** el egreso por compra queda pendiente hasta que exista el
  flujo de pago (spec 007).
- **Envíos (011):** concreta el paso `contra_entrega → entregado`.
- **Conciliación bancaria** y **comprobantes en PDF**: pendientes.
