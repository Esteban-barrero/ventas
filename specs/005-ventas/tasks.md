# Tareas: Ventas

- **ID:** 005 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/ventas`
- [ ] T002 Definir entidades `Venta` e `ItemVenta`
- [ ] T003 Definir la lógica de cálculo de totales (`domain`)

## Fase 2 — Lógica de Negocio

- [ ] T010 Implementar `VentasRepository.registrar` (transacción)
- [ ] T011 Implementar consecutivo de factura por empresa
- [ ] T012 Implementar cálculo de totales (envío, descuentos, impuestos)
- [ ] T013 Implementar descuento de stock transaccional
- [ ] T014 Implementar tipos de entrega y regla de envío
- [ ] T015 Implementar medios de pago (efectivo, tarjeta, transferencia)
- [ ] T016 Implementar anulación con reverso de stock y caja
- [ ] T017 Integrar creación de crédito y plan de cobros (si aplica)

## Fase 3 — Interfaz de Usuario

- [ ] T020 Pantalla de nueva venta (productos + cantidades)
- [ ] T021 Selección de cliente y tipo (contado/crédito)
- [ ] T022 Selección de tipo de entrega
- [ ] T023 Selección de medio de pago
- [ ] T024 Previsualización e impresión de factura en PDF
- [ ] T025 Listado y detalle de ventas con filtros

## Fase 4 — Seguridad y Auditoría

- [ ] T030 Reglas de Firestore por rol y empresa
- [ ] T031 Registrar auditoría por venta y anulación

## Fase 5 — Pruebas y Cierre

- [ ] T040 Pruebas unitarias de totales y consecutivo
- [ ] T041 Pruebas de widget de la pantalla de venta
- [ ] T042 Prueba de integración de la transacción
- [ ] T043 Ejecutar `flutter analyze` y `flutter test`
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Transacción, consecutivo y auditoría verificados
- [ ] Commit y push realizados
