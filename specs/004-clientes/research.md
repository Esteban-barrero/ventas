# Investigación y Decisiones: Clientes

- **ID:** 004 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesita registrar clientes con dirección completa (departamento, ciudad, dirección, barrio)
y ubicación GPS tipo WhatsApp, con acceso del cliente a su historial.

## 2. Opciones Evaluadas

### 2.1. Dirección

| Opción | Ventajas | Desventajas |
|---|---|---|
| Objeto embebido en el cliente | Simple, una sola dirección | No soporta varias direcciones |
| **Colección `direcciones` aparte** | Varias direcciones por cliente | Más complejo |

**Decisión:** **Objeto embebido** ahora. Si más adelante se necesitan varias direcciones,
se migra a colección.

### 2.2. Catálogo de departamentos y ciudades

| Opción | Ventajas | Desventajas |
|---|---|---|
| **Dataset local (JSON)** | Sin dependencia de red, rápido | Hay que actualizarlo |
| Colección en Firestore | Centralizado | Costo de lecturas |
| API externa | Siempre actualizado | Dependencia y latencia |

**Decisión:** **Dataset local** (DANE Colombia) cargado en la app.

### 2.3. Ubicación GPS y mapas

| Opción | Ventajas | Desventajas |
|---|---|---|
| SDK de mapas embebido (Google Maps) | Mapa dentro de la app | Requiere API key y más peso |
| **`url_launcher` a Google Maps/Waze** | Sin SDK, simple | Abre app externa |

**Decisión:** Guardar las coordenadas y abrir con **`url_launcher`**. El mapa embebido se evalúa después.

### 2.4. Acceso del cliente

**Decisión:** El cliente registrado tiene un `uid` vinculado a su documento y solo puede leer/editar
su propio registro (excepto `empresaId` y `estado`).

## 3. Preguntas Abiertas

- ¿Múltiples direcciones por cliente? (evaluar)
- ¿Validación contra registros oficiales? (fuera de alcance)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11.4 y 12.5.
- Dataset DANE — Departamentos y municipios de Colombia.
- `geolocator` / `geocoding` / `url_launcher`.
