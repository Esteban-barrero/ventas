# Especificación: Gestión de Empresas (Multi-Tenant)

- **ID:** 002 | **Carpeta:** `specs/002-gestion-empresas/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Permite al **Super Admin** crear, configurar y administrar las empresas (tenants) que usan el
aplicativo. Al crear una empresa se define su **licencia** (mensual o anual), se sube su **logo**
y el sistema crea automáticamente su **administrador** y sus **parámetros por defecto**.

Esta funcionalidad es la puerta de entrada del modelo de negocio: vender la aplicación a
múltiples empresas con datos totalmente separados.

## 2. Objetivo

- Incorporar nuevas empresas de forma rápida y controlada.
- Aislar por completo los datos de cada empresa (`empresaId`).
- Controlar la vigencia de cada licencia y el estado de cada empresa.
- Personalizar cada empresa con su logo y su tema.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Super Admin** | Crea, edita, suspende y elimina empresas. Define licencias y planes. Acceso global. |
| **Administrador de Empresa** | Gestiona su propia empresa: usuarios, parámetros, logo y tema. |
| Otros roles | No tienen acceso a la gestión de empresas. |

## 4. Historias de Usuario

- **Como** Super Admin, **quiero** crear una empresa **para** incorporar un nuevo cliente.
- **Como** Super Admin, **quiero** definir la licencia (tipo, inicio y fin) **para** controlar el cobro.
- **Como** Super Admin, **quiero** ver un tablero de empresas por vencer y vencidas **para** gestionar renovaciones.
- **Como** Super Admin, **quiero** suspender o reactivar una empresa **para** controlar su acceso.
- **Como** Administrador, **quiero** subir el logo de mi empresa **para** personalizar la app.
- **Como** Administrador, **quiero** ver que mi licencia está por vencer **para** renovarla a tiempo.

## 5. Requisitos Funcionales

- RF-01 Crear empresa con datos básicos: nombre, NIT, correo de notificación, contacto.
- RF-02 Definir la licencia: tipo (`gratis`, `mensual`, `anual`, `personalizado`), `fechaInicio`, `fechaFin`, `diasAvisoVencimiento` (por defecto 5).
- RF-03 Crear automáticamente el **usuario Administrador** de la empresa.
- RF-04 Crear automáticamente los **parámetros por defecto** (márgenes, costo de envío, tema).
- RF-05 Crear los **roles básicos** del sistema para la empresa.
- RF-06 Subir y actualizar el **logo** (recomendado 512x512 px, PNG, máx 500 KB).
- RF-07 Editar datos de la empresa.
- RF-08 Activar, suspender y reactivar empresas.
- RF-09 Renovar / extender la licencia (`fechaFin`).
- RF-10 Tablero con empresas: activas, por vencer, vencidas, suspendidas.
- RF-11 Definir límites por plan (usuarios, productos, almacenamiento).
- RF-12 Registrar el historial de pagos/renovaciones de cada empresa.
- RF-13 Enviar avisos de vencimiento por **correo** y por **notificación dentro de la app**.
- RF-14 Eliminar empresa (solo Super Admin, con confirmación y borrado lógico).

## 6. Reglas de Negocio

- RN-01 Cada documento del sistema lleva `empresaId`.
- RN-02 Una empresa no puede ver datos de otra empresa.
- RN-03 El Super Admin es el único que crea empresas.
- RN-04 Al crear la empresa el sistema genera su Administrador con credenciales temporales.
- RN-05 Si la licencia está `vencida` o la empresa `suspendida`, se bloquea el ingreso de todos sus usuarios.
- RN-06 El aviso de vencimiento se repite según `diasAvisoVencimiento` (por defecto 5, 3, 1 y el día del vencimiento).
- RN-07 El logo máximo 500 KB; 512x512 px recomendado.
- RN-08 La eliminación de empresa es lógica (no borra físicamente de inmediato).

## 7. Criterios de Aceptación

- [ ] CA-01 El Super Admin puede crear una empresa con licencia y logo.
- [ ] CA-02 Al crear la empresa se crea su Administrador automáticamente.
- [ ] CA-03 La empresa nueva queda con parámetros por defecto.
- [ ] CA-04 El Administrador puede subir su logo y verlo en login y facturas.
- [ ] CA-05 El Super Admin puede renovar/suspender/reactivar una empresa.
- [ ] CA-06 El tablero muestra empresas activas, por vencer y vencidas.
- [ ] CA-07 Los avisos de vencimiento llegan por correo y en la app.
- [ ] CA-08 Una empresa con licencia vencida bloquea el ingreso de sus usuarios.
- [ ] CA-09 Ninguna empresa puede ver datos de otra.

## 8. Datos Involucrados

- `empresas` (datos, licencia, logo, estado, parámetros, contacto del proveedor)
- `usuarios` (administrador de la empresa)
- `planes` (límites por plan)
- `roles` (roles básicos)
- `_auditoria` (cambios en empresas)
- Firebase Storage: `empresas/{empresaId}/logo.png`

## 9. Casos Borde / Errores

- NIT o nombre duplicado.
- Logo que excede el tamaño o resolución mínima.
- Fecha de fin anterior a la fecha de inicio.
- Empresa sin licencia definida.
- Fallo al crear el usuario administrador (reintento / estado "creación incompleta").

## 10. Fuera de Alcance

- Pasarela de pago en línea para renovaciones (se agrega después).
- Registro self-service de empresas (por ahora lo hace el Super Admin).

## 11. Dependencias

- Funcionalidad 001 (Autenticación y Roles) para crear el Administrador y sus claims.
