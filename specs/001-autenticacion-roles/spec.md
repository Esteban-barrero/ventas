# Especificación: Autenticación y Roles

- **ID:** 001 | **Carpeta:** `specs/001-autenticacion-roles/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Define el inicio de sesión de usuarios, la gestión de roles (RBAC), el control por empresa
(multi-tenant) y el bloqueo por licencia vencida. Es la base de seguridad del aplicativo:
todas las demás funcionalidades dependen de que el usuario esté autenticado y autorizado.

## 2. Objetivo

Garantizar que:

- Solo usuarios registrados y con licencia vigente puedan ingresar.
- Cada usuario vea y opere **únicamente** los datos de su empresa.
- Los permisos se calculen como la **unión** de los roles del usuario.
- Un usuario pueda tener **múltiples roles** (ej: Administrador + Developer).

## 3. Actores / Roles

| Rol | Descripción |
|---|---|
| Super Admin | Acceso global. Crea empresas y sus administradores. |
| Administrador | Acceso total dentro de su empresa. Gestiona usuarios y roles. |
| Gerente | Reportes y aprobaciones de su empresa. |
| Vendedor | Ventas y clientes propios. |
| Marketing | Contenido del catálogo y promociones. |
| Cajero | Caja y cobros. |
| Cliente | Catálogo, carrito, pedidos e historial propios. |
| Invitado | Catálogo, carrito y pedidos sin registro. |
| Developer | Logs de errores. Se asigna además de otros roles. |

## 4. Historias de Usuario

- **Como** usuario, **quiero** iniciar sesión con correo y contraseña **para** acceder a mi empresa.
- **Como** Super Admin, **quiero** crear empresas y su administrador **para** incorporar clientes.
- **Como** Administrador, **quiero** crear usuarios y asignarles roles **para** organizar mi equipo.
- **Como** usuario con licencia vencida, **quiero** ver un mensaje claro **para** saber que debo renovar.
- **Como** usuario de una empresa, **quiero** que solo se me muestren mis datos **para** proteger la información.

## 5. Requisitos Funcionales

- RF-01 Inicio de sesión con correo/contraseña y Google Sign-In.
- RF-02 Cierre de sesión (logout) y recuperación de contraseña.
- RF-03 Registro de usuarios creado por el Administrador de la empresa.
- RF-04 Asignación de **uno o varios roles** por usuario.
- RF-05 Cálculo de permisos como **unión** de los roles asignados.
- RF-06 Ocultar formularios, opciones y datos a roles sin permiso.
- RF-07 Asociar cada usuario a una empresa (`empresaId`).
- RF-08 Validar la vigencia de la licencia de la empresa al iniciar sesión.
- RF-09 Bloquear el ingreso si la licencia está vencida o la empresa suspendida.
- RF-10 Crear automáticamente el Administrador al crear una empresa (Super Admin).
- RF-11 Registro de auditoría de cambios en usuarios y roles.

## 6. Reglas de Negocio

- RN-01 Un usuario pertenece a **una sola** empresa.
- RN-02 Los permisos efectivos = unión de permisos de todos sus roles.
- RN-03 El Administrador tiene acceso total dentro de su empresa.
- RN-04 El Super Admin no pertenece a ninguna empresa (acceso global).
- RN-05 Si la licencia está `vencida` o la empresa `suspendida`, se bloquea el ingreso de **todos** sus usuarios.
- RN-06 El aviso de vencimiento aparece cuando faltan los días configurados (`diasAvisoVencimiento`, por defecto 5).
- RN-07 El rol Developer no da acceso a datos del negocio, solo a logs de errores.

## 7. Criterios de Aceptación

- [ ] CA-01 El usuario puede iniciar sesión con correo/contraseña válidos.
- [ ] CA-02 Con credenciales inválidas se muestra un error claro y no se ingresa.
- [ ] CA-03 El usuario con licencia vencida es bloqueado y ve el contacto del proveedor.
- [ ] CA-04 Un usuario con varios roles obtiene la unión de sus permisos.
- [ ] CA-05 Un usuario no puede ver datos de otra empresa.
- [ ] CA-06 El Administrador puede crear un usuario y asignarle roles.
- [ ] CA-07 Los cambios en usuarios y roles quedan en la auditoría.
- [ ] CA-08 El Administrador de una empresa solo gestiona usuarios de SU empresa.

## 8. Datos Involucrados

- `empresas` (licencia, estado, `correoNotificacion`)
- `usuarios` (`empresaId`, `roles[]`, datos de perfil)
- `roles` (definición y permisos)
- `_auditoria` (registro de cambios)

## 9. Casos Borde / Errores

- Usuario sin empresa asignada.
- Usuario con rol inexistente.
- Licencia que vence mientras el usuario está conectado.
- Intento de acceso a datos de otra empresa (debe fallar en reglas).
- Pérdida de conexión durante el login (usar caché offline).

## 10. Fuera de Alcance

- Pasarela de pago para renovar licencias.
- Autenticación biométrica (se evaluará después).
- SSO empresarial.

## 11. Dependencias

- Funcionalidad 002 (Gestión de Empresas) para la creación de empresas y licencias.
