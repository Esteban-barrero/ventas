# Guía Rápida: Ventas

- **ID:** 005 | **Fecha:** 2026-10-14

---

## Registrar una venta

1. Entrar al módulo **Ventas** → **Nueva venta**.
2. Seleccionar el **cliente** (o "Consumidor final").
3. Agregar **productos** y cantidades.
4. Elegir **tipo de venta**: contado o crédito.
5. Elegir **tipo de entrega**:
   - Presencial
   - Entrega local
   - Recoger en local
   - Envío
6. Elegir **medio de pago**: efectivo, tarjeta, transferencia (Nequi / Bancolombia).
7. Aplicar descuento (si aplica).
8. Confirmar. El sistema:
   - Asigna **número de factura** consecutivo.
   - **Descuenta stock** (transacción).
   - Registra el **movimiento de caja** o el **crédito**.
   - Guarda la **auditoría**.

## Regla de envío

| Tipo de entrega | Costo de envío |
|---|---|
| Presencial | 0 |
| Recoger en local | 0 |
| Entrega local | Según producto o general |
| Envío | Según producto o general |

## Cálculo del total

```
total = subtotal + costoEnvio - descuento + impuestos
```

## Anular una venta

1. Abrir la venta.
2. Clic en **Anular** (requiere permiso).
3. Indicar el motivo.
4. El sistema **revierte el stock**, ajusta caja/crédito y registra auditoría.

## Estados

| Estado | Significado |
|---|---|
| `registrada` | Venta válida |
| `anulada` | Venta revertida |

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/ventas-contracts.md`](./contracts/ventas-contracts.md)
