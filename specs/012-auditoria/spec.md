# Especificación: Auditoría

- **ID:** 012 | **Carpeta:** `specs/012-auditoria/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Registra de forma **automática e inmutable** todas las operaciones **INSERT / UPDATE / DELETE** de
las colecciones sensibles, con **quién, cuándo, dónde (colección), campo, valor anterior y valor
nuevo**. Se exige una **retención mínima de 6 meses**. Se implementa con **Cloud Functions
(triggers)** y solo la pueden consultar roles autorizados.

## 2. Objetivo

- Tener trazabilidad completa de los cambios de datos.
- Saber **quién** cambió **qué**, **cuándo** y **de qué valor a qué valor**.
- Cumplir con la retención mínima de **6 meses**.
- Facilitar investigaciones y revisiones internas.
- Que los registros **no se puedan alterar ni borrar**.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Super Admin** | Consulta toda la auditoría (todas las empresas). |
| **Administrador** | Consulta la auditoría de su empresa. |
| **Gerente** | Consulta la auditoría de su empresa. |
| **Auditor** (opcional) | Solo lectura de la auditoría. |
| **Sistema (Cloud Functions)** | Escribe los registros (nadie más escribe). |

## 4. Historias de Usuario

- **Como** Administrador, **quiero** ver quién cambió un precio **para** controlar el negocio.
- **Como** Gerente, **quiero** ver el historial de una venta **para** resolver una queja.
- **Como** Super Admin, **quiero** buscar por usuario y fecha **para** auditar una empresa.
- **Como** Auditor, **quiero** exportar los registros **para** una revisión externa.

## 5. Requisitos Funcionales

- RF-01 Registrar **INSERT** (creación) con sus valores.
- RF-02 Registrar **UPDATE** con **campo, valor anterior y valor nuevo**.
- RF-03 Registrar **DELETE** con los valores eliminados.
- RF-04 Guardar por registro: **usuario** (uid y nombre), **fecha/hora**, **colección**, **documentoId**, **campos**, **valores anteriores/nuevos**, **operación**, **empresaId**, **IP/origen** (si está disponible).
- RF-05 **Retención mínima de 6 meses** (configurable, nunca menor).
- RF-06 **Registros inmutables** (no se pueden editar ni borrar desde la app).
- RF-07 **Consulta con filtros:** empresa, usuario, colección, operación, rango de fechas, documentoId.
- RF-08 **Búsqueda** por palabra/frase.
- RF-09 **Exportación** (CSV/Excel/PDF) de los resultados.
- RF-10 Cobertura automática de todas las colecciones sensibles (según lista configurable).
- RF-11 Registro de la propia consulta de auditoría (meta-auditoría), opcional.

## 6. Reglas de Negocio

- RN-01 Los registros de auditoría **solo se crean** (nunca por el cliente).
- RN-02 Los registros son **inmutables**: no hay update ni delete permitidos.
- RN-03 La retención es de **mínimo 6 meses**; se puede configurar más, nunca menos.
- RN-04 Cada registro pertenece a una empresa (`empresaId`), salvo operaciones de Super Admin.
- RN-05 El usuario se toma desautenticado (`request.auth`) en la Cloud Function.
- RN-06 Las colecciones auditadas se definen en una **lista configurable**.
- RN-07 La auditoría **no guarda** datos sensibles en claro si la empresa así lo exige (se enmascaran ciertos campos).
- RN-08 La consulta respeta el aislamiento multi-tenant (cada quien ve lo suyo).

## 7. Criterios de Aceptación

- [ ] CA-01 Un INSERT genera su registro de auditoría.
- [ ] CA-02 Un UPDATE registra el campo con valor anterior y nuevo.
- [ ] CA-03 Un DELETE guarda los valores eliminados.
- [ ] CA-04 Cada registro indica **quién** y **cuándo**.
- [ ] CA-05 Los registros no se pueden editar ni borrar.
- [ ] CA-06 La retención no baja de 6 meses.
- [ ] CA-07 Se puede filtrar por usuario, colección, operación y fecha.
- [ ] CA-08 Se puede exportar el resultado.

## 8. Datos Involucrados

- `_auditoria` (colección principal, inmutable)
- Colecciones auditadas (ventas, productos, clientes, etc.)
- `_auditoria_config` (colecciones auditadas y política de retención)

## 9. Casos Borde / Errores

- Operación hecha fuera de la Cloud Function (escritura directa) → reglas que lo impiden.
- Cambios masivos (batch) → generar un registro por documento.
- Campos muy grandes (arrays/objetos) → truncar o guardar hash.
- Falta de `request.auth` (tareas del sistema) → marcar como `sistema`.
- Volumen alto → usar subcolecciones/particiones y TTL de 6+ meses.

## 10. Fuera de Alcance

- Reconstrucción automática de datos a partir de la auditoría (se evalúa después).
- Firma criptográfica de los registros (posible mejora).
- Alertas en tiempo real por cambios sospechosos (fase posterior).

## 11. Dependencias

- Todas las specs de datos (001 Autenticación/Roles, 002 Empresas, 003 Catálogo, 004 Clientes, 005 Ventas, 006 Créditos, 007 Compras, 008 Inventario, 009 Caja, 010 Pedidos, 011 Envíos).
- 001 Autenticación (identidad del usuario).
- 014 Parámetros (política de retención y colecciones auditadas).
