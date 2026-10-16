# Tareas: Créditos y Cobros

- **ID:** 006 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14 | **Actualizado:** 2026-10-16
- **Estado:** Implementado (núcleo). Ver notas al final.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/creditos`
- [x] T002 Definir entidades `Credito` y `Cuota`
- [x] T003 Definir la lógica de generación de cuotas (`domain`)

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar creación del crédito desde una venta a crédito
- [x] T011 Implementar generación del plan de cuotas (semanal/quincenal/mensual)
- [x] T012 Implementar cálculo de interés (si aplica) y ajuste de redondeo
- [x] T013 Implementar aprobación del crédito
- [x] T014 Implementar registro de pagos y abonos parciales (transacción)
- [x] T015 Implementar cálculo de saldo y días de mora
- [ ] T016 Marcado automático de cliente moroso *(hoy es manual desde el cliente;
      el automático lo hace la Cloud Function programada)*
- [ ] T017 Integrar movimiento de caja por cada pago *(depende de la spec 009)*

## Fase 3 — Interfaz de Usuario

- [x] T020 Listado de créditos (cartera) con filtros
- [x] T021 Detalle del crédito con cuotas y saldo
- [x] T022 Registrar pago (diálogo con monto y medio de pago)
- [ ] T023 Vista del cliente: sus cuotas y saldo *(las reglas ya permiten al
      cliente leer su crédito; falta una pantalla dedicada del rol Cliente)*
- [ ] T024 Exportación de cartera (PDF/Excel)

## Fase 4 — Cloud Functions y Auditoría

- [ ] T030 Cloud Function programada `actualizarMoraYNotificar`
- [ ] T031 Notificaciones de cuota por vencer/vencida (correo e in-app)
- [x] T032 Reglas de Firestore por rol y empresa
- [x] T033 Registrar auditoría en créditos y pagos

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de cuotas y mora
- [ ] T041 Pruebas de widget del detalle y del pago *(se cubrió el listado)*
- [ ] T042 Prueba de integración de pago (cuota + caja) *(requiere emulador)*
- [x] T043 Ejecutar `flutter analyze` y `flutter test` (172 pruebas)
- [x] T044 Actualizar documentación

---

## Decisiones tomadas al implementar

- **Stack:** patrón existente (StatefulWidget + repositorios); **no** Riverpod ni
  `intl`.
- **Crédito desde la venta:** la pantalla de **Nueva venta** captura el plan
  (cuotas, periodicidad, interés, primer pago) y, tras registrar, la app crea el
  crédito (`crearDesdeVenta`). Esto cierra el **CA-09 de la spec 005**.
- **Cuotas:** subcolección `creditos/{id}/cuotas` con ids deterministas
  (`c001`, `c002`, …) para leerlas dentro de la transacción de pago.
- **Caja:** el movimiento de caja por pago se integra con la **spec 009**.
- **Mora:** se calcula en lectura para mostrar; el recálculo persistido, el
  marcado automático de moroso y las notificaciones van con la Cloud Function
  programada.

## Pendiente (no bloqueante)

- Cloud Function `actualizarMoraYNotificar` + notificaciones (T030/T031).
- Movimiento de caja por pago (spec 009) y exportación de cartera (PDF/Excel).

---

## Criterio de Terminado (Definition of Done)

- [x] Criterios de aceptación cumplidos **salvo** CA-07 (marcado automático de
      moroso) y CA-08 (caja), que dependen de la Function y de la spec 009
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando (172)
- [x] Transacción de pago y cálculo de mora verificados
- [x] Código documentado: cada método y clase comentado en español (Principio 11)
- [ ] Commit y push realizados *(al cierre de esta spec)*
