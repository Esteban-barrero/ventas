# Tareas: Caja y Trazabilidad del dinero

- **ID:** 009 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/caja`
- [x] T002 Definir entidades `Caja`, `MovimientoCaja` y `Arqueo`
- [x] T003 Definir la lógica de saldo y diferencia (`domain/calculos_caja.dart`)

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar apertura de caja (validar no abierta)
- [x] T011 Implementar registro de movimientos (transacción + saldo)
- [x] T012 Implementar tipos de movimiento (ingreso, egreso, retiro, gasto)
- [x] T013 Implementar medios de pago (efectivo, Nequi, Bancolombia, tarjeta)
- [x] T014 Implementar cierre de caja (arqueo + diferencia)
- [x] T015 Implementar bloqueo de caja cerrada
- [x] T016 Implementar trazabilidad del dinero (responsable y estado)
- [~] T017 Flujo de pago contra entrega (`en_transito` → `entregado`): modelo
  listo; el flujo completo se cierra en la spec 011 (Envíos/domicilios).
- [~] T018 Integración: **ventas de contado** y **cobros de crédito** ingresan a
  caja (best-effort: solo si el usuario tiene caja abierta, sin bloquear la
  operación). Egreso por **compras** queda pendiente hasta que exista el "pago a
  proveedor" (spec 007 lo deja como cuenta por pagar).

## Fase 3 — Interfaz de Usuario

- [x] T020 Pantalla de apertura de caja
- [x] T021 Panel de caja (saldo, movimientos, medios de pago)
- [x] T022 Pantalla de registrar movimiento
- [x] T023 Pantalla de cierre/arqueo
- [x] T024 Pantalla de trazabilidad del dinero
- [ ] T025 Comprobante de cierre en PDF (pendiente)

## Fase 4 — Seguridad y Auditoría

- [x] T030 Reglas de Firestore (movimientos inmutables)
- [ ] T031 Autorización de retiros/ajustes por monto (pendiente)
- [x] T032 Registrar auditoría en caja y movimientos

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de saldo y diferencia (`test/caja_test.dart`)
- [ ] T041 Pruebas de widget del panel y del cierre (pendiente)
- [~] T042 Integración venta → caja → arqueo: hecha por flujo (no automática).
- [x] T043 Ejecutar `flutter analyze` y `flutter test`
- [x] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Saldo, arqueo y trazabilidad verificados
- [ ] Commit y push realizados
