# Especificación: Carrito y Pedidos

- **ID:** 010 | **Carpeta:** `specs/010-carrito-pedidos/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Permite a **clientes registrados** e **invitados** armar un **carrito** con productos del catálogo
y **realizar un pedido**. El invitado solo puede ver el catálogo, usar el carrito y pedir (se le
solicitan **nombre, cédula, teléfono y dirección**). Cada pedido notifica al negocio por
**WhatsApp / Telegram** y avanza por un flujo de **estados** hasta convertirse en venta.

## 2. Objetivo

- Permitir comprar sin fricción a clientes e **invitados**.
- Persistir el carrito entre sesiones.
- Recibir pedidos y notificarlos al negocio al instante.
- Dar seguimiento al estado del pedido (para el cliente y el negocio).

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Cliente** | Arma carrito, hace pedidos, ve su historial. |
| **Invitado** | Catálogo + carrito + pedido (sin cuenta). |
| **Vendedor / Administrador** | Recibe, confirma y gestiona pedidos. |
| **Gerente** | Supervisa pedidos y conversión a ventas. |

## 4. Historias de Usuario

- **Como** Cliente, **quiero** agregar productos al carrito **para** comprarlos luego.
- **Como** Invitado, **quiero** pedir sin registrarme **para** comprar rápido.
- **Como** Invitado, **quiero** que me pidan mis datos **para** que me contacten.
- **Como** Administrador, **quiero** recibir el pedido por WhatsApp/Telegram **para** atenderlo ya.
- **Como** Cliente, **quiero** ver el estado de mi pedido **para** saber cuándo llega.

## 5. Requisitos Funcionales

- RF-01 **Carrito:** agregar, quitar y modificar cantidades de productos.
- RF-02 **Persistencia del carrito:**
  - Cliente registrado → sincronizado en la nube.
  - Invitado → guardado localmente.
- RF-03 Cálculo de **subtotales y total** del carrito.
- RF-04 **Realizar pedido** desde el carrito.
- RF-05 **Invitado:** solicitar **nombre completo, cédula, teléfono y dirección** (departamento, ciudad, dirección, barrio).
- RF-06 **Notificación** al negocio por **WhatsApp / Telegram** (configurable).
- RF-07 **Estados del pedido:** pendiente, confirmado, en_preparacion, listo, entregado, cancelado.
- RF-08 **Historial de pedidos** del cliente.
- RF-09 Convertir un pedido en **venta** (spec 005).
- RF-10 Observaciones/notas del pedido.
- RF-11 Tipos de entrega del pedido: presencial, entrega local, recoger en local, envío.
- RF-12 Registro de auditoría.

## 6. Reglas de Negocio

- RN-01 Todo pedido pertenece a una empresa (`empresaId`).
- RN-02 Un **invitado** no puede ver precios de costo ni información interna.
- RN-03 El pedido **no descuenta stock** hasta confirmarse (o convertirse en venta).
- RN-04 El pedido **bloquea el precio** del producto al momento de crearlo.
- RN-05 El carrito de un invitado se identifica por un `carritoId` local.
- RN-06 Un pedido **cancelado** no se convierte en venta.
- RN-07 La conversión pedido → venta respeta las reglas de la spec 005.
- RN-08 Se notifica al negocio en cada pedido nuevo (según canales activos).

## 7. Criterios de Aceptación

- [ ] CA-01 Se agregan y quitan productos del carrito.
- [ ] CA-02 El carrito del cliente se conserva entre sesiones.
- [ ] CA-03 El invitado puede pedir completando sus datos obligatorios.
- [ ] CA-04 El negocio recibe la notificación por WhatsApp/Telegram.
- [ ] CA-05 El pedido cambia de estado correctamente.
- [ ] CA-06 El cliente ve su historial y el estado del pedido.
- [ ] CA-07 Un pedido puede convertirse en venta.
- [ ] CA-08 Todo cambio de estado queda auditado.

## 8. Datos Involucrados

- `carritos` (cliente o invitado)
- `pedidos` (datos, ítems, estado, origen)
- `productos` (catálogo)
- `clientes`
- `_auditoria`

## 9. Casos Borde / Errores

- Producto agotado entre el carrito y el pedido.
- Precio cambiado entre el carrito y el pedido.
- Invitado sin dirección o teléfono.
- Fallo de la notificación (reintento / aviso en la app).
- Pedido duplicado por doble toque.
- Carrito local perdido al limpiar datos.

## 10. Fuera de Alcance

- Pasarela de pago en línea (no hay por ahora).
- Seguimiento GPS del repartidor en tiempo real.
- Cupones / promociones (se evalúa después).

## 11. Dependencias

- 003 Catálogo (productos y precios).
- 004 Clientes (cliente registrado).
- 005 Ventas (conversión a venta).
- 008 Inventario (validación de stock).
- 011 Envíos y Entregas.
- 014 Parámetros (canales de notificación, teléfonos, tokens).
