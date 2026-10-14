# Modelo de Datos: Proveedores y Compras

- **ID:** 007 | **Fecha:** 2026-10-14

---

## `proveedores/{proveedorId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del proveedor |
| empresaId | string | Empresa propietaria |
| nombre | string | Nombre / razón social |
| nit | string | NIT / RIF (único por empresa) |
| direccion | string | Dirección |
| telefono | string | Teléfono |
| correo | string | Correo |
| contacto | string | Persona de contacto |
| activo | boolean | Si está activo |
| fechaCreacion | timestamp | Fecha de creación |

---

## `compras/{compraId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador de la compra |
| empresaId | string | Empresa propietaria |
| numeroOrden | string | Número de orden |
| fecha | timestamp | Fecha de la compra |
| proveedorId | string | Proveedor |
| proveedorNombre | string | Nombre del proveedor |
| items | array | Ver abajo |
| valorTotal | number | Valor total |
| formaPago | string | `contado` \| `credito` \| `transferencia` |
| estado | string | `pendiente` \| `pagada` \| `anulada` |
| actualizaCosto | boolean | Si actualiza el costo de los productos |
| observaciones | string | Notas |
| motivoAnulacion | string | Si fue anulada |
| fechaCreacion | timestamp | Fecha de registro |

### `items[]` (array embebido)

| Campo | Tipo | Descripción |
|---|---|---|
| productoId | string | Producto |
| codigo | string | Código |
| nombre | string | Nombre |
| cantidad | number | Unidades |
| costoUnitario | number | Costo por unidad |
| subtotal | number | cantidad × costoUnitario |

---

## `compras/{compraId}/anexos/{anexoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del anexo |
| empresaId | string | Empresa |
| nombre | string | Nombre del archivo |
| tipo | string | `factura_escaneada` \| `factura_pdf` \| `anexo_legal` \| `otro` |
| url | string | URL en Storage |
| tamano | number | Tamaño en bytes |
| contentType | string | MIME type |
| fechaSubida | timestamp | Fecha de subida |
| subidoPor | string | UID del usuario que subió |

---

## `cuentas_por_pagar/{cuentaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador |
| empresaId | string | Empresa |
| proveedorId | string | Proveedor |
| compraId | string | Compra asociada |
| monto | number | Valor a pagar |
| pagado | number | Valor pagado |
| saldo | number | Saldo pendiente |
| fechaVencimiento | timestamp | Vencimiento (si aplica) |
| estado | string | `pendiente` \| `pagada` \| `vencida` |

---

## Ejemplo de compra

```json
{
  "empresaId": "empresa_001",
  "numeroOrden": "OC-000045",
  "fecha": "2026-10-14T10:00:00Z",
  "proveedorId": "prov_001",
  "items": [
    { "productoId": "P001", "codigo": "PROD-001", "nombre": "Camiseta Polo",
      "cantidad": 50, "costoUnitario": 20000, "subtotal": 1000000 }
  ],
  "valorTotal": 1000000,
  "formaPago": "credito",
  "estado": "pendiente",
  "actualizaCosto": true
}
```

Anexo de ejemplo:

```json
{
  "nombre": "factura_prov001.pdf",
  "tipo": "factura_pdf",
  "url": "empresas/empresa_001/compras/compra_45/1730000000_factura_prov001.pdf",
  "fechaSubida": "2026-10-14T10:05:00Z",
  "subidoPor": "uid_admin_01"
}
```

---

## Efectos de una compra

1. **Inventario:** `productos/{id}.stock += cantidad` (transacción).
2. **Costo:** si `actualizaCosto` → actualizar `costo` del producto.
3. **Inventario:** `movimientos_inventario` tipo `entrada`.
4. **Cuentas por pagar:** si `credito` → crear cuenta.
5. **Auditoría.**

---

## Índices sugeridos

- `proveedores`: `empresaId` + `nit` (único)
- `compras`: `empresaId` + `fecha` (desc)
- `compras`: `empresaId` + `proveedorId`
- `cuentas_por_pagar`: `empresaId` + `estado`
