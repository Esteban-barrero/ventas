# Modelo de Datos: Créditos y Cobros

- **ID:** 006 | **Fecha:** 2026-10-14

---

## `creditos/{creditoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del crédito |
| empresaId | string | Empresa propietaria |
| clienteId | string | Cliente deudor |
| clienteUid | string | UID del cliente (si tiene cuenta) |
| ventaId | string | Venta que originó el crédito |
| montoTotal | number | Monto base del crédito |
| tasaInteres | number | Interés aplicado (%) |
| montoConInteres | number | Monto + interés |
| numeroCuotas | number | Número de cuotas |
| periodicidad | string | `semanal` \| `quincenal` \| `mensual` |
| fechaInicio | timestamp | Fecha de apertura |
| fechaPrimerPago | timestamp | Fecha de la primera cuota |
| saldoActual | number | Saldo pendiente |
| cuotasPagadas | number | Cuotas pagadas |
| diasMora | number | Días de mora actuales |
| aprobado | boolean | Si fue aprobado |
| aprobadoPor | string | UID de quien aprobó |
| fechaAprobacion | timestamp | Fecha de aprobación |
| estado | string | `activo` \| `pagado` \| `vencido` \| `cancelado` |

---

## `creditos/{creditoId}/cuotas/{cuotaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| numero | number | Número de cuota (1..N) |
| fechaVencimiento | timestamp | Fecha de vencimiento |
| monto | number | Valor de la cuota |
| pagado | number | Valor pagado |
| saldo | number | Valor pendiente |
| estado | string | `pendiente` \| `pagada` \| `vencida` \| `parcial` |
| fechaPago | timestamp | Fecha del último pago |

---

## `pagos_credito/{pagoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del pago |
| empresaId | string | Empresa |
| creditoId | string | Crédito |
| clienteId | string | Cliente |
| cuotaNumero | number | Cuota afectada |
| monto | number | Valor pagado |
| medioPago | string | `efectivo` \| `transferencia_nequi` \| `transferencia_bancolombia` \| `tarjeta` |
| fecha | timestamp | Fecha del pago |
| cobradorUid | string | Quién cobró |
| movimientoCajaId | string | Movimiento de caja generado |
| notas | string | Observaciones |

---

## Ejemplo de crédito

```json
{
  "empresaId": "empresa_001",
  "clienteId": "cliente_001",
  "ventaId": "venta_123",
  "montoTotal": 300000,
  "tasaInteres": 10,
  "montoConInteres": 330000,
  "numeroCuotas": 3,
  "periodicidad": "mensual",
  "saldoActual": 330000,
  "cuotasPagadas": 0,
  "diasMora": 0,
  "aprobado": true,
  "estado": "activo"
}
```

Cuotas generadas (ejemplo):

| # | Vencimiento | Monto | Estado |
|---|---|---|---|
| 1 | 2026-11-14 | 110000 | pendiente |
| 2 | 2026-12-14 | 110000 | pendiente |
| 3 | 2027-01-14 | 110000 | pendiente |

---

## Efectos de un pago

1. Actualiza la **cuota** (pagado/saldo/estado).
2. Actualiza el **crédito** (saldo, cuotasPagadas, estado).
3. Crea un **movimiento de caja**.
4. Registra **auditoría**.

---

## Índices sugeridos

- `creditos`: `empresaId` + `estado`, `empresaId` + `clienteId`
- `cuotas`: `estado` + `fechaVencimiento`
- `pagos_credito`: `empresaId` + `fecha` (desc)
