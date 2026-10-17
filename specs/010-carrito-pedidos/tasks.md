# Tareas: Carrito y Pedidos

- **ID:** 010 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14
- **Estado:** implementado el **MVP** (tienda del cliente → pedido → aprobación →
  venta/Entregas). Persistencia del carrito y notificaciones quedan pendientes.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/pedidos`
- [x] T002 Definir entidades `ItemPedido` y `Pedido`
- [x] T003 Definir totales y utilidad (`domain`)

## Fase 2 — Carrito

- [x] T010 Agregar/quitar/modificar cantidades del carrito
- [~] T011 Persistencia del carrito del cliente (Firestore): pendiente; hoy en
  memoria durante la sesión.
- [~] T012 Persistencia del carrito del invitado (local): pendiente.
- [x] T013 Cálculo de subtotales, impuestos y total
- [x] T014 Revalidar stock al aprobar (la venta lo valida en transacción)

## Fase 3 — Pedidos

- [x] T020 Creación del pedido desde el carrito (número consecutivo `PED-`)
- [x] T021 Captura de datos del cliente (nombre, cédula, teléfono, dirección)
- [x] T022 Estados del pedido (pendiente → confirmado; cancelado)
- [x] T023 Historial de pedidos del cliente ("Mis pedidos")
- [x] T024 Conversión de pedido a venta (`VentasRepository`, spec 005) y paso
  automático a **Entregas** (spec 011)

## Fase 4 — Notificaciones

- [ ] T030 Cloud Function al crear pedido (notificar negocio)
- [~] T031 Integración WhatsApp: aviso por **wa.me** desde la app (con el número
  configurado en la empresa). El envío automático requiere Cloud Function.
- [ ] T032 Integración Telegram (pendiente)
- [~] T033 Plantilla de mensaje del pedido (resumen simple)
- [ ] T034 Notificación de cambio de estado al cliente (opcional)

## Fase 5 — Interfaz, Seguridad y Cierre

- [x] T040 Pantallas de tienda, carrito y checkout
- [x] T041 Pantalla de mis pedidos y detalle; lista de pedidos de la empresa
- [x] T042 Reglas de Firestore (`pedidos`, `consecutivos_pedidos`)
- [x] T043 Auditoría de pedidos
- [x] T044 Pruebas unitarias del dominio
- [x] T045 Ejecutar `flutter analyze` y `flutter test`
- [x] T046 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [x] Criterios del MVP cubiertos
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando
- [x] Conversión a venta verificada
- [x] Commit y push realizados
