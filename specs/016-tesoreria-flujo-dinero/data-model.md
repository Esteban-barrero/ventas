# Modelo de Datos: Tesorería y flujo del dinero

- **ID:** 016 | **Fecha:** 2026-10-16

---

## `movimientos_dinero/{movimientoId}` (inmutable)

Libro único del dinero de la empresa. Reemplaza a `movimientos_caja` (spec 009),
que pasa a ser un movimiento más con `ubicacion: caja_fisica`.

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador |
| empresaId | string | Empresa propietaria |
| fecha | timestamp | Cuándo ocurrió |
| tipo | string | `ingreso` \| `egreso` \| `traslado` |
| monto | number | Valor del movimiento (> 0) |
| medioPago | string | `efectivo` \| `nequi` \| `bancolombia` \| `tarjeta` |
| ubicacion | string | Ubicación (origen si es traslado) |
| ubicacionDestino | string | Destino (solo `traslado`) |
| responsableUid | string | UID de quien tiene el dinero |
| responsableNombre | string | Nombre de quien tiene el dinero |
| descripcion | string | Concepto libre |
| referenciaTipo | string | `venta` \| `cobro` \| `compra` \| `gasto` \| `retiro` \| `traslado` \| `ajuste` \| `manual` |
| referenciaId | string | Documento de origen |
| cajaId | string | Turno asociado (opcional, caja física) |
| usuarioUid | string | Quién registró el movimiento |
| usuarioNombre | string | Nombre de quien registró |

### Ubicaciones (`UbicacionDinero`)

| id | Nombre |
|---|---|
| `caja_fisica` | Caja física |
| `vendedor_efectivo` | Efectivo con el vendedor |
| `contra_entrega` | Pago contra entrega (en tránsito) |
| `nequi` | Nequi |
| `banco` | Banco (Bancolombia) |
| `tarjeta_por_consignar` | Tarjeta (por consignar) |

### Cálculo de la posición

```
saldo(ubicacion) = Σ ingresos(ubicacion) − Σ egresos(ubicacion)
                 + Σ traslados(→ ubicacion) − Σ traslados(ubicacion →)

totalEmpresa = Σ saldo(ubicacion)
```

---

## `cajas/{cajaId}` (spec 009, sin cambios)

Turno de caja. La **caja física** es la ubicación `caja_fisica`. El efectivo
esperado de un turno es la suma de los movimientos de dinero con ese `cajaId`.

---

## `ventas/{ventaId}` — snapshot de rentabilidad (RF-07)

`items[]` incorpora:

| Campo | Tipo | Descripción |
|---|---|---|
| costoUnitario | number | Costo del producto al momento de la venta |
| utilidad | number | `cantidad × (precioUnitario − costoUnitario)` |

Y en la venta:

| Campo | Tipo | Descripción |
|---|---|---|
| costoTotal | number | Suma de los costos de las líneas |
| utilidadTotal | number | Suma de las utilidades de las líneas |
| margenPct | number | Margen promedio (`utilidad / subtotal × 100`) |
