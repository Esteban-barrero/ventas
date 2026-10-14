# Modelo de Datos: Parámetros Generales y Tema

- **ID:** 014 | **Fecha:** 2026-10-14

---

## `parametros/{empresaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa |
| nombreEmpresa | string | Nombre comercial |
| moneda | string | Código de moneda (ej: `COP`) |
| simboloMoneda | string | Símbolo (ej: `$`) |
| impuestoPorcentaje | number | Impuesto por defecto (%) |
| aplicaImpuesto | boolean | Si se aplican impuestos |
| tasaInteresCredito | number | Interés por defecto de créditos (%) |
| diasMora | number | Días para marcar moroso |
| costoEnvioGeneral | number | Costo de envío por defecto |
| paletaActivaId | string | Paleta activa |
| modoTema | string | `claro` \| `oscuro` \| `sistema` |
| logoUrl | string | URL del logo (Storage) |
| logoAnchoPx | number | Ancho en píxeles |
| logoAltoPx | number | Alto en píxeles |
| diasAvisoVencimiento | number | Días de aviso antes del vencimiento (defecto 5) |
| whatsappNumero | string | Número para notificaciones |
| telegramChatId | string | Chat de Telegram |
| telegramToken | string | Token del bot (protegido) |
| contactoProveedor | string | Contacto del proveedor al vencer |
| fechaActualizacion | timestamp | Última actualización |

---

## `paletas/{paletaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| id | string | Identificador |
| empresaId | string | Empresa propietaria |
| nombre | string | Nombre de la paleta |
| esBase | boolean | Si es una paleta base del proveedor |
| activa | boolean | Si está activa |
| colores | map | Ver abajo |
| fechaCreacion | timestamp | Creación |
| fechaActualizacion | timestamp | Última modificación |

### `colores` (map)

| Clave | Descripción |
|---|---|
| primario | Color principal |
| secundario | Color secundario |
| acento | Color de acento |
| fondo | Fondo |
| superficie | Superficie/tarjetas |
| texto | Texto principal |
| textoInverso | Texto sobre primario |
| exito | Éxito |
| advertencia | Advertencia |
| error | Error |

---

## `licencias/{empresaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa |
| plan | string | `mensual` \| `anual` |
| fechaInicio | timestamp | Inicio de la licencia |
| fechaFin | timestamp | Fin de la licencia |
| estado | string | `activa` \| `por_vencer` \| `vencida` \| `suspendida` |
| avisoEnviado | boolean | Si ya se envió el aviso de este ciclo |
| fechaUltimoAviso | timestamp | Fecha del último aviso |
| creadoPor | string | Super Admin que la asignó |

---

## Ejemplo de paleta

```json
{
  "empresaId": "empresa_001",
  "nombre": "Azul + Naranja",
  "esBase": true,
  "activa": true,
  "colores": {
    "primario": "#1A73E8",
    "secundario": "#FF6B35",
    "acento": "#FFC107",
    "fondo": "#FFFFFF",
    "superficie": "#F5F5F5",
    "texto": "#202124",
    "textoInverso": "#FFFFFF",
    "exito": "#34A853",
    "advertencia": "#FBBC04",
    "error": "#EA4335"
  }
}
```

---

## Ejemplo de licencia

```json
{
  "empresaId": "empresa_001",
  "plan": "anual",
  "fechaInicio": "2026-10-14T00:00:00Z",
  "fechaFin": "2027-10-14T00:00:00Z",
  "estado": "activa",
  "avisoEnviado": false
}
```

---

## Cálculo de vencimiento

```
diasRestantes = (fechaFin - ahora) en dias
si diasRestantes < 0        -> estado = vencida   -> bloqueo
si diasRestantes <= diasAvisoVencimiento -> estado = por_vencer -> aviso
```

---

## Índices sugeridos

- `paletas`: `empresaId` + `activa`
- `licencias`: `estado` + `fechaFin`
