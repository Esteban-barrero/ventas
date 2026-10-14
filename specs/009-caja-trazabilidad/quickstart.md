# Guía Rápida: Caja y Trazabilidad del dinero

- **ID:** 009 | **Fecha:** 2026-10-14

---

## Abrir la caja

1. Módulo **Caja** → **Abrir caja**.
2. Ingresar el **monto inicial** (base del turno).
3. Confirmar. Queda una caja **abierta** para tu usuario.

> Solo puede haber **una caja abierta por usuario**.

## Registrar un movimiento

1. En el panel de caja → **Nuevo movimiento**.
2. Elegir **tipo**: ingreso, egreso, retiro o gasto.
3. Indicar **monto**, **concepto** y **medio de pago**:
   - Efectivo
   - Nequi
   - Bancolombia
   - Tarjeta
4. Guardar. El **saldo** se actualiza.

## Cerrar la caja (arqueo)

1. Caja → **Cerrar caja**.
2. Contar el efectivo e ingresar el **total contado**.
3. El sistema calcula la **diferencia**:

```
diferencia = contado − esperado
```

| Resultado | Significado |
|---|---|
| `> 0` | **Sobrante** |
| `= 0` | Cuadre perfecto |
| `< 0` | **Faltante** |

4. Si hay diferencia, escribir la **justificación**.
5. Cerrar (queda **bloqueada**).

## Trazabilidad del dinero

Consulta que responde:

| Pregunta | Dónde se ve |
|---|---|
| ¿Quién vendió? | Vendedor de la venta |
| ¿Quién tiene el dinero? | Responsable del movimiento |
| ¿Dónde está? | Estado: en caja / en tránsito / en banco / entregado |
| ¿Cómo se pagó? | Medio de pago |

## Pago contra entrega

1. La venta se marca como **envío** con pago **contra entrega**.
2. El dinero queda **en tránsito** (responsable = domiciliario).
3. Al entregar, el cajero lo pasa a **entregado** (responsable = cajero) y entra a caja.

## Estados del dinero

| Estado | Significado |
|---|---|
| `en_caja` | En poder de un cajero |
| `en_transito` | Con el domiciliario / empresa de envío |
| `en_banco` | Consignado |
| `entregado` | Recibido y cuadrado |

> **Importante:** los movimientos de caja son **inmutables**. Un error se corrige con un
> **contramovimiento**.

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/caja-contracts.md`](./contracts/caja-contracts.md)
