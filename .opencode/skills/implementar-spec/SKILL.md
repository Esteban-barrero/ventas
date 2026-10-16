---
name: Implementar spec
description: Flujo SDD para implementar una especificación del aplicativo de ventas (leer spec/plan/tasks, implementar por fases, documentar según el Principio 11, ejecutar analyze y test, y hacer commit + push a ventas).
---

# Implementar una spec (SDD)

Usa este flujo cuando vayas a implementar una funcionalidad del proyecto
(`specs/00X-...`). Respeta la metodología **Spec-Driven Development**.

## Antes de escribir código

1. Lee `.specify/memory/constitution.md` y `AGENTS.md`.
2. Lee la carpeta de la spec: `spec.md`, `plan.md`, `data-model.md`,
   `contracts/`, `research.md`, `quickstart.md` y `tasks.md`.
3. **Resuelve conflictos** entre la spec y lo ya implementado antes de codificar
   (p. ej. nombres de campos, reglas o modelos que no calzan). Pregunta al
   usuario si es una decisión de negocio.
4. Si la decisión cambia el modelo, **actualiza también** `data-model.md`/`plan.md`
   para que la spec siga siendo la fuente de verdad.

## Principios no negociables (constitución)

- **Multi-tenant:** toda consulta/escritura filtra por `empresaId`.
- **RBAC:** permisos por rol (unión de roles); usa `Permiso` y `Rol`.
- **Auditoría:** toda escritura relevante se registra en `_auditoria`.
- **Offline:** no romper la persistencia local de Firestore.
- **Documentación (Principio 11):** cada método/clase/función con comentarios en
  español (docstrings `///` en Dart, JSDoc en TS). Es parte del Definition of Done.

## Convenciones del código

- Sigue el patrón existente: **StatefulWidget + repositorios** (NO Riverpod).
- Estructura: `lib/features/<feature>/{data,domain,presentation}`.
- Reutiliza utilidades: `core/formato/fechas.dart` (fechas/valores),
  `core/imagen/medir_imagen.dart`, `core/firebase/errores.dart`.
- Reglas de Firestore **por perfil** (`perfil().empresaId`, `roles()`), no por
  *custom claims* (ver `app/firestore.rules`).

## Cierre

1. `flutter analyze` sin errores y `flutter test` (todo pasando).
2. Actualiza `tasks.md` (marca tareas), `spec.md` (estado y CA) y `README.md`.
3. Commit con `tipo(alcance): descripción` (ej. `feat(catalogo): ...`) y **push a
   `origin` (repo `ventas`)**.
4. Si tocaste reglas (`firestore.rules`/`storage.rules`), usa la skill
   **desplegar-reglas**.
5. Reinicia la app para que el usuario pruebe (ver skill **publicar**).
