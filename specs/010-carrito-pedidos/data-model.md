# Modelo de Datos: Carrito y Pedidos

- **ID:** 010 | **Fecha:** 2026-10-14

---

## `carritos/{carritoId}` (cliente registrado)

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del carrito |
| empresaId | string | Empresa |
| clienteUid | string | Cliente dueño |
| items | array | Ver abajo |
| subtotal | number | Suma de ítems |
| total | number | Total |
| fechaActualizacion | timestamp | Última modificación |

### `items[]` (array embebido)

| Campo | Tipo | Descripción |
|---|---|---|
| productoId | string | Producto |
| codigo | string | Código |
| nombre | string | Nombre |
| cantidad | number | Unidades |
| precioUnitario | number | Precio congelado al agregar |
| subtotal | number | cantidad × precioUnitario |

> El carrito del **invitado** tiene la misma estructura, pero vive en `shared_preferences`.

---

## `pedidos/{pedidoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del pedido |
| empresaId | string | Empresa propietaria |
| numero | string | Número consecutivo del pedido |
| origen | string | `cliente` \| `invitado` |
| clienteUid | string | UID del cliente (null si invitado) |
| clienteId | string | ID del cliente (si registrado) |
| invitadoNombre | string | Nombre completo (invitado) |
| invitadoCedula | string | Cédula (invitado) |
| invitadoTelefono | string | Teléfono (invitado) |
| direccion | map | departamento, ciudad, direccion, barrio |
| items | array | Igual que el carrito (precio congelado) |
| subtotal | number | Suma de ítems |
| costoEnvio | number | Costo de envío (si aplica) |
| total | number | Total |
| tipoEntrega | string | `presencial` \| `entrega_local` \| `recoger_local` \| `envio` |
| observaciones | string | Notas del cliente |
| estado | string | `pendiente` \| `confirmado` \| `en_preparacion` \| `listo` \| `entregado` \| `cancelado` |
| canalNotificado | string | `whatsapp` \| `telegram` \| `ambos` \| `ninguno` |
| notificado | boolean | Si ya se avisó al negocio |
| ventaId | string | Venta generada (si se convirtió) |
| motivoCancelacion | string | Motivo (si cancelado) |
| fechaCreacion | timestamp | Fecha del pedido |
| fechaActualizacion | timestamp | Última actualización |

---

## Ejemplo de pedido (invitado)

```json
{
  "empresaId": "empresa_001",
  "numero": "PED-000012",
  "origen": "invitado",
  "clienteUid": null,
  "invitadoNombre": "Maria Lopez",
  "invitadoCedula": "1020304050",
  "invitadoTelefono": "3001234567",
  "direccion": {
    "departamento": "Cundinamarca",
    "ciudad": "Bogota",
    "direccion": "Calle 123 #45-67",
    "barrio": "Chapinero"
  },
  "items": [
    { "productoId": "P001", "codigo": "PROD-001", "nombre": "Camiseta Polo",
      "cantidad": 2, "precioUnitario": 30000, "subtotal": 60000 }
  ],
  "subtotal": 60000,
  "costoEnvio": 5000,
  "total": 65000,
  "tipoEntrega": "envio",
  "estado": "pendiente",
  "canalNotificado": "ambos",
  "notificado": true
}
```

---

## Flujo de estados

```
pendiente ─► confirmado ─► en_preparacion ─► listo ─► entregado
     │            │               │
     └────────────┴───────────────┴──► cancelado
```

Al pasar a `entregado` (o antes, según la empresa) se puede **convertir en venta**.

---

## Efectos

1. **Crear pedido:** escribe `pedidos`, dispara la **notificación**.
2. **Convertir a venta:** llama a `VentasRepository.registrar` (descuenta stock y caja).
3. **Cancelar:** marca `cancelado` y libera la reserva (no había afectado stock).
4. **Auditoría** en cada cambio de estado.

---

## Índices sugeridos

- `pedidos`: `empresaId` + `fechaCreacion` (desc)
- `pedidos`: `empresaId` + `estado`
- `pedidos`: `clienteUid` + `fechaCreacion` (desc)
- `carritos`: `empresaId` + `clienteUid`
