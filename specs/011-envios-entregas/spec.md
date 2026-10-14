# Especificación: Envíos y Entregas

- **ID:** 011 | **Carpeta:** `specs/011-envios-entregas/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Gestiona la **entrega** de cada venta o pedido según su tipo: **presencial**, **entrega local**,
**recoger en local** o **envío**. Para los envíos controla la **transportadora**, la **guía**, el
**repartidor**, las **fechas**, el **estado** y la **evidencia de entrega**, además del
**pago contra entrega** (cuya trazabilidad del dinero vive en la spec 009).

## 2. Objetivo

- Saber **cómo** y **cuándo** se entrega cada venta/pedido.
- Rastrear el envío: transportadora, guía, estado y repartidor.
- Confirmar la entrega con **evidencia** (foto/firma).
- Controlar el **pago contra entrega**.
- Avisar al cliente de cada cambio de estado.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Administrador** | Configura transportadoras; gestiona envíos. |
| **Vendedor** | Crea el envío y despacha. |
| **Repartidor / Domiciliario** | Marca en reparto y entrega con evidencia. |
| **Cajero** | Recibe el dinero del contra entrega. |
| **Cliente** | Consulta el estado de su envío. |

## 4. Historias de Usuario

- **Como** Vendedor, **quiero** registrar un envío con transportadora y guía **para** rastrearlo.
- **Como** Administrador, **quiero** que el envío tenga estados **para** saber dónde va.
- **Como** Repartidor, **quiero** marcar la entrega con una **foto** **para** dejar constancia.
- **Como** Cajero, **quiero** saber cuándo entra el dinero del **contra entrega**.
- **Como** Cliente, **quiero** que me avisen del estado **para** estar pendiente.

## 5. Requisitos Funcionales

- RF-01 Definir el **tipo de entrega**: presencial, entrega local, recoger en local, envío.
- RF-02 Para **envío**: transportadora, número de **guía**, fecha de despacho y fecha estimada.
- RF-03 **Repartidor / domiciliario** asignado.
- RF-04 **Estados del envío:** preparando, despachado, en_transito, en_reparto, entregado, devuelto, novedad.
- RF-05 **Costo de envío** (por artículo o general, según catálogo).
- RF-06 **Dirección de entrega** (departamento, ciudad, dirección, barrio).
- RF-07 **Evidencia de entrega:** foto y/o firma.
- RF-08 **Pago contra entrega:** monto, responsable y estado del dinero (spec 009).
- RF-09 **Trazabilidad:** quién despachó y quién entregó, con fecha y hora.
- RF-10 **Notificación** al cliente en cada cambio de estado (WhatsApp/Telegram).
- RF-11 Ubicación GPS opcional del punto de entrega (abrir en Google Maps/Waze).
- RF-12 Registro de auditoría.

## 6. Reglas de Negocio

- RN-01 El **envío** aplica solo a ventas/pedidos con tipo de entrega `envio` o `entrega_local`.
- RN-02 Presencial y **recoger en local** **no** tienen costo de envío ni transportadora.
- RN-03 Cada envío pertenece a una empresa (`empresaId`).
- RN-04 El pago contra entrega deja el dinero **en tránsito** hasta que se entrega (spec 009).
- RN-05 Una entrega **devuelta** puede reingresar el stock (según política configurable).
- RN-06 La entrega se marca como **entregado** solo con evidencia (si así está configurado).
- RN-07 El estado del envío avanza en orden; los retrocesos requieren permiso.
- RN-08 El cliente solo puede **ver**, no modificar, el estado del envío.

## 7. Criterios de Aceptación

- [ ] CA-01 Se registra un envío con transportadora y guía.
- [ ] CA-02 El envío cambia de estado correctamente.
- [ ] CA-03 Se adjunta la evidencia de entrega (foto/firma).
- [ ] CA-04 Se registra quién despachó y quién entregó.
- [ ] CA-05 El pago contra entrega se refleja en la caja al entregarse.
- [ ] CA-06 El cliente recibe la notificación del cambio de estado.
- [ ] CA-07 Presencial y recoger en local no generan envío.
- [ ] CA-08 Todo cambio queda auditado.

## 8. Datos Involucrados

- `envios` (datos, guía, estado, evidencia)
- `empresas_envio` (transportadoras)
- `ventas` / `pedidos` (origen)
- `movimientos_caja` (pago contra entrega)
- Firebase Storage: evidencias de entrega
- `_auditoria`

## 9. Casos Borde / Errores

- Envío sin transportadora ni guía.
- Entrega devuelta / dirección errónea.
- Cliente no está al momento de la entrega.
- Contra entrega no pagado por el cliente.
- Evidencia perdida o no subida.
- Cambio de estado fuera de orden.

## 10. Fuera de Alcance

- Integración automática con API de transportadoras (se evalúa después).
- Seguimiento GPS en tiempo real del repartidor.
- Optimización de rutas.

## 11. Dependencias

- 005 Ventas (origen del envío).
- 010 Carrito y Pedidos (origen del envío).
- 009 Caja (contra entrega, estado del dinero).
- 008 Inventario (reingreso por devolución).
- 014 Parámetros (transportadoras por defecto, canales de notificación).
