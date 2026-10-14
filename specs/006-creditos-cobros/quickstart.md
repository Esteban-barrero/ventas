# Guía Rápida: Créditos y Cobros

- **ID:** 006 | **Fecha:** 2026-10-14

---

## Cómo nace un crédito

1. Se registra una **venta a crédito** (spec 005).
2. El sistema **genera el crédito** automáticamente.
3. Un rol autorizado lo **aprueba**.
4. Se crea el **plan de cuotas**.

## Periodo de las cuotas

| Periodicidad | Intervalo |
|---|---|
| Semanal | 7 días |
| Quincenal | 15 días |
| Mensual | 1 mes |

## Cálculo

```
montoConInteres = monto * (1 + tasaInteres / 100)
montoCuota      = montoConInteres / numeroCuotas
```

Ejemplo: monto 300.000, interés 10%, 3 cuotas → **110.000** por cuota.

## Registrar un pago

1. Abrir el **crédito**.
2. Clic en **Registrar pago**.
3. Indicar monto y **medio de pago**.
4. Guardar. El sistema:
   - Actualiza la cuota y el saldo.
   - Registra el **movimiento de caja**.
   - Guarda **auditoría** (quién cobró, cuándo y cuánto).

## Estados del crédito

| Estado | Significado |
|---|---|
| `activo` | Vigente, con saldo |
| `pagado` | Sin saldo pendiente |
| `vencido` | Con cuotas vencidas |
| `cancelado` | Anulado administrativamente |

## Mora

- **Días de mora** = días desde el vencimiento sin pago completo.
- Si supera el límite configurado, el cliente se marca **moroso**.

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/creditos-contracts.md`](./contracts/creditos-contracts.md)
