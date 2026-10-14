# Investigación y Decisiones: Caja y Trazabilidad del dinero

- **ID:** 009 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesita controlar el dinero de la empresa: apertura/cierre de caja, movimientos de efectivo,
arqueo, y sobre todo **trazabilidad** (quién vendió, quién tiene el dinero y en qué estado),
incluyendo el **pago contra entrega** por parte de empresas de envío.

## 2. Opciones Evaluadas

### 2.1. Modelo de caja

| Opción | Ventajas | Desventajas |
|---|---|---|
| Caja única por empresa | Simple | No refleja turnos ni responsables |
| **Caja/turno por usuario** | Trazabilidad por cajero | Más documentos |

**Decisión:** **Caja/turno por usuario**; una abierta a la vez por usuario.

### 2.2. Inmutabilidad de movimientos

| Opción | Ventajas | Desventajas |
|---|---|---|
| Editar/borrar movimientos | Flexible | Rompe auditoría |
| **Inmutable + contramovimiento** | Confiable | Más registros |

**Decisión:** **Inmutable**; correcciones con contramovimiento.

### 2.3. Saldo: campo o cálculo

| Opción | Ventajas | Desventajas |
|---|---|---|
| Calcular sumando movimientos | Fuente única | Lento con muchos movimientos |
| **Campo `saldo` actualizado en transacción** | Rápido | Debe mantenerse consistente |

**Decisión:** **Campo `saldo`** recalculado en **transacción**; verificable contra la suma de movimientos.

### 2.4. Trazabilidad del dinero

| Opción | Ventajas | Desventajas |
|---|---|---|
| Solo el movimiento | Simple | No dice quién tiene el dinero |
| **`responsableUid` + `estadoDinero`** | Traza el efectivo y el contra entrega | Modelo más rico |

**Decisión:** Campos **`responsableUid`** y **`estadoDinero`** (`en_caja`, `en_transito`,
`en_banco`, `entregado`) para seguir el dinero, incluyendo el pago contra entrega.

### 2.5. Reapertura de caja

**Decisión:** Caja cerrada queda **bloqueada**; solo **Super Admin** puede reabrir, dejando auditoría.

## 3. Preguntas Abiertas

- ¿Conciliación bancaria automática? (después)
- ¿Cuadre de medios distintos al efectivo (Nequi/Bancolombia)? (sí, previsto)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11 Caja y 12 Trazabilidad del dinero.
- Firestore — Transactions.
