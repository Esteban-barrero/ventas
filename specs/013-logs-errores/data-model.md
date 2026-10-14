# Modelo de Datos: Logs de Errores

- **ID:** 013 | **Fecha:** 2026-10-14

---

## `logs_errores/{logId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del log |
| empresaId | string | Empresa (`sistema` si global) |
| modulo | string | Módulo donde ocurrió (ej: `ventas`) |
| opcion | string | Opción del menú (ej: "Nueva venta") |
| accion | string | Acción ejecutada (ej: "Guardar") |
| usuarioUid | string | Quién lo provocó (`anonimo` si sin sesión) |
| usuarioNombre | string | Nombre del usuario |
| usuarioRol | string | Rol del usuario |
| fecha | timestamp | Fecha y hora del error |
| archivo | string | Archivo fuente |
| linea | number | Línea del código |
| codigo | string | Código/tipo de error (ej: `NullCheckError`) |
| descripcion | string | Mensaje del error |
| stackTrace | string | Traza completa |
| severidad | string | `info` \| `warning` \| `error` \| `fatal` |
| plataforma | string | `android` \| `ios` \| `web` |
| appVersion | string | Versión de la app |
| osVersion | string | Versión del sistema |
| huella | string | Hash para agrupar errores iguales |
| ocurrencias | number | Veces que se ha repetido |
| estado | string | `nuevo` \| `reconocido` \| `resuelto` |
| resueltoPor | string | UID de quien lo resolvió |
| fechaResolucion | timestamp | Fecha de resolución |
| contexto | map | Datos extra (params, pantalla, etc.) |
| expiraEn | timestamp | Fecha para TTL (retención) |

---

## Ejemplo de log

```json
{
  "empresaId": "empresa_001",
  "modulo": "ventas",
  "opcion": "Nueva venta",
  "accion": "Guardar",
  "usuarioUid": "uid_vend_01",
  "usuarioNombre": "Juan Perez",
  "usuarioRol": "vendedor",
  "fecha": "2026-10-14T16:40:00Z",
  "archivo": "lib/features/ventas/data/ventas_repository.dart",
  "linea": 142,
  "codigo": "StockInsuficienteException",
  "descripcion": "Stock insuficiente para el producto PROD-001",
  "stackTrace": "#0 VentasRepository.registrar (ventas_repository.dart:142)\n#1 ...",
  "severidad": "error",
  "plataforma": "android",
  "appVersion": "1.0.0+3",
  "osVersion": "Android 14",
  "huella": "6f3a9c2b",
  "ocurrencias": 1,
  "estado": "nuevo"
}
```

---

## Severidades

| Severidad | Significado |
|---|---|
| `info` | Informativo, sin impacto |
| `warning` | Advertencia, puede continuar |
| `error` | Error que afectó una operación |
| `fatal` | Error que tumbó la app/flujo |

---

## Huella (fingerprint)

```
huella = hash(codigo + "|" + archivo + "|" + linea)
```

Si ya existe un log con la misma huella, se incrementa `ocurrencias` y se actualiza la fecha del
último evento (según configuración).

---

## Retención

```
expiraEn = fecha + mesesRetencion   // por defecto 6 meses
```

---

## Índices sugeridos

- `logs_errores`: `empresaId` + `fecha` (desc)
- `logs_errores`: `empresaId` + `severidad` + `fecha` (desc)
- `logs_errores`: `empresaId` + `modulo` + `fecha` (desc)
- `logs_errores`: `empresaId` + `huella`
- `logs_errores`: `estado` + `fecha` (desc)
