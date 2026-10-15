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
- [x] T014 Cachear permisos y sesión para uso offline

## Fase 3 — Interfaz de Usuario

- [x] T020 Pantalla de login (correo/contraseña + Google)
- [x] T021 Pantalla de recuperación de contraseña
- [x] T022 Pantalla de "Licencia vencida" con datos de contacto del proveedor
- [x] T023 Guardas de navegación según permisos

## Fase 4 — Seguridad y Auditoría

- [x] T030 Definir reglas de Firestore por rol y `empresaId`
- [x] T031 Cloud Function `validarLicencia` — desplegada en us-central1
- [x] T032 Cloud Function (trigger) para claims `empresaId` y `roles` —
      `onUsuarioEscrito`, desplegada en southamerica-east1 y verificada
- [x] T033 Registrar auditoría en cambios de usuario y roles

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de permisos y licencia
- [x] T041 Pruebas de widget de login y licencia vencida
- [x] T042 Ejecutar `flutter analyze` y `flutter test`
- [x] T043 Actualizar documentación

## Fase 6 — Gestión de Usuarios (CA-06)

- [x] T050 Cloud Function `crearUsuario` (Admin SDK) — desplegada en us-central1.
      Fuerza el `empresaId` del llamante, impide asignar `superadmin` y aplica el
      límite de usuarios del plan (RF-11).
- [x] T051 Repositorio y respaldo local: `UsuariosRepository.crear`,
      `escucharDeEmpresa`/`escucharTodos`, `actualizarRoles`, `actualizarActivo`,
      `actualizarDatos`; `CreadorUsuarioLocal` con instancia secundaria (ADR-004).
- [x] T052 Pantallas `usuarios_list_screen.dart` y `usuario_form_screen.dart`
      (módulo "Usuarios" en el inicio) + reglas de Firestore para que el
      Administrador cree usuarios de su empresa (nunca `superadmin`).
- [x] T053 Pruebas (dominio y widget) y verificación E2E de `crearUsuario`.

---

## Criterio de Terminado (Definition of Done)

- [x] Todos los criterios de aceptación de `spec.md` cumplidos
      *(CA-01 a CA-08, incluida CA-06)*
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando (120)
- [x] RBAC y auditoría verificados
- [x] Commit y push realizados

### Pendiente fuera de esta spec

- [ ] Envío automático de correos de activación/vencimiento (extensión
      *Trigger Email from Firestore*).
- [x] T031 / T032 Cloud Functions desplegadas y verificadas (plan **Blaze** activo).
