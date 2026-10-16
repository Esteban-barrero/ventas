# AGENTS.md — Guía para Agentes de IA

Este repositorio se desarrolla con la metodología **SDD (Spec-Driven Development)**.
Lee este archivo completo **antes** de generar cualquier código.

---

## 1. Descripción del proyecto

Aplicativo de ventas multiplataforma (Android, iOS y Web) en **Flutter + Firebase**,
con arquitectura **multi-tenant** (múltiples empresas en una sola aplicación).

La documentación de requerimientos está en:
`Documentacion/aplicativo ventas.docx`

---

## 2. Fuente de verdad (en orden de prioridad)

1. `.specify/memory/constitution.md` — principios no negociables
2. `specs/<n>-<nombre>/spec.md` — especificación de la funcionalidad
3. `specs/<n>-<nombre>/plan.md` — plan técnico
4. `specs/<n>-<nombre>/tasks.md` — tareas
5. `Documentacion/aplicativo ventas.docx` — levantamiento de requerimientos

> **Nunca implementes sin `spec.md` y `plan.md` aprobados.**

---

## 3. Stack tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | Flutter (Dart) |
| Base de datos | Firebase Firestore |
| Autenticación | Firebase Authentication |
| Archivos | Firebase Storage |
| Lógica de servidor | Cloud Functions (Node.js / TypeScript) |

---

## 4. Reglas no negociables

- **Multi-tenant:** TODA consulta y escritura debe filtrar por `empresaId`.
- **RBAC:** validar permisos por rol. Un usuario puede tener varios roles; los permisos efectivos son la **UNIÓN**.
- **Auditoría:** toda escritura (INSERT/UPDATE/DELETE) debe quedar registrada en `_auditoria`.
- **Licencias:** si la licencia de la empresa está vencida, se bloquea el ingreso.
- **No subir secretos** (`.env`, llaves privadas, `serviceAccountKey.json`).
  - **Excepción documentada:** `google-services.json` y `firebase_options.dart`
    **sí** se versionan. Son identificadores públicos del cliente (apiKey,
    appId, projectId) y el plugin de Gradle de Android requiere el primero para
    compilar. La seguridad real está en las reglas de Firestore/Storage y en
    Authentication. Ver la nota en `.gitignore` y en el `README.md`.
- **No romper el funcionamiento offline** (Firestore sincroniza al recuperar conexión).
- **Documentación del código (constitución, Principio 11):** todo método
  (público o privado), clase, función y campo relevante debe quedar
  **comentado** con claridad y en **español**, indicando qué hace, sus
  parámetros, su valor de retorno y la spec/RF/RN/ADR que lo respalda. En Dart
  se usan docstrings `///` en las APIs públicas y comentarios inline `//` en los
  métodos privados; en TypeScript, JSDoc `/** ... */`. Ninguna tarea se considera
  terminada sin la documentación del código.

---

## 5. Convenciones

- **Ramas:** `main` (producción), `develop` (desarrollo), `feature/<nombre>`.
- **Commits:** `tipo(alcance): descripción` (ej: `feat(auth): login multi-rol`).
- **Idioma:** identificadores en inglés, comentarios y documentación en **español**.
- **Estructura Flutter:** `lib/features/<feature>/{data,domain,presentation}`.
- **Tests:** cada funcionalidad debe incluir pruebas.
- **Documentación del código:** cada método y clase se comenta en español
  (Principio 11); es parte del Definition of Done.

---

## 6. Comandos útiles

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter build apk
```

---

## 7. Flujo de trabajo (SDD)

1. Leer `spec.md` y `plan.md` de la funcionalidad.
2. Implementar **tarea por tarea** de `tasks.md`.
3. Marcar cada tarea como completada.
4. **Documentar** cada método y clase en español (Principio 11).
5. Ejecutar `flutter analyze` y `flutter test`.
6. Hacer commit y push.
7. Actualizar la documentación si aplica.

---

## 8. Skills del proyecto

Las guías operativas viven en `.opencode/skills/` y se cargan cuando hacen
falta (no ocupan contexto todo el tiempo):

| Skill | Para qué |
|---|---|
| `implementar-spec` | Flujo SDD completo (implementar, documentar, probar, commit/push) |
| `desplegar-reglas` | Desplegar reglas de Firestore/Storage por la API (sin Firebase CLI) |
| `contexto-proyecto` | Repos, Firebase, empresa demo, Super Admin y convenciones |
| `respaldo-datos` | Export/import de Firestore (+ Auth y Storage) |
| `publicar` | `analyze` + `test` + commit + push + reiniciar la app |
| `validar-correo` | Usar `esCorreoValido` (`core/validacion/correo.dart`) |
| `formato-fechas` | Usar `core/formato/fechas.dart` (no `intl`) |
