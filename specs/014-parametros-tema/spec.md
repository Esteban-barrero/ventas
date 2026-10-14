# Especificación: Parámetros Generales y Tema

- **ID:** 014 | **Carpeta:** `specs/014-parametros-tema/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Administra la **configuración general** de cada empresa: **paletas de colores** y **tema**,
**logo** con tamaño en píxeles, **licencia** (fecha inicio/fin y bloqueo por vencimiento),
**avisos de vencimiento** (correo e in-app con días configurables) y demás **parámetros**
(moneda, impuestos, interés, días de mora, canales de notificación).

## 2. Objetivo

- Personalizar la apariencia por empresa (colores, logo) **en tiempo real**.
- Controlar la **licencia** y bloquear el ingreso al vencer.
- **Avisar** al cliente antes del vencimiento.
- Centralizar los **parámetros** que usan los demás módulos.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Super Admin / Proveedor** | Crea empresas, asigna licencia y paletas base. |
| **Administrador de empresa** | Configura tema, paletas, logo y parámetros de su empresa. |
| **Gerente** | Consulta parámetros; puede sugerir cambios. |
| **Usuario final** | Ve el tema aplicado (no lo edita, salvo preferencias). |

## 4. Historias de Usuario

- **Como** Administrador, **quiero** elegir una **paleta de colores** **para** que la app se vea de mi marca.
- **Como** Administrador, **quiero** **crear/editar/duplicar/eliminar** paletas.
- **Como** Administrador, **quiero** subir mi **logo** con un **tamaño en píxeles** **para** que se vea bien en móvil y web.
- **Como** Super Admin, **quiero** asignar la **licencia** (inicio/fin) **para** controlar el servicio.
- **Como** Administrador, **quiero** recibir un **aviso** antes de que venza la licencia.

## 5. Requisitos Funcionales

- RF-01 **Paletas de colores** por empresa: crear, editar, **duplicar** y **eliminar**.
- RF-02 **Aplicar el tema en tiempo real** al guardar (sin reiniciar).
- RF-03 Paleta activa por empresa; modo claro/oscuro.
- RF-04 **Logo de la empresa** con **tamaño en píxeles** configurable (ej. 512×512).
- RF-05 Validación de logo: formato **PNG/JPG**, peso máximo (ej. 500 KB), dimensiones.
- RF-06 **Licencia** con **fecha de inicio y fin** (mensual o anual).
- RF-07 **Bloqueo de ingreso** al vencer la licencia, con **mensaje** y **contacto del proveedor**.
- RF-08 **Aviso de vencimiento** por **correo** y **dentro de la app**.
- RF-09 Días de aviso configurables (`diasAvisoVencimiento`, por defecto **5**).
- RF-10 **Parámetros generales:** moneda, impuestos, tasa de interés, días de mora, costo de envío por defecto.
- RF-11 **Canales de notificación:** WhatsApp, Telegram (teléfono, token/chatId).
- RF-12 Nombre, datos y **contacto** de la empresa.
- RF-13 Registro de auditoría de los cambios.

## 6. Reglas de Negocio

- RN-01 Cada empresa tiene **sus** parámetros (`empresaId`).
- RN-02 Las **paletas base** las define el proveedor; cada empresa puede modificarlas.
- RN-03 El **tema se aplica en tiempo real** al guardar la paleta activa.
- RN-04 Al **vencer** la licencia se **bloquea el ingreso** y se muestra el contacto del proveedor.
- RN-05 El **aviso** se envía a `diasAvisoVencimiento` días del fin (por defecto 5).
- RN-06 El **logo** debe cumplir formato y tamaño; si no, se rechaza con mensaje.
- RN-07 Las paletas incluyen: primario, secundario, acento, fondo, texto, éxito, advertencia, error.
- RN-08 Los cambios de parámetros quedan **auditados**.

## 7. Criterios de Aceptación

- [ ] CA-01 Se crean, editan, duplican y eliminan paletas.
- [ ] CA-02 El tema cambia **en tiempo real** al aplicar una paleta.
- [ ] CA-03 Se sube el logo validando formato, peso y tamaño.
- [ ] CA-04 La licencia guarda fecha inicio/fin (mensual/anual).
- [ ] CA-05 Al vencer, se bloquea el ingreso con mensaje y contacto.
- [ ] CA-06 Se envía el aviso por **correo** y **en la app** con los días configurados.
- [ ] CA-07 Los parámetros generales se usan en los demás módulos.
- [ ] CA-08 Todo cambio queda auditado.

## 8. Datos Involucrados

- `parametros/{empresaId}` (parámetros generales)
- `paletas` (paletas de colores)
- `licencias` (inicio/fin, plan, estado)
- Firebase Storage: logos (`empresas/{empresaId}/logo.png`)
- `_auditoria`

## 9. Casos Borde / Errores

- Logo muy pesado o en formato no permitido.
- Paleta con contraste insuficiente (accesibilidad) → advertencia.
- Licencia vencida a mitad de sesión → cerrar sesión y mostrar mensaje.
- Cambio de paleta mientras otro usuario la usa → sincronización en tiempo real.
- Aviso ya enviado (no repetir el mismo día).
- Zona horaria para calcular el vencimiento.

## 10. Fuera de Alcance

- Temas creados por el usuario final (personalización individual).
- Facturación de la licencia (solo el control).
- Tienda de plantillas / marketplace de temas.

## 11. Dependencias

- 001 Autenticación y Roles (bloqueo por licencia, rol Developer).
- 002 Gestión de Empresas (creación de empresa y licencia).
- Todos los módulos (usan estos parámetros).
- 003 Catálogo (impuestos, moneda, márgenes por defecto).
- 006 Créditos (tasa de interés, días de mora).
- 010 Pedidos y 011 Envíos (canales de notificación).
