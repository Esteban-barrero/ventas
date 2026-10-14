# Guía Rápida: Carrito y Pedidos

- **ID:** 010 | **Fecha:** 2026-10-14

---

## Cliente registrado

1. Navega el **catálogo**.
2. Agregar productos al **carrito**.
3. El carrito se **guarda en la nube** (sigue ahí al volver).
4. **Realizar pedido** → confirmar.
5. Ver estado en **Mis pedidos**.

## Invitado (sin cuenta)

1. Navega el **catálogo** (solo catálogo, carrito y pedido).
2. Agregar productos al **carrito** (guardado local).
3. **Realizar pedido** → completar datos:
   - **Nombre completo** (obligatorio)
   - **Cédula** (obligatoria)
   - **Teléfono** (obligatorio)
   - **Dirección** (departamento, ciudad, dirección, barrio)
4. Confirmar. El negocio recibe la **notificación**.

## Notificación al negocio

| Canal | Cómo |
|---|---|
| **WhatsApp** | Enlace `wa.me` y/o proveedor de API |
| **Telegram** | Bot API (`sendMessage`) al chat configurado |

La empresa elige los canales en **Parámetros**.

## Estados del pedido

```
pendiente ─► confirmado ─► en_preparacion ─► listo ─► entregado
     │            │               │
     └────────────┴───────────────┴──► cancelado
```

| Estado | Significado |
|---|---|
| `pendiente` | Recibido, sin confirmar |
| `confirmado` | Aceptado por el negocio |
| `en_preparacion` | Alistando la mercancía |
| `listo` | Disponible para entregar |
| `entregado` | Recibido por el cliente |
| `cancelado` | Anulado |

## Convertir pedido en venta

1. Abrir el pedido (rol interno).
2. Clic en **Convertir en venta**.
3. El sistema revalida **stock** y **precio**.
4. Se registra la **venta** (descuenta stock y alimenta la caja/crédito).

## Reglas clave

- El pedido **bloquea el precio** al crearse.
- El **stock** se descuenta al convertirse en **venta**, no antes.
- El **invitado** nunca ve costos ni información interna.

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/pedidos-contracts.md`](./contracts/pedidos-contracts.md)
