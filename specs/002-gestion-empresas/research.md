# Investigación y Decisiones: Gestión de Empresas

- **ID:** 002 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesita incorporar múltiples empresas (tenants) a una sola aplicación, con datos
aislados, licencias controladas y personalización (logo, tema).

## 2. Opciones Evaluadas

### 2.1. Estrategia multi-tenant

| Opción | Ventajas | Desventajas |
|---|---|---|
| Colección por empresa | Aislamiento total | Difícil de administrar y consultar global |
| **Campo `empresaId` en cada documento** | Simple, consultas globales fáciles | Hay que filtrar siempre por `empresaId` |
| Proyecto Firebase por empresa | Aislamiento máximo | Múltiples proyectos, costos y mantenimiento |

**Decisión:** Campo **`empresaId`** en todas las colecciones + reglas de seguridad.

### 2.2. Creación del administrador de la empresa

| Opción | Ventajas | Desventajas |
|---|---|---|
| Cliente crea el usuario | Simple | El cliente debe estar logueado como Super Admin y gestionar Auth |
| **Cloud Function con Admin SDK** | Atómico, seguro, oculta privilegios | Requiere Cloud Functions |

**Decisión:** Cloud Function `crearEmpresa` con **Admin SDK** (crea Auth user, perfil, claims, parámetros y roles).

### 2.3. Avisos de vencimiento

| Opción | Ventajas | Desventajas |
|---|---|---|
| Al iniciar sesión | Simple | Solo avisa cuando el usuario entra |
| **Cloud Scheduler diario** | Avisa siempre a tiempo | Requiere programación |

**Decisión:** **Cloud Scheduler** diario que evalúa vencimientos y envía correo + notificación in-app.

### 2.4. Eliminación de empresas

**Decisión:** Eliminación **lógica** (`estado = eliminada`). No se borra físicamente para conservar
auditoría y permitir recuperación.

### 2.5. Logo

**Decisión:** Guardar en Storage como PNG, comprimir con `sharp`, y almacenar `logoAncho`/`logoAlto`.
Tamaño recomendado 512x512, máximo 500 KB.

## 3. Preguntas Abiertas

- ¿Se permitirá que la empresa se registre sola (self-service)? (fuera de alcance inicial)
- ¿Se facturará integrado con pasarela? (después)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 5 y 12.1.
- Firebase Admin SDK — Create user.
- Cloud Scheduler — Scheduled functions.
