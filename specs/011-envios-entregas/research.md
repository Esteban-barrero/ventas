# Investigación y Decisiones: Envíos y Entregas

- **ID:** 011 | **Fecha:** 2026-10-14

---

## 1. Contexto

Las ventas y pedidos pueden entregarse de varias formas (presencial, entrega local, recoger en
local o envío). Se necesita rastrear el envío, confirmar la entrega con evidencia y controlar el
pago contra entrega.

## 2. Opciones Evaluadas

### 2.1. ¿Dónde vive el envío?

| Opción | Ventajas | Desventajas |
|---|---|---|
| Campos dentro de la venta | Simple | Mezcla responsabilidades |
| **Documento `envios` que referencia venta/pedido** | Independiente y consultable | Un documento más |

**Decisión:** **Documento propio** `envios` que referencia la venta o el pedido.

### 2.2. Modelo de estados

| Opción | Ventajas | Desventajas |
|---|---|---|
| Un solo campo `estado` | Simple | Sin historial de tiempos |
| **Campo `estado` + `historialEstados`** | Traza tiempos y responsables | Más datos |

**Decisión:** Estado actual **+ historial** con fecha, usuario y observación.

### 2.3. Evidencia de entrega

| Opción | Ventajas | Desventajas |
|---|---|---|
| No exigir evidencia | Rápido | Sin constancia |
| **Foto y/o firma (obligatoria si se configura)** | Constancia real | Más pasos |

**Decisión:** **Foto y/o firma**, obligatoria según configuración de la empresa.

### 2.4. Pago contra entrega

**Decisión:** El dinero queda **en tránsito** (responsable = repartidor) hasta la entrega; se
integra con la **caja** (spec 009) para el cambio de estado del dinero.

### 2.5. Devoluciones

**Decisión:** Estado `devuelto` con **reingreso de stock** configurable (spec 008).

### 2.6. Integración con transportadoras

**Decisión:** Manual (guía + transportadora). La **API automática** se evalúa después.

## 3. Preguntas Abiertas

- ¿Seguimiento GPS en tiempo real? (después)
- ¿Optimización de rutas? (después)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11 Envíos y 12 Trazabilidad.
- Google Maps / Waze — enlaces `maps` y `waze://`.
