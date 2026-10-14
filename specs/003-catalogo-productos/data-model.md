# Modelo de Datos: Catálogo de Productos

- **ID:** 003 | **Fecha:** 2026-10-14

---

## `productos/{productoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del producto |
| empresaId | string | Empresa propietaria |
| codigo | string | Código único por empresa |
| nombre | string | Nombre del producto |
| descripcion | string | Descripción general |
| medidas | map | `{ material, dimensiones, peso, color }` |
| categoriaId | string | Referencia a `categorias` |
| fotoPrincipal | string | URL en Storage |
| galeria | array&lt;string&gt; | URLs adicionales |
| costo | number | Costo de compra al proveedor |
| precioDetal | number | Precio al por menor |
| precioMayor | number | Precio al por mayor |
| margenes | map | `{ contado: number?, credito: number? }` (opcional, hereda) |
| costoEnvio | number | Costo de envío individual (opcional, hereda) |
| stock | number | Unidades disponibles |
| stockMinimo | number | Umbral de alerta |
| activo | boolean | Si está visible en el catálogo |
| fechaCreacion | timestamp | Fecha de creación |
| fechaActualizacion | timestamp | Última modificación |

### Ejemplo

```json
{
  "empresaId": "empresa_001",
  "codigo": "PROD-001",
  "nombre": "Camiseta Polo",
  "descripcion": "Camiseta de algodón",
  "medidas": { "material": "Algodón", "dimensiones": "M/L/XL", "peso": "200g", "color": "Azul" },
  "categoriaId": "cat_rop",
  "fotoPrincipal": "empresas/empresa_001/productos/PROD-001/foto.png",
  "galeria": [],
  "costo": 20000,
  "precioDetal": 30000,
  "precioMayor": 26000,
  "margenes": { "contado": 50, "credito": 65 },
  "costoEnvio": null,
  "stock": 40,
  "stockMinimo": 10,
  "activo": true
}
```

---

## `categorias/{categoriaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador de la categoría |
| empresaId | string | Empresa propietaria |
| nombre | string | Nombre de la categoría |
| descripcion | string | Descripción (opcional) |
| activo | boolean | Si está disponible |

---

## Herencia de márgenes

```
margen_efectivo(producto, "contado"):
  producto.margenes.contado  ??  empresa.parametros.margenContado

margen_efectivo(producto, "credito"):
  producto.margenes.credito  ??  empresa.parametros.margenCredito
```

## Herencia de costo de envío

```
costo_envio_efectivo(producto):
  producto.costoEnvio  ??  empresa.parametros.costoEnvio
```

---

## `movimientos_inventario/{movId}` (referencia)

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa |
| productoId | string | Producto afectado |
| tipo | string | `entrada` \| `salida` \| `ajuste` |
| cantidad | number | Unidades |
| motivo | string | Compra, venta, ajuste |
| referenciaId | string | Venta o compra asociada |
| fecha | timestamp | Fecha del movimiento |
| usuario | string | Quién lo realizó |

---

## Índices sugeridos

- `productos`: `empresaId` + `activo`, `empresaId` + `categoriaId`
- `productos`: `empresaId` + `codigo` (único)
- `categorias`: `empresaId` + `activo`
