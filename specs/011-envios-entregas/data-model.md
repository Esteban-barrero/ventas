# Modelo de Datos: Envíos y Entregas

- **ID:** 011 | **Fecha:** 2026-10-14

---

## `envios/{envioId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador del envío |
| empresaId | string | Empresa propietaria |
| origenTipo | string | `venta` \| `pedido` |
| origenId | string | ID de la venta o pedido |
| numeroGuia | string | Número de guía / seguimiento |
| empresaEnvioId | string | Transportadora |
| empresaEnvioNombre | string | Nombre de la transportadora |
| repartidorUid | string | Repartidor asignado |
| repartidorNombre | string | Nombre del repartidor |
| tipoEntrega | string | `entrega_local` \| `envio` |
| direccion | map | departamento, ciudad, direccion, barrio |
| gps | map | lat, lng (opcional) |
| clienteUid | string | Cliente (si tiene cuenta) |
| clienteNombre | string | Nombre del cliente |
| clienteTelefono | string | Teléfono |
| costoEnvio | number | Costo del envío |
| contraEntrega | boolean | Si es pago contra entrega |
| montoContraEntrega | number | Monto a recaudar |
| estadoDinero | string | `en_caja` \| `en_transito` \| `en_banco` \| `entregado` |
| estado | string | `preparando` \| `despachado` \| `en_transito` \| `en_reparto` \| `entregado` \| `devuelto` \| `novedad` |
| evidenciaUrl | string | Foto de entrega (Storage) |
| firmaUrl | string | Firma (Storage) |
| observaciones | string | Notas / novedades |
| historialEstados | array | Ver abajo |
| fechaCreacion | timestamp | Fecha de creación |
| fechaDespacho | timestamp | Fecha de despacho |
| fechaEstimada | timestamp | Fecha estimada de entrega |
| fechaEntrega | timestamp | Fecha de entrega real |

### `historialEstados[]` (array embebido)

| Campo | Tipo | Descripción |
|---|---|---|
| estado | string | Estado alcanzado |
| fecha | timestamp | Fecha y hora |
| usuarioUid | string | Quién lo registró |
| observacion | string | Nota del cambio |

---

## `empresas_envio/{empresaEnvioId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador |
| empresaId | string | Empresa (tenant) |
| nombre | string | Nombre de la transportadora |
| telefono | string | Teléfono |
| sitioWeb | string | Sitio de rastreo (opcional) |
| activo | boolean | Si está activa |

---

## Ejemplo de envío

```json
{
  "empresaId": "empresa_001",
  "origenTipo": "venta",
  "origenId": "venta_123",
  "numeroGuia": "ENV-2026-000123",
  "empresaEnvioNombre": "Envios Rapidos SAS",
  "repartidorUid": "uid_rep_07",
  "repartidorNombre": "Carlos M.",
  "tipoEntrega": "envio",
  "direccion": {
    "departamento": "Cundinamarca",
    "ciudad": "Bogota",
    "direccion": "Calle 123 #45-67",
    "barrio": "Chapinero"
  },
  "gps": { "lat": 4.6486, "lng": -74.0630 },
  "clienteNombre": "Maria Lopez",
  "clienteTelefono": "3001234567",
  "costoEnvio": 5000,
  "contraEntrega": true,
  "montoContraEntrega": 65000,
  "estadoDinero": "en_transito",
  "estado": "en_reparto"
}
```

---

## Flujo de estados

```
preparando ─► despachado ─► en_transito ─► en_reparto ─► entregado
                                                │
                                                ├─► devuelto  (reingresa stock)
                                                └─► novedad   (reintenta entrega)
```

---

## Efectos

1. **Despacho:** guarda guía, transportadora y `fechaDespacho`.
2. **En reparto:** asigna repartidor; si es contra entrega, `estadoDinero = en_transito`.
3. **Entregado:** guarda evidencia y `fechaEntrega`; el contra entrega pasa a **caja**.
4. **Devuelto:** reintegra stock (configurable) e informa.
5. **Notificación** al cliente en cada cambio.
6. **Auditoría.**

---

## Índices sugeridos

- `envios`: `empresaId` + `estado`
- `envios`: `empresaId` + `fechaCreacion` (desc)
- `envios`: `empresaId` + `numeroGuia`
- `envios`: `repartidorUid` + `estado`
- `empresas_envio`: `empresaId` + `activo`
