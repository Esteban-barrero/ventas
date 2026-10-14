# Investigación y Decisiones: Créditos y Cobros

- **ID:** 006 | **Fecha:** 2026-10-14

---

## 1. Contexto

Las ventas a crédito necesitan un plan de cuotas (semanal, quincenal o mensual), control de
saldo y mora, y registro trazable de cada cobro.

## 2. Opciones Evaluadas

### 2.1. Modelado de las cuotas

| Opción | Ventajas | Desventajas |
|---|---|---|
| Array embebido en el crédito | Una sola lectura | Difícil consultar cuotas individuales / vencimientos |
| **Subcolección `creditos/{id}/cuotas`** | Consultas por vencimiento y estado | Más documentos |

**Decisión:** **Subcolección** de cuotas (facilita avisos y actualizaciones puntuales).

### 2.2. Cálculo de mora

| Opción | Ventajas | Desventajas |
|---|---|---|
| En el cliente al abrir | Sin infraestructura | Depende de que alguien abra la app |
| **Cloud Function programada** | Siempre actualizado + notifica | Requiere Scheduler |

**Decisión:** **Cloud Function programada** diaria que recalcula mora y notifica.

### 2.3. Registro de pagos

| Opción | Ventajas | Desventajas |
|---|---|---|
| Solo actualizar el crédito | Simple | Pierde detalle de cuotas y caja |
| **Transacción: cuota + crédito + caja + auditoría** | Consistente y trazable | Más complejo |

**Decisión:** **Transacción** completa por cada pago.

### 2.4. Interés

**Decisión:** **Interés simple** configurable por empresa (porcentaje sobre el monto). Se evalúa
interés compuesto después.

## 3. Preguntas Abiertas

- ¿Refinanciación de créditos? (después)
- ¿Cupo de crédito automático por cliente? (evaluar)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11.6 y 12.7.
- Firestore — Transactions / Subcollections.
