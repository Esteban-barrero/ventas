# Tareas: Autenticación y Roles

- **ID:** 001 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/auth`
- [x] T002 Definir entidades `Usuario`, `Rol` y `Permiso`
- [x] T003 Configurar Firebase (proyecto, Authentication, Firestore)

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar `AuthRepository` (login, logout, recuperar contraseña)
- [x] T011 Implementar cálculo de permisos (unión de roles) en `domain`
- [x] T012 Implementar validación de licencia (llamada a Cloud Function)
- [x] T013 Implementar Google Sign-In
- [ ] T014 Cachear permisos y sesión para uso offline

## Fase 3 — Interfaz de Usuario

- [x] T020 Pantalla de login (correo/contraseña + Google)
- [x] T021 Pantalla de recuperación de contraseña
- [x] T022 Pantalla de "Licencia vencida" con datos de contacto del proveedor
- [ ] T023 Guardas de navegación según permisos

## Fase 4 — Seguridad y Auditoría

- [ ] T030 Definir reglas de Firestore por rol y `empresaId`
- [ ] T031 Cloud Function `validarLicencia`
- [ ] T032 Cloud Function (trigger) para claims `empresaId` y `roles`
- [ ] T033 Registrar auditoría en cambios de usuario y roles

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de permisos y licencia
- [x] T041 Pruebas de widget de login y licencia vencida
- [x] T042 Ejecutar `flutter analyze` y `flutter test`
- [ ] T043 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] RBAC y auditoría verificados
- [ ] Commit y push realizados
