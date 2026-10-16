# Tareas: Envíos y Entregas

- **ID:** 011 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14
- **Estado:** implementado el **MVP "Pendientes por entregar"** (rol
  `domiciliario`); transportadoras, guías, evidencia y notificaciones quedan
  pendientes.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/envios`
- [x] T002 Definir `EstadoEnvio` (estado en la venta: `estadoEnvio`)
- [~] T003 Máquina de estados y costo de envío (costo ya existe en catálogo/005)

## Fase 2 — Lógica de Negocio

- [x] T010 Tomar las ventas con entrega pendiente como origen del listado
- [ ] T011 CRUD de transportadoras (`empresas_envio`) (pendiente)
- [x] T012 Asignación de repartidor (`repartidorUid`/`repartidorNombre`)
- [x] T013 Cambios de estado (`pendiente`/`en_reparto`/`entregado`/`novedad`)
- [ ] T014 Registro del costo de envío (ya en la venta, spec 005)
- [ ] T015 Evidencia de entrega (foto/firma) (pendiente)
- [x] T016 Pago contra entrega → tesorería (spec 016) y **rendición** a caja
- [ ] T017 Devolución con reingreso de stock (pendiente)

## Fase 3 — Interfaz de Usuario

- [x] T020 Listado de **pendientes por entregar** con filtros (estado, ciudad)
- [x] T021 Detalle del pedido con datos del cliente y dirección
- [ ] T022 Pantalla de despacho dedicada (equivale al filtro de estado)
- [ ] T023 Captura de evidencia (pendiente)
- [ ] T024 Rastreo para el cliente (pendiente)
- [x] T025 Abrir ubicación en Google Maps / Waze

## Fase 4 — Notificaciones y Auditoría

- [ ] T030 Cloud Function de cambio de estado (pendiente)
- [ ] T031 Plantillas de mensaje por estado (pendiente)
- [x] T032 Reglas de Firestore (domiciliario actualiza solo campos de entrega)
- [x] T033 Auditar cambios de estado de entrega

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de estados y `entregaPendiente`
- [ ] T041 Pruebas de widget de despacho y evidencia (pendiente)
- [~] T042 Integración entrega + contra entrega (hecha por flujo)
- [x] T043 Ejecutar `flutter analyze` y `flutter test`
- [x] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [x] Criterios de aceptación cubiertos por el MVP
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando
- [x] Estados y contra entrega verificados
- [x] Commit y push realizados
