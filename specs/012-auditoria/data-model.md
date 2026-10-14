# Modelo de Datos: Auditoría

- **ID:** 012 | **Fecha:** 2026-10-14

---

## `_auditoria/{registroId}` (inmutable)

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del registro |
| empresaId | string | Empresa afectada (`sistema` si global) |
| operacion | string | `INSERT` \| `UPDATE` \| `DELETE` |
| coleccion | string | Colección afectada |
| documentoId | string | Documento afectado |
| usuarioUid | string | Quién hizo el cambio |
| usuarioNombre | string | Nombre del usuario |
| usuarioEmail | string | Correo del usuario |
| origen | string | `app` \| `cloud_function` \| `sistema` |
| fecha | timestamp | Fecha y hora exactas |
| cambios | array | Ver abajo (UPDATE) |
| valoresAnteriores | map | Snapshot previo (UPDATE/DELETE) |
| valoresNuevos | map | Snapshot nuevo (INSERT/UPDATE) |
| ip | string | IP/origen (si está disponible) |
| expiraEn | timestamp | Fecha para la política TTL (>= 6 meses) |

### `cambios[]` (array embebido, para UPDATE)

| Campo | Tipo | Descripción |
|---|---|---|
| campo | string | Nombre del campo |
| valorAnterior | any | Valor antes del cambio |
| valorNuevo | any | Valor después del cambio |

---

## `_auditoria_config/{empresaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa |
| coleccionesAuditadas | array | Lista de colecciones a auditar |
| camposEnmascarados | array | Campos que no se guardan en claro |
| mesesRetencion | number | Meses de retención (mínimo 6) |
| auditarLecturas | boolean | Si se auditan consultas (meta-auditoría) |

---

## Ejemplo de registro (UPDATE)

```json
{
  "empresaId": "empresa_001",
  "operacion": "UPDATE",
  "coleccion": "productos",
  "documentoId": "P001",
  "usuarioUid": "uid_admin_01",
  "usuarioNombre": "Ana Gomez",
  "usuarioEmail": "ana@empresa.com",
  "origen": "app",
  "fecha": "2026-10-14T16:20:00Z",
  "cambios": [
    { "campo": "precioDetal", "valorAnterior": 30000, "valorNuevo": 32000 },
    { "campo": "stockMinimo",  "valorAnterior": 5,     "valorNuevo": 10 }
  ],
  "expiraEn": "2027-04-14T16:20:00Z"
}
```

## Ejemplo de registro (DELETE)

```json
{
  "empresaId": "empresa_001",
  "operacion": "DELETE",
  "coleccion": "clientes",
  "documentoId": "cliente_045",
  "usuarioUid": "uid_admin_01",
  "usuarioNombre": "Ana Gomez",
  "origen": "app",
  "fecha": "2026-10-14T16:25:00Z",
  "valoresAnteriores": {
    "nombre": "Pedro Perez",
    "cedula": "79845612",
    "telefono": "3105556677"
  },
  "expiraEn": "2027-04-14T16:25:00Z"
}
```

---

## Cálculo de diferencias

```
cambios = []
para cada campo en valoresNuevos:
    antes  = valoresAnteriores[campo]
    despues = valoresNuevos[campo]
    si antes != despues:
        cambios.push({ campo, valorAnterior: antes, valorNuevo: despues })
```

---

## Retención (TTL)

```
mesesRetencion = max(6, config.mesesRetencion)
expiraEn       = fecha + mesesRetencion
```

> Firestore borra automáticamente los documentos al pasar `expiraEn`. El mínimo siempre es 6 meses.

---

## Índices sugeridos

- `_auditoria`: `empresaId` + `fecha` (desc)
- `_auditoria`: `empresaId` + `coleccion` + `fecha` (desc)
- `_auditoria`: `empresaId` + `usuarioUid` + `fecha` (desc)
- `_auditoria`: `empresaId` + `operacion` + `fecha` (desc)
- `_auditoria`: `empresaId` + `documentoId`
