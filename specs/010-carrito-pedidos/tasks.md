# Tareas: Carrito y Pedidos

- **ID:** 010 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/pedidos`
- [ ] T002 Definir entidades `Carrito`, `ItemCarrito` y `Pedido`
- [ ] T003 Definir la lógica de totales y conversión a venta (`domain`)

## Fase 2 — Carrito

- [ ] T010 Implementar agregar/quitar/modificar del carrito
- [ ] T011 Implementar persistencia del carrito del cliente (Firestore)
- [ ] T012 Implementar persistencia del carrito del invitado (local)
- [ ] T013 Implementar cálculo de subtotales y total
- [ ] T014 Revalidar stock y precio al confirmar

## Fase 3 — Pedidos

- [ ] T020 Implementar creación del pedido desde el carrito
- [ ] T021 Implementar captura de datos del invitado (nombre, cédula, teléfono, dirección)
- [ ] T022 Implementar estados del pedido y sus transiciones
- [ ] T023 Implementar historial de pedidos del cliente
- [ ] T024 Implementar conversión de pedido a venta (spec 005)

## Fase 4 — Notificaciones

- [ ] T030 Cloud Function al crear pedido (notificar negocio)
- [ ] T031 Integración WhatsApp (enlace y/o proveedor)
- [ ] T032 Integración Telegram (Bot API)
- [ ] T033 Plantilla de mensaje del pedido
- [ ] T034 Notificación de cambio de estado al cliente (opcional)

## Fase 5 — Interfaz, Seguridad y Cierre

- [ ] T040 Pantallas de carrito, checkout y confirmación
- [ ] T041 Pantalla de mis pedidos y detalle
- [ ] T042 Reglas de Firestore (invitado restringido)
- [ ] T043 Registrar auditoría de pedidos
- [ ] T044 Pruebas unitarias, de widget e integración
- [ ] T045 Ejecutar `flutter analyze` y `flutter test`
- [ ] T046 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Notificación por WhatsApp/Telegram verificada
- [ ] Conversión a venta verificada
- [ ] Commit y push realizados
