# Investigación y Decisiones: Carrito y Pedidos

- **ID:** 010 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se requiere carrito y pedidos para clientes registrados e invitados, con notificación al negocio
por WhatsApp/Telegram y seguimiento por estados.

## 2. Opciones Evaluadas

### 2.1. Persistencia del carrito

| Opción | Ventajas | Desventajas |
|---|---|---|
| Siempre en Firestore | Sincroniza | El invitado no tiene cuenta |
| Siempre local | Sin cuenta | Se pierde al limpiar datos |
| **Firestore (cliente) + local (invitado)** | Lo mejor de ambos | Dos rutas de código |

**Decisión:** **Firestore** para el cliente registrado y **almacenamiento local** para el invitado.

### 2.2. Notificación al negocio

| Opción | Ventajas | Desventajas |
|---|---|---|
| Solo dentro de la app | Sin terceros | No avisa al instante |
| **WhatsApp (enlace / API)** | Lo que usa la gente | Requiere número / proveedor |
| **Telegram (Bot API)** | Fácil de integrar | Requiere bot y chatId |

**Decisión:** **WhatsApp y Telegram**, ambos configurables por empresa; el mensaje se arma en una
Cloud Function al crear el pedido.

### 2.3. ¿Cuándo descontar el stock?

| Opción | Ventajas | Desventajas |
|---|---|---|
| Al crear el pedido | Reserva existencias | Puede bloquear sin pago |
| **Al convertir en venta** | Consistente con la venta | Riesgo de sobreventa |

**Decisión:** **Al convertir en venta**; se revalida stock al confirmar y se avisa si cambió.

### 2.4. Precio del pedido

**Decisión:** el pedido **bloquea el precio** al momento de crearlo; si el precio cambió, se
advierte antes de convertir a venta.

### 2.5. Estados del pedido

**Decisión:** `pendiente → confirmado → en_preparacion → listo → entregado`, con `cancelado` como
salida en cualquier punto previo a la entrega.

## 3. Preguntas Abiertas

- ¿Cupones y promociones? (después)
- ¿Pago en línea? (no por ahora)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11 Pedidos y Carrito, 12 Invitado.
- Telegram Bot API — `sendMessage`.
- WhatsApp — `https://wa.me/<numero>`.
