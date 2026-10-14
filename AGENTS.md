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
- **No subir secretos** (`.env`, `google-services.json`, `GoogleService-Info.plist`, llaves).
- **No romper el funcionamiento offline** (Firestore sincroniza al recuperar conexión).

---

## 5. Convenciones

- **Ramas:** `main` (producción), `develop` (desarrollo), `feature/<nombre>`.
- **Commits:** `tipo(alcance): descripción` (ej: `feat(auth): login multi-rol`).
- **Idioma:** identificadores en inglés, comentarios y documentación en **español**.
- **Estructura Flutter:** `lib/features/<feature>/{data,domain,presentation}`.
- **Tests:** cada funcionalidad debe incluir pruebas.

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
4. Ejecutar `flutter analyze` y `flutter test`.
5. Hacer commit y push.
6. Actualizar la documentación si aplica.
