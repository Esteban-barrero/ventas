# Investigación y Decisiones: Ventas

- **ID:** 005 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesita registrar ventas con múltiples ítems, tipos de pago y entrega, factura con
consecutivo, descuento de stock y trazabilidad del dinero.

## 2. Opciones Evaluadas

### 2.1. Atomicidad de la venta

| Opción | Ventajas | Desventajas |
|---|---|---|
| Escribir documentos por separado | Simple | Puede quedar inconsistente (stock/caja) |
| **Transacción de Firestore** | Todo o nada | Límites de una transacción |

**Decisión:** **Transacción** única: venta + stock + movimientos + caja/crédito.

### 2.2. Numeración de factura

| Opción | Ventajas | Desventajas |
|---|---|---|
| Auto-incremental por timestamp | Sin contador | No es consecutivo limpio |
| **Contador en `consecutivos/{empresaId}`** | Consecutivo controlado | Requiere transacción |
| Rango reservado (bloques) | Menos contención | Desperdicia números |

**Decisión:** **Contador** por empresa, incrementado dentro de la transacción.

### 2.3. Ítems de la venta

| Opción | Ventajas | Desventajas |
|---|---|---|
| **Array embebido en la venta** | Lectura en un documento | Tamaño si hay muchos ítems |
| Subcolección `ventas/{id}/items` | Escala | Más lecturas |

**Decisión:** **Array embebido** (una venta suele tener pocos ítems).

### 2.4. Factura electrónica

**Decisión:** Fuera de alcance inicial. El modelo guarda los datos necesarios (NIT, totales,
impuestos) para integrar la DIAN después.

### 2.5. Anulación

**Decisión:** Anulación **lógica** (`estado = anulada`) con **reverso de stock** y registro
de auditoría.

## 3. Preguntas Abiertas

- ¿Impuestos configurables por producto? (sí, previsto)
- ¿Notas crédito formales? (después)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11.5 y 12.6.
- Firestore — Transactions.
