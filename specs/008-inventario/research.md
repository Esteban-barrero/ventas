# Investigación y Decisiones: Inventario

- **ID:** 008 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesita controlar existencias con trazabilidad total (kardex), soportar entradas por compras y
salidas por ventas, permitir ajustes controlados y alertar sobre stock mínimo.

## 2. Opciones Evaluadas

### 2.1. Fuente de verdad del stock

| Opción | Ventajas | Desventajas |
|---|---|---|
| Solo campo `productos.stock` | Rápido de leer | Sin historial ni trazabilidad |
| **Campo `stock` + kardex inmutable** | Rápido y auditable | Dos escrituras por operación |
| Recalcular desde el kardex siempre | Fuente única | Costoso y lento de consultar |

**Decisión:** **Campo `stock`** como vista rápida (fuente de verdad operativa) + **kardex**
`movimientos_inventario` como historial (fuente de verdad auditable). El stock debe cuadrar con
la suma del kardex.

### 2.2. Inmutabilidad de los movimientos

| Opción | Ventajas | Desventajas |
|---|---|---|
| Permitir editar/borrar movimientos | Flexible | Rompe la auditoría |
| **Inmutable (corregir con inverso)** | Auditoría confiable | Más movimientos |

**Decisión:** **Inmutable**. Las correcciones se hacen con un movimiento inverso.

### 2.3. Ajustes manuales

**Decisión:** Requieren **motivo** y rol autorizado (`administrador`/`gerente`). Quedan auditados.

### 2.4. Multibodega

| Opción | Ventajas | Desventajas |
|---|---|---|
| Una sola bodega | Simple | No sirve a empresas con sucursales |
| **Stock por bodega (campo `bodegaId`)** | Escala | Mayor complejidad |

**Decisión:** Diseñar los movimientos con `bodegaId` (opcional, por defecto `principal`) para no
bloquear el crecimiento.

### 2.5. Stock negativo

**Decisión:** **No permitido** por defecto; configurable por empresa con permiso especial.

## 3. Preguntas Abiertas

- ¿Lotes y fechas de vencimiento? (después)
- ¿Lectura con código de barras? (mejora)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, sección 11 Inventario.
- Firestore — Transactions.
