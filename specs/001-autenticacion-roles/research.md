# Investigación y Decisiones: Autenticación y Roles

- **ID:** 001 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesita autenticación multi-tenant (varias empresas) con roles múltiples por usuario
y control de licencia. Se evaluaron las opciones de Firebase.

## 2. Opciones Evaluadas

### 2.1. Dónde guardar `empresaId` y `roles`

| Opción | Ventajas | Desventajas |
|---|---|---|
| Solo en Firestore (`usuarios`) | Simple | Requiere leer el documento en cada regla/consulta |
| **Custom claims en el token** | Reglas y consultas más rápidas; disponible sin lectura | Requiere Cloud Function; se actualiza al renovar token |
| Ambos | Lo mejor de los dos | Duplicación controlada |

**Decisión:** Usar **custom claims** (`empresaId`, `roles`) + el documento en Firestore como respaldo.
Forzar `getIdToken(true)` tras cambios de rol.

### 2.2. Validación de licencia

| Opción | Ventajas | Desventajas |
|---|---|---|
| En el cliente (Flutter) | Rápido | Se puede burlar |
| **Cloud Function** | Seguro, fuente de verdad | Requiere conexión (se cachea) |
| Reglas de Firestore | Automático | Difícil expresar lógica de fechas |

**Decisión:** **Cloud Function** `validarLicencia`, con caché local para modo offline.

### 2.3. Modelo de roles

- Roles fijos del sistema (Administrador, Gerente, Vendedor, etc.).
- Permisos por rol definidos en la colección `roles`.
- Un usuario puede tener varios roles → permisos = unión.

## 3. Preguntas Abiertas

- ¿Se permitirá crear roles personalizados por empresa? (sí, previsto en el documento)
- ¿Autenticación biométrica? (fuera de alcance inicial)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 5, 7.
- Firebase Auth — Custom Claims.
