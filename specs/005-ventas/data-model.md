# Modelo de Datos: Ventas

- **ID:** 005 | **Fecha:** 2026-10-14

---

## `ventas/{ventaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador de la venta |
| empresaId | string | Empresa propietaria |
| numeroFactura | string | Consecutivo por empresa |
| fecha | timestamp | Fecha y hora |
| vendedorUid | string | Vendedor responsable |
| vendedorNombre | string | Nombre del vendedor |
| clienteId | string | Cliente (puede ser null: consumidor final) |
| clienteNombre | string | Nombre del cliente |
| clienteUid | string | UID del cliente (si tiene cuenta) |
| items | array | Ver abajo |
| tipoVenta | string | `contado` \| `credito` |
| tipoEntrega | string | `presencial` \| `entrega_local` \| `recoger_local` \| `envio` |
| medioPago | string | `efectivo` \| `tarjeta` \| `transferencia_nequi` \| `transferencia_bancolombia` |
| subtotal | number | Suma de ítems |
| costoEnvio | number | 0 si presencial/recoger |
| descuento | number | Descuento aplicado |
| impuestos | number | Impuestos (si aplican) |
| total | number | Total |
| empresaEnvio | string | Empresa de envío (si aplica) |
| fechaEnvio | timestamp | Fecha de envío (si aplica) |
| estadoEnvio | string | Estado del envío (si aplica) |
| estado | string | `registrada` \| `anulada` |
| motivoAnulacion | string | Motivo (si anulada) |
| creditoId | string | Crédito generado (si aplica) |

### `items[]` (array embebido)

| Campo | Tipo | Descripción |
|---|---|---|
| productoId | string | Producto |
| codigo | string | Código |
| nombre | string | Nombre |
| cantidad | number | Unidades |
| precioUnitario | number | Precio aplicado |
| subtotal | number | cantidad × precioUnitario |

---

## `consecutivos/{empresaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa |
| facturaActual | number | Último número de factura asignado |
| prefijo | string | Prefijo (ej: "FV-") |

---

## Ejemplo de venta

```json
{
  "empresaId": "empresa_001",
  "numeroFactura": "FV-000123",
  "fecha": "2026-10-14T15:30:00Z",
  "vendedorUid": "uid_vend_01",
  "clienteId": "cliente_001",
  "items": [
    { "productoId": "P001", "codigo": "PROD-001", "nombre": "Camiseta Polo",
      "cantidad": 2, "precioUnitario": 30000, "subtotal": 60000 }
  ],
  "tipoVenta": "contado",
  "tipoEntrega": "entrega_local",
  "medioPago": "transferencia_nequi",
  "subtotal": 60000,
  "costoEnvio": 5000,
  "descuento": 0,
  "total": 65000,
  "estado": "registrada"
}
```

---

## Efectos secundarios de una venta

1. **Stock:** `productos/{id}.stock -= cantidad` (transacción).
2. **Inventario:** `movimientos_inventario` tipo `salida`.
3. **Caja:** si contado → `movimientos_caja` entrada (según medio de pago).
4. **Crédito:** si crédito → `creditos` + plan de cobros.
5. **Auditoría:** registro del INSERT.

---

## Índices sugeridos

- `ventas`: `empresaId` + `fecha` (desc)
- `ventas`: `empresaId` + `vendedorUid` + `fecha`
- `ventas`: `empresaId` + `clienteId`
- `ventas`: `empresaId` + `numeroFactura` (único)
