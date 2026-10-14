# Tareas: Créditos y Cobros

- **ID:** 006 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/creditos`
- [ ] T002 Definir entidades `Credito` y `Cuota`
- [ ] T003 Definir la lógica de generación de cuotas (`domain`)

## Fase 2 — Lógica de Negocio

- [ ] T010 Implementar creación del crédito desde una venta a crédito
- [ ] T011 Implementar generación del plan de cuotas (semanal/quincenal/mensual)
- [ ] T012 Implementar cálculo de interés (si aplica) y ajuste de redondeo
- [ ] T013 Implementar aprobación del crédito
- [ ] T014 Implementar registro de pagos y abonos parciales (transacción)
- [ ] T015 Implementar cálculo de saldo y días de mora
- [ ] T016 Implementar cambio de estados y marcado de cliente moroso
- [ ] T017 Integrar movimiento de caja por cada pago

## Fase 3 — Interfaz de Usuario

- [ ] T020 Listado de créditos con filtros (activos, vencidos, por cliente)
- [ ] T021 Detalle del crédito con cuotas y saldo
- [ ] T022 Pantalla de registrar pago
- [ ] T023 Vista del cliente: sus cuotas y saldo
- [ ] T024 Exportación de cartera (PDF/Excel)

## Fase 4 — Cloud Functions y Auditoría

- [ ] T030 Cloud Function programada `actualizarMoraYNotificar`
- [ ] T031 Notificaciones de cuota por vencer/vencida (correo e in-app)
- [ ] T032 Reglas de Firestore por rol y empresa
- [ ] T033 Registrar auditoría en créditos y pagos

## Fase 5 — Pruebas y Cierre

- [ ] T040 Pruebas unitarias de cuotas y mora
- [ ] T041 Pruebas de widget del detalle y del pago
- [ ] T042 Prueba de integración de pago (cuota + caja)
- [ ] T043 Ejecutar `flutter analyze` y `flutter test`
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Transacción de pago y mora verificadas
- [ ] Commit y push realizados
