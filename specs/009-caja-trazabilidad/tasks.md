# Tareas: Caja y Trazabilidad del dinero

- **ID:** 009 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/caja`
- [ ] T002 Definir entidades `Caja`, `MovimientoCaja` y `Arqueo`
- [ ] T003 Definir la lógica de saldo y diferencia (`domain`)

## Fase 2 — Lógica de Negocio

- [ ] T010 Implementar apertura de caja (validar no abierta)
- [ ] T011 Implementar registro de movimientos (transacción + saldo)
- [ ] T012 Implementar tipos de movimiento (ingreso, egreso, retiro, gasto)
- [ ] T013 Implementar medios de pago (efectivo, Nequi, Bancolombia, tarjeta)
- [ ] T014 Implementar cierre de caja (arqueo + diferencia)
- [ ] T015 Implementar bloqueo de caja cerrada
- [ ] T016 Implementar trazabilidad del dinero (responsable y estado)
- [ ] T017 Implementar flujo de pago contra entrega (en tránsito → entregado)
- [ ] T018 Integrar ingresos por ventas y cobros, egresos por compras

## Fase 3 — Interfaz de Usuario

- [ ] T020 Pantalla de apertura de caja
- [ ] T021 Panel de caja (saldo, movimientos, medios de pago)
- [ ] T022 Pantalla de registrar movimiento
- [ ] T023 Pantalla de cierre/arqueo
- [ ] T024 Pantalla de trazabilidad del dinero
- [ ] T025 Comprobante de cierre en PDF

## Fase 4 — Seguridad y Auditoría

- [ ] T030 Reglas de Firestore (movimientos inmutables)
- [ ] T031 Autorización de retiros/ajustes por monto
- [ ] T032 Registrar auditoría en caja y movimientos

## Fase 5 — Pruebas y Cierre

- [ ] T040 Pruebas unitarias de saldo y diferencia
- [ ] T041 Pruebas de widget del panel y del cierre
- [ ] T042 Prueba de integración venta → caja → arqueo
- [ ] T043 Ejecutar `flutter analyze` y `flutter test`
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Saldo, arqueo y trazabilidad verificados
- [ ] Commit y push realizados
