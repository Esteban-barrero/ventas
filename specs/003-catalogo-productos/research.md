# Investigación y Decisiones: Catálogo de Productos

- **ID:** 003 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesita un catálogo con fotos, medidas, precios duales (contado/crédito), márgenes
generales e individuales, costo de envío y control de stock.

## 2. Opciones Evaluadas

### 2.1. Cálculo del precio

| Opción | Ventajas | Desventajas |
|---|---|---|
| Guardar el precio calculado en el documento | Rápido de leer | Se desactualiza si cambia el costo o el margen |
| **Calcular en el cliente (domain)** | Siempre coherente con el margen | Cálculo en cada lectura |
| Calcular en Cloud Function | Centralizado | Latencia y costo |

**Decisión:** **Calcular en `domain`** (Flutter) a partir de `costo` y `margen`. Guardar el último
precio calculado como caché de conveniencia, pero la fuente es la fórmula.

### 2.2. Márgenes generales vs. por producto

**Decisión:** El producto puede tener `margenes { contado, credito }`. Si no están definidos,
se heredan de `empresa.parametros`.

### 2.3. Costo de envío

**Decisión:** Si el producto define `costoEnvio`, se usa; si no, el global de la empresa.

### 2.4. Búsqueda

| Opción | Ventajas | Desventajas |
|---|---|---|
| Filtros de Firestore por prefijo | Sin dependencias | No busca en medio del texto |
| **Extensiones / Algolia (búsqueda full-text)** | Búsqueda real | Servicio adicional y costo |

**Decisión:** Empezar con **búsqueda por prefijo** y evaluar Algolia si se necesita.

### 2.5. Imágenes

**Decisión:** Comprimir en el cliente (`flutter_image_compress`), límite de tamaño, y usar
`cached_network_image` para mostrar. Guardar en `empresas/{empresaId}/productos/{productoId}/`.

### 2.6. Stock

**Decisión:** Actualizar stock con **transacciones** de Firestore para evitar sobreventa.

## 3. Preguntas Abiertas

- ¿Variantes (talla/color) con stock independiente? (fuera de alcance inicial)
- ¿Precios por volumen (escalonados)? (evaluar)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11.1 y 12.2.
- Firestore — Transactions.
