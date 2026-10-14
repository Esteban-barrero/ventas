# Investigación y Decisiones: Proveedores y Compras

- **ID:** 007 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesitan proveedores, compras con actualización de inventario y **anexos legales**
(facturas escaneadas, PDFs) como sustento para declaración.

## 2. Opciones Evaluadas

### 2.1. ¿Dónde escanear la factura?

| Opción | Ventajas | Desventajas |
|---|---|---|
| **Cámara con `image_picker`** | Escaneo directo desde el móvil | Calidad variable |
| Escáner externo / archivo | Mejor calidad | Requiere otro dispositivo |
| Lector de PDF | Ya viene digital | No siempre hay PDF |

**Decisión:** Ofrecer **ambos**: tomar foto (escaneo) o subir un PDF.

### 2.2. Almacenamiento de anexos

| Opción | Ventajas | Desventajas |
|---|---|---|
| Base64 en Firestore | Todo junto | Límite de 1 MB por documento |
| **Firebase Storage + metadatos en Firestore** | Archivos grandes, barato | Dos sistemas |

**Decisión:** **Storage** para los archivos y **metadatos** en la subcolección `anexos`.

### 2.3. Actualización del inventario y costo

| Opción | Ventajas | Desventajas |
|---|---|---|
| Solo inventario | Simple | No refleja el nuevo costo |
| **Inventario + costo (configurable)** | Costos actualizados | Puede cambiar el margen |

**Decisión:** Sumar inventario siempre; actualizar costo **según configuración** de la empresa
(promedio o último costo).

### 2.4. Anulación de compras

**Decisión:** Anulación **lógica** con **reverso de inventario**, solo si no se consumió y con permiso.

## 3. Preguntas Abiertas

- ¿OCR para leer datos de la factura? (después)
- ¿Órdenes de compra con flujo de aprobación? (evaluar)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11.8 y 12.9.
- Firebase Storage — Security Rules.
- `image_picker` / `file_picker`.
