# Tareas: Envíos y Entregas

- **ID:** 011 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/envios`
- [ ] T002 Definir entidades `Envio` y `EstadoEnvio`
- [ ] T003 Definir la máquina de estados y el cálculo del costo de envío

## Fase 2 — Lógica de Negocio

- [ ] T010 Implementar creación del envío desde venta o pedido
- [ ] T011 Implementar CRUD de transportadoras (`empresas_envio`)
- [ ] T012 Implementar asignación de repartidor
- [ ] T013 Implementar cambios de estado con historial y validación
- [ ] T014 Implementar cálculo/registro del costo de envío
- [ ] T015 Implementar evidencia de entrega (foto/firma)
- [ ] T016 Implementar flujo de pago contra entrega (integración con caja)
- [ ] T017 Implementar devolución con reingreso de stock (opcional)

## Fase 3 — Interfaz de Usuario

- [ ] T020 Listado de envíos con filtros por estado
- [ ] T021 Detalle del envío con historial de estados
- [ ] T022 Pantalla de despacho
- [ ] T023 Pantalla de captura de evidencia
- [ ] T024 Pantalla de rastreo para el cliente
- [ ] T025 Abrir ubicación en Google Maps / Waze

## Fase 4 — Notificaciones y Auditoría

- [ ] T030 Cloud Function de cambio de estado (notificar cliente)
- [ ] T031 Plantillas de mensaje por estado
- [ ] T032 Reglas de Firestore y Storage
- [ ] T033 Registrar auditoría en envíos y estados

## Fase 5 — Pruebas y Cierre

- [ ] T040 Pruebas unitarias de estados y costo de envío
- [ ] T041 Pruebas de widget de despacho y evidencia
- [ ] T042 Prueba de integración de entrega + contra entrega
- [ ] T043 Ejecutar `flutter analyze` y `flutter test`
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Estados, evidencia y contra entrega verificados
- [ ] Commit y push realizados
