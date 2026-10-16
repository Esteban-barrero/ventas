---
name: Contexto del proyecto
description: Contexto del aplicativo de ventas (Flutter + Firebase, SDD, multi-tenant): repositorios, proyecto Firebase, estructura, empresa demo, cuenta Super Admin y convenciones. Úsalo como contexto rápido antes de trabajar en el proyecto.
---

# Contexto del proyecto — Aplicativo de Ventas

App multiplataforma (**Flutter + Firebase**) de gestión de ventas, con
arquitectura **multi-tenant** (varias empresas en una sola app). Metodología
**SDD** (Spec-Driven Development).

## Repositorios

- **`ventas`** (principal, donde se trabaja y se hace push):
  `https://github.com/Esteban-barrero/ventas.git`
- **`proyecto_core`** (espejo, snapshot de **un solo commit**):
  `https://github.com/Esteban-barrero/proyecto_core.git`
  - Se regenera con `git archive` + repo nuevo + `git push -f`.

## Firebase

- Proyecto: **`aplicativo-de-ventas-d8bcd`** (plan **Blaze**).
- **Firestore** en `southamerica-east1`; bucket de Storage
  `aplicativo-de-ventas-d8bcd.firebasestorage.app`.
- Cloud Functions en `us-central1` (+ `onUsuarioEscrito` en `southamerica-east1`).
- Sin Firebase CLI instalado: las reglas se despliegan con la skill
  **desplegar-reglas**.

## Cuentas de prueba

- Empresa **`demo`** (`empresas/demo`), con el Administrador
  `estebanbarrerosanabria6@gmail.com`.
- Cuenta **Super Admin**: `algoritmo.ebarrero@gmail.com` (sin empresa; ve el
  módulo **Empresas**). *La contraseña no se versiona: se maneja aparte.*

## Estructura

```
app/         Flutter (lib/features/<feature>/{data,domain,presentation})
functions/   Cloud Functions (TypeScript)
specs/       Specs SDD (001 a 015)
Documentacion/  Word de levantamiento (no se edita; fuente de verdad = specs)
```

## Funcionalidades implementadas

- 001 Autenticación y roles · 002 Empresas · 003 Catálogo · 004 Clientes ·
  005 Ventas. Pendientes: 006–015.

## Convenciones rápidas

- Identificadores en inglés; comentarios y docs en **español**.
- Patrón **StatefulWidget + repositorios** (sin Riverpod).
- Reglas de Firestore **por perfil** (no por *claims*).
- Fechas/valores con `core/formato/fechas.dart` (no `intl`).
- Push siempre a `ventas` (`origin`).
