# Especificación: Clientes

- **ID:** 004 | **Carpeta:** `specs/004-clientes/`
- **Fecha:** 2026-10-14
- **Estado:** Implementado (núcleo)
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Gestiona los clientes de cada empresa: datos personales, **dirección completa**
(departamento, ciudad, dirección y barrio), **ubicación GPS tipo WhatsApp** y su historial
de compras, pedidos y créditos. Los clientes registrados tienen su propio rol y pueden ver
sus compras y el estado de sus pedidos.

## 2. Objetivo

- Registrar clientes con datos válidos y obligatorios.
- Capturar la dirección completa para entregas locales y envíos.
- Guardar la ubicación GPS para facilitar las entregas y abrirla en Google Maps o Waze.
- Dar al cliente acceso a su historial (compras, pedidos y estados).

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Administrador** | CRUD completo de clientes. |
| **Vendedor** | Crea y edita clientes, consulta su historial. |
| **Cajero** | Consulta clientes para cobros. |
| **Gerente** | Consulta y aprueba créditos. |
| **Cliente** | Ve y edita sus propios datos, dirección y ubicación GPS; ve su historial. |

## 4. Historias de Usuario

- **Como** Vendedor, **quiero** registrar un cliente con sus datos y dirección **para** venderle.
- **Como** Vendedor, **quiero** guardar la ubicación GPS del cliente **para** llegar más fácil.
- **Como** Cliente, **quiero** ver mis compras y el estado de mis pedidos **para** hacer seguimiento.
- **Como** Cliente, **quiero** actualizar mi dirección y ubicación **para** que me encuentren.
- **Como** Administrador, **quiero** clasificar clientes como detal o mayorista **para** dar precios correctos.
- **Como** Administrador, **quiero** marcar clientes como morosos **para** controlar el crédito.

## 5. Requisitos Funcionales

- RF-01 Crear cliente con **campos obligatorios**: nombre completo, cédula, teléfono y dirección.
- RF-02 Dirección completa: **departamento** (selector), **ciudad** (selector filtrado), **dirección** y **barrio**.
- RF-03 Campos opcionales: correo, nombre de contacto, teléfono alternativo, observaciones.
- RF-04 **Ubicación GPS** (tipo WhatsApp): latitud, longitud y dirección aproximada.
- RF-05 Abrir la ubicación en **Google Maps** o **Waze**.
- RF-06 Clasificación: cliente **detal** o **mayorista**.
- RF-07 Historial de compras por cliente.
- RF-08 Historial de pedidos y su estado.
- RF-09 Estado del cliente: activo, inactivo, moroso.
- RF-10 Asignación de crédito (límite y saldo).
- RF-11 Rol **Cliente** con acceso a su información e historial.
- RF-12 Validación de unicidad de cédula por empresa.
- RF-13 Registro de auditoría de cambios.

## 6. Reglas de Negocio

- RN-01 Obligatorios: nombre completo, cédula, teléfono y dirección (departamento, ciudad, dirección).
- RN-02 La cédula debe ser única por empresa.
- RN-03 El teléfono debe tener formato válido.
- RN-04 La ciudad se filtra según el departamento seleccionado.
- RN-05 Todo cliente pertenece a una empresa (`empresaId`).
- RN-06 Un cliente solo ve su propia información e historial.
- RN-07 La ubicación GPS es opcional, pero se recomienda para entregas locales.
- RN-08 Los clientes no se eliminan físicamente (`activo = false`).

## 7. Criterios de Aceptación

- [x] CA-01 Se puede crear un cliente con los campos obligatorios.
- [x] CA-02 No se permite una cédula duplicada en la misma empresa.
- [x] CA-03 El selector de ciudad se filtra por departamento.
- [x] CA-04 Se puede capturar y guardar la ubicación GPS.
- [x] CA-05 Al hacer clic en la ubicación se abre en Google Maps o Waze.
- [ ] CA-06 El cliente puede ver su historial de compras y pedidos. *(depende de las specs 005 y 010)*
- [x] CA-07 El cliente puede actualizar su dirección y ubicación.
- [x] CA-08 Un cliente no ve datos de otros clientes ni de otra empresa.
- [x] CA-09 El historial y los cambios quedan auditados.

## 8. Datos Involucrados

- `clientes` (datos, dirección, GPS, clasificación, estado, crédito)
- `departamentos` / `ciudades` (catálogo de ubicaciones)
- `_auditoria`

## 9. Casos Borde / Errores

- Cédula duplicada.
- Teléfono con formato inválido.
- Ciudad sin departamento seleccionado.
- Ubicación GPS sin permisos del dispositivo.
- Cliente sin historial (estado vacío).
- Cédula extranjera o tipo de documento distinto (evaluar).

## 10. Fuera de Alcance

- Validación en línea contra registros oficiales (RUES/DIAN).
- Multi-dirección por cliente (se evalúa después).
- Segmentación y campañas de marketing.

## 11. Dependencias

- Funcionalidad 002 (Gestión de Empresas) para `empresaId` y parámetros.
- Funcionalidad 001 (Autenticación) para el rol Cliente.
- Funcionalidades de Ventas, Pedidos y Créditos (historial).
