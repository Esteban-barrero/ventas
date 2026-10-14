# Modelo de Datos: Inventario

- **ID:** 008 | **Fecha:** 2026-10-14

---

## `movimientos_inventario/{movimientoId}` (kardex, inmutable)

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del movimiento |
| empresaId | string | Empresa propietaria |
| productoId | string | Producto |
| codigo | string | Código del producto |
| nombre | string | Nombre del producto |
| tipo | string | `entrada` \| `salida` \| `ajuste_positivo` \| `ajuste_negativo` \| `reverso` |
| cantidad | number | Cantidad del movimiento (positiva) |
| stockAnterior | number | Stock antes del movimiento |
| stockResultante | number | Stock después del movimiento |
| motivo | string | Razón (para ajustes) |
| referenciaTipo | string | `venta` \| `compra` \| `ajuste` \| `conteo` \| `anulacion` |
| referenciaId | string | ID del documento origen |
| bodegaId | string | Bodega/sucursal (por defecto `principal`) |
| usuarioUid | string | Quién lo registró |
| fecha | timestamp | Fecha y hora |

---

## `conteos_inventario/{conteoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del conteo |
| empresaId | string | Empresa |
| fecha | timestamp | Fecha del conteo |
| bodegaId | string | Bodega contada |
| estado | string | `en_proceso` \| `cerrado` \| `anulado` |
| items | array | Ver abajo |
| usuarioUid | string | Quién realizó el conteo |
| aprobadoPor | string | Quién aprobó el cierre |

### `items[]` (array embebido)

| Campo | Tipo | Descripción |
|---|---|---|
| productoId | string | Producto |
| nombre | string | Nombre |
| stockSistema | number | Stock según el sistema |
| stockFisico | number | Stock contado físicamente |
| diferencia | number | `stockFisico - stockSistema` |
| ajusteGenerado | boolean | Si generó ajuste |

---

## `productos/{productoId}` (campos de inventario)

| Campo | Tipo | Descripción |
|---|---|---|
| stock | number | Existencias actuales |
| stockMinimo | number | Umbral de alerta |
| costo | number | Costo vigente (para valorización) |

---

## Ejemplo de movimiento

```json
{
  "empresaId": "empresa_001",
  "productoId": "P001",
  "codigo": "PROD-001",
  "nombre": "Camiseta Polo",
  "tipo": "salida",
  "cantidad": 2,
  "stockAnterior": 50,
  "stockResultante": 48,
  "referenciaTipo": "venta",
  "referenciaId": "venta_123",
  "bodegaId": "principal",
  "usuarioUid": "uid_vend_01",
  "fecha": "2026-10-14T15:30:00Z"
}
```

---

## Efectos por operación

| Operación | Movimiento | Producto |
|---|---|---|
| Compra | `entrada` | `stock += cantidad` |
| Venta | `salida` | `stock -= cantidad` |
| Ajuste + | `ajuste_positivo` | `stock += cantidad` |
| Ajuste − | `ajuste_negativo` | `stock -= cantidad` |
| Anulación compra | `reverso` | `stock -= cantidad` |
| Anulación venta | `reverso` | `stock += cantidad` |
| Conteo (diferencia) | `ajuste_*` | `stock = stockFisico` |

---

## Valorización

```
valorizacion(producto) = stock * costo
valorizacionTotal      = Σ valorizacion(producto)
```

---

## Índices sugeridos

- `movimientos_inventario`: `empresaId` + `productoId` + `fecha` (desc)
- `movimientos_inventario`: `empresaId` + `tipo` + `fecha`
- `movimientos_inventario`: `empresaId` + `referenciaId`
- `productos`: `empresaId` + `stock` (para bajo stock)
