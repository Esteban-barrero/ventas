# Investigación y Decisiones: Auditoría

- **ID:** 012 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se requiere auditar INSERT/UPDATE/DELETE con quién, cuándo, colección, campo y valores
anterior/nuevo, con retención mínima de **6 meses** e inmutabilidad.

## 2. Opciones Evaluadas

### 2.1. ¿Dónde se genera la auditoría?

| Opción | Ventajas | Desventajas |
|---|---|---|
| En el cliente (Flutter) | Fácil de escribir | Se puede evadir/alterar |
| **Cloud Functions (triggers)** | Confiable, central | Requiere Functions |
| Triggers de BD nativos | Atómico | Firestore no tiene triggers nativos equivalentes |

**Decisión:** **Cloud Functions triggers** (`onCreate`, `onUpdate`, `onDelete`). Ya decidido en el
proyecto.

### 2.2. Inmutabilidad

| Opción | Ventajas | Desventajas |
|---|---|---|
| Permitir update/delete | Flexible | No es auditoría real |
| **Solo lectura (write: false)** | Auditoría confiable | Nada |

**Decisión:** Colección `_auditoria` de **solo lectura**; solo el Admin SDK (Functions) escribe.

### 2.3. Modelo del cambio

| Opción | Ventajas | Desventajas |
|---|---|---|
| Guardar el documento completo antes/después | Fácil de consultar | Duplica datos |
| **Guardar solo los campos cambiados (antes/después)** | Compacto y claro | Requiere diff |

**Decisión:** Guardar el **detalle de cambios por campo** (antes/después) + el **snapshot** cuando
sea útil (DELETE).

### 2.4. Retención

| Opción | Ventajas | Desventajas |
|---|---|---|
| Sin retención definida | — | Incumple el requisito |
| **TTL >= 6 meses** | Cumple | Requiere política |

**Decisión:** Retención **mínimo 6 meses** (configurable hacia arriba) usando **política TTL** de
Firestore sobre un campo `expiraEn` (nunca menor a 6 meses).

### 2.5. Volumen

**Decisión:** Particionar por **mes** (p. ej. subcolección o campo `periodo`) para consultas rápidas
y TTL ordenado.

## 3. Preguntas Abiertas

- ¿Firma/criptografía de los registros? (mejora)
- ¿Alertas en tiempo real por cambios críticos? (fase posterior)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11 Auditoría y 12.
- Firestore — TTL Policies.
- Cloud Functions — Firestore Triggers.
