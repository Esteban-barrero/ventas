# Guía Rápida: Inventario

- **ID:** 008 | **Fecha:** 2026-10-14

---

## Ver el inventario

1. Módulo **Inventario**.
2. Se muestra cada producto con su **stock actual** y su **stock mínimo**.
3. Filtros rápidos:
   - **Bajo stock** (≤ mínimo)
   - **Agotado** (stock = 0)

## Ver el kardex de un producto

1. Abrir el producto → **Kardex**.
2. Aparece el historial de movimientos (más reciente primero):

| Fecha | Tipo | Cantidad | Stock resultante | Referencia | Usuario |
|---|---|---|---|---|---|
| 2026-10-14 15:30 | salida | 2 | 48 | Venta FV-000123 | Juan P. |
| 2026-10-14 10:00 | entrada | 50 | 50 | Compra OC-000045 | Admin |

## Hacer un ajuste

1. Inventario → producto → **Ajustar**.
2. Indicar cantidad y **motivo** (obligatorio).
3. Solo roles autorizados (`administrador` / `gerente`).
4. Se registra el movimiento y queda **auditado**.

## Conteo físico (toma de inventario)

1. Inventario → **Nuevo conteo**.
2. Ingresar el **stock físico** contado por producto.
3. El sistema calcula la **diferencia** contra el sistema.
4. Al cerrar, se generan los **ajustes** por diferencia.

## Tipos de movimiento

| Tipo | Origen | Efecto |
|---|---|---|
| `entrada` | Compra | + |
| `salida` | Venta | − |
| `ajuste_positivo` | Manual / conteo | + |
| `ajuste_negativo` | Manual / conteo | − |
| `reverso` | Anulación | +/− |

## Valorización

```
valor = stock × costo
```

Se muestra por producto y el **total** de capital en mercancía.

> **Importante:** el kardex es **inmutable**. Un error se corrige con un movimiento inverso, nunca
> borrando.

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/inventario-contracts.md`](./contracts/inventario-contracts.md)
