# Modelo de Datos: Autenticación y Roles

- **ID:** 001 | **Fecha:** 2026-10-14

---

## `empresas/{empresaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador de la empresa |
| nombre | string | Nombre de la empresa |
| nit | string | NIT / RIF |
| correoNotificacion | string | Correo para avisos de licencia |
| logo | string | Ruta en Storage (`empresas/{id}/logo.png`) |
| logoAncho | number | Ancho del logo en px |
| logoAlto | number | Alto del logo en px |
| adminId | string | UID del administrador |
| estado | string | `activa` \| `suspendida` \| `prueba` |
| fechaCreacion | timestamp | Fecha de creación |
| contactoProveedor | string | Contacto del proveedor del aplicativo |
| licencia | map | Ver abajo |
| parametros | map | Márgenes, costo de envío, tema |

### `licencia` (map)

| Campo | Tipo | Descripción |
|---|---|---|
| tipo | string | `mensual` \| `anual` \| `gratis` \| `personalizado` |
| fechaInicio | timestamp | Inicio del plan |
| fechaFin | timestamp | Vencimiento del plan |
| estado | string | `activa` \| `por_vencer` \| `vencida` \| `suspendida` \| `prueba` |
| diasAvisoVencimiento | number | Días de aviso (por defecto 5) |
| valorPagado | number | Valor de la licencia |
| historialPagos | array | Renovaciones (fecha, valor, periodo) |

---

## `usuarios/{uid}`

| Campo | Tipo | Descripción |
|---|---|---|
| uid | string | UID de Firebase Auth |
| nombre | string | Nombre completo |
| email | string | Correo |
| telefono | string | Teléfono |
| empresaId | string | Empresa a la que pertenece (null para Super Admin) |
| roles | array&lt;string&gt; | Lista de roles asignados |
| activo | boolean | Si puede ingresar |
| fechaCreacion | timestamp | Fecha de creación (se persiste como ISO-8601) |
| creadoPor | string | UID de quien creó el usuario (opcional) |

---

## `roles/{rolId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del rol |
| nombre | string | Nombre visible |
| descripcion | string | Descripción |
| permisos | array&lt;string&gt; | Códigos de permiso |
| esSistema | boolean | Si es un rol fijo del sistema |

---

## `_auditoria/{autoId}`

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa del cambio |
| usuario | string | UID/correo del autor |
| fecha | timestamp | Fecha/hora (ISO 8601) |
| operacion | string | INSERT \| UPDATE \| DELETE |
| tabla | string | Colección afectada |
| documentoId | string | Documento afectado |
| campo | string | Campo modificado |
| valorViejo | any | Valor anterior |
| valorNuevo | any | Valor nuevo |

---

## Índices sugeridos

- `usuarios`: `empresaId` + `rol`
- `_auditoria`: `empresaId` + `fecha` (desc)
