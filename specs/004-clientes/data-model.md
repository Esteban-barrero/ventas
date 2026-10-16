# Modelo de Datos: Clientes

- **ID:** 004 | **Fecha:** 2026-10-14

---

## `clientes/{clienteId}`

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| id | string | Sí | Identificador del cliente |
| empresaId | string | Sí | Empresa propietaria |
| uid | string | No | UID de Auth (si el cliente tiene cuenta) |
| nombreCompleto | string | **Sí** | Nombre completo |
| cedula | string | **Sí** | Documento (único por empresa) |
| tipoDocumento | string | No | CC, NIT, CE, Pasaporte |
| telefono | string | **Sí** | Teléfono principal |
| correo | string | No | Correo electrónico |
| contacto | string | No | Persona de contacto en la dirección (quién recibe) |
| telefonoAlterno | string | No | Teléfono alternativo |
| direccion | map | **Sí** | Ver abajo |
| ubicacionGPS | map | No | Ver abajo |
| clasificacion | string | No | `detal` \| `mayorista` |
| estado | string | Sí | `activo` \| `inactivo` \| `moroso` |
| creditoLimite | number | No | Límite de crédito |
| creditoSaldo | number | No | Saldo actual |
| observaciones | string | No | Notas |
| fechaCreacion | timestamp | Sí | Fecha de creación |

### `direccion` (map)

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| departamento | string | **Sí** | Código/nombre del departamento |
| ciudad | string | **Sí** | Código/nombre de la ciudad |
| direccion | string | **Sí** | Calle, número, apartamento, etc. |
| barrio | string | No | Barrio |
| referencia | string | No | Punto de referencia |

### `ubicacionGPS` (map)

| Campo | Tipo | Descripción |
|---|---|---|
| latitud | number | Latitud |
| longitud | number | Longitud |
| direccionAproximada | string | Dirección calculada por geocodificación inversa |
| fecha | timestamp | Fecha de captura |

### Ejemplo

```json
{
  "empresaId": "empresa_001",
  "uid": "uid_cliente_01",
  "nombreCompleto": "María Pérez",
  "cedula": "1020304050",
  "telefono": "+573001112233",
  "correo": "maria@correo.com",
  "direccion": {
    "departamento": "Cundinamarca",
    "ciudad": "Bogotá",
    "direccion": "Calle 123 #45-67, Apto 201",
    "barrio": "Chapinero"
  },
  "ubicacionGPS": {
    "latitud": 4.6486,
    "longitud": -74.0628,
    "direccionAproximada": "Chapinero, Bogotá"
  },
  "clasificacion": "detal",
  "estado": "activo"
}
```

---

## Catálogo de ubicaciones (local)

```json
{
  "departamentos": [
    { "id": "05", "nombre": "Antioquia", "ciudades": [{ "id": "05001", "nombre": "Medellín" }] },
    { "id": "11", "nombre": "Bogotá D.C.", "ciudades": [{ "id": "11001", "nombre": "Bogotá" }] }
  ]
}
```

---

## Apertura en mapas

```
Google Maps:  https://www.google.com/maps/search/?api=1&query={lat},{lng}
Waze:         https://waze.com/ul?ll={lat},{lng}&navigate=yes
```

---

## Índices sugeridos

- `clientes`: `empresaId` + `cedula` (único)
- `clientes`: `empresaId` + `nombreCompleto`
- `clientes`: `uid`
