# Modelo de Datos: Caja y Trazabilidad del dinero

- **ID:** 009 | **Fecha:** 2026-10-14

---

## `cajas/{cajaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador de la caja/turno |
| empresaId | string | Empresa propietaria |
| nombre | string | Nombre/etiqueta de la caja |
| usuarioUid | string | Cajero responsable |
| usuarioNombre | string | Nombre del cajero |
| estado | string | `abierta` \| `cerrada` |
| montoInicial | number | Base de apertura |
| saldo | number | Saldo actual (inicial + ingresos − egresos) |
| medioPredominante | string | `efectivo` \| `nequi` \| `bancolombia` \| `tarjeta` |
| fechaApertura | timestamp | Apertura |
| fechaCierre | timestamp | Cierre |
| cerradoPor | string | UID que cerró |
| diferenciaCierre | number | Sobrante/faltante al cerrar |

---

## `movimientos_caja/{movimientoId}` (inmutable)

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador |
| empresaId | string | Empresa |
| cajaId | string | Caja asociada |
| tipo | string | `ingreso` \| `egreso` \| `retiro` \| `gasto` |
| concepto | string | Descripción |
| monto | number | Valor |
| medioPago | string | `efectivo` \| `nequi` \| `bancolombia` \| `tarjeta` |
| referenciaTipo | string | `venta` \| `cobro` \| `compra` \| `manual` |
| referenciaId | string | ID del origen |
| responsableUid | string | Quién tiene/recibe el dinero |
| estadoDinero | string | `en_caja` \| `en_transito` \| `en_banco` \| `entregado` |
| empresaEnvio | string | Empresa de envío (si contra entrega) |
| domiciliario | string | Domiciliario (si contra entrega) |
| saldoResultante | number | Saldo de caja después |
| usuarioUid | string | Quién registró |
| fecha | timestamp | Fecha y hora |

---

## `arqueos/{arqueoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador |
| empresaId | string | Empresa |
| cajaId | string | Caja |
| fecha | timestamp | Fecha del arqueo |
| totalEsperado | number | Según el sistema |
| totalContado | number | Conteo físico |
| diferencia | number | `contado − esperado` |
| justificacion | string | Explicación de la diferencia |
| desgloseEfectivo | map | Billetes/monedas |
| usuarioUid | string | Quién arquó |
| aprobadoPor | string | Quién aprobó |

---

## Ejemplo de movimiento (pago contra entrega)

```json
{
  "empresaId": "empresa_001",
  "cajaId": "caja_01",
  "tipo": "ingreso",
  "concepto": "Venta contra entrega FV-000123",
  "monto": 65000,
  "medioPago": "efectivo",
  "referenciaTipo": "venta",
  "referenciaId": "venta_123",
  "responsableUid": "uid_domiciliario_07",
  "estadoDinero": "en_transito",
  "empresaEnvio": "Envios Rapidos SAS",
  "domiciliario": "Carlos M.",
  "saldoResultante": 0,
  "usuarioUid": "uid_vend_01",
  "fecha": "2026-10-14T15:30:00Z"
}
```

Al entregarse, se actualiza `estadoDinero = entregado` y `responsableUid = uid_cajero_01`.

---

## Cálculos

```
saldo      = montoInicial + Σ ingreso - Σ egreso
esperado   = saldo
diferencia = totalContado - esperado   // + sobrante, - faltante
```

---

## Trazabilidad del dinero

| Pregunta | Cómo se responde |
|---|---|
| ¿Quién vendió? | `ventas.vendedorUid` |
| ¿Quién tiene el dinero? | `movimientos_caja.responsableUid` |
| ¿Dónde está el dinero? | `movimientos_caja.estadoDinero` |
| ¿Cómo se pagó? | `movimientos_caja.medioPago` |
| ¿Cuándo se entregó? | `fecha` + cambio de estado |

---

## Índices sugeridos

- `cajas`: `empresaId` + `estado` + `usuarioUid`
- `movimientos_caja`: `empresaId` + `fecha` (desc)
- `movimientos_caja`: `empresaId` + `cajaId`
- `movimientos_caja`: `empresaId` + `estadoDinero`
- `arqueos`: `empresaId` + `cajaId`
