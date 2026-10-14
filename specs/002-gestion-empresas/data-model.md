# Modelo de Datos: Gestión de Empresas

- **ID:** 002 | **Fecha:** 2026-10-14

---

## `empresas/{empresaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador de la empresa |
| nombre | string | Nombre / razón social |
| nit | string | NIT / RIF (único) |
| correoNotificacion | string | Correo para avisos de licencia |
| telefono | string | Teléfono de contacto |
| contactoProveedor | string | Contacto de quien vendió el aplicativo |
| logo | string | Ruta en Storage |
| logoAncho | number | Ancho del logo (px) |
| logoAlto | number | Alto del logo (px) |
| adminId | string | UID del administrador |
| estado | string | `activa` \| `suspendida` \| `prueba` \| `eliminada` \| `creacion_incompleta` |
| fechaCreacion | timestamp | Fecha de creación |
| creadaPor | string | UID del Super Admin |
| plan | string | id del plan (`planId`) |
| licencia | map | Ver abajo |
| parametros | map | márgenes, costo de envío, tema |
| limites | map | usuarios, productos, almacenamiento |

### `licencia` (map)

| Campo | Tipo | Descripción |
|---|---|---|
| tipo | string | `gratis` \| `mensual` \| `anual` \| `personalizado` |
| fechaInicio | timestamp | Inicio del plan |
| fechaFin | timestamp | Vencimiento |
| estado | string | `activa` \| `por_vencer` \| `vencida` \| `suspendida` \| `prueba` |
| diasAvisoVencimiento | number | Días de aviso (por defecto 5) |
| valorPagado | number | Valor de la licencia |
| historialPagos | array | [{fecha, valor, periodoInicio, periodoFin, nota}] |

---

## `planes/{planId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del plan |
| nombre | string | Nombre (Gratis, Básico, Premium) |
| periodicidad | string | `mensual` \| `anual` \| `gratis` |
| valor | number | Precio del plan |
| limites | map | `maxUsuarios`, `maxProductos`, `maxAlmacenamientoMB` |
| activo | boolean | Si está disponible |

---

## `usuarios/{uid}` (relación)

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa a la que pertenece |
| roles | array | Incluye `administrador` para el admin de la empresa |

---

## `notificaciones/{autoId}` (avisos in-app)

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa destino |
| tipo | string | `licencia_por_vencer` \| `licencia_vencida` |
| mensaje | string | Texto del aviso |
| leida | boolean | Si fue leída |
| fecha | timestamp | Fecha de creación |

---

## Índices sugeridos

- `empresas`: `nit` (único), `licencia.fechaFin` (asc), `estado`
- `notificaciones`: `empresaId` + `leida` + `fecha` (desc)
