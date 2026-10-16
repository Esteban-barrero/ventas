# Tareas: Catálogo de Productos

- **ID:** 003 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14 | **Actualizado:** 2026-10-15
- **Estado:** Implementado (núcleo). Ver notas al final.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/catalogo`
- [x] T002 Definir entidades `Producto` y `Categoria`
- [x] T003 Definir la lógica de cálculo de precio (`domain`)

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar `ProductosRepository` (CRUD, búsqueda, por categoría)
- [x] T011 Implementar `CategoriasRepository`
- [x] T012 Implementar cálculo de precio contado/crédito (general e individual)
- [x] T013 Implementar cálculo de costo de envío (individual o general)
- [x] T014 Implementar control de stock y alerta de stock mínimo
- [x] T015 Implementar subida y compresión de imágenes

## Fase 3 — Interfaz de Usuario

- [x] T020 Pantalla de catálogo (tarjetas con foto, nombre, medidas y precio)
- [x] T021 Pantalla de detalle de producto
- [x] T022 Formulario de creación/edición de producto
- [x] T023 Gestión de categorías
- [x] T024 Búsqueda y filtros

## Fase 4 — Seguridad y Auditoría

- [x] T030 Reglas de Firestore (lectura por empresa, escritura admin/marketing)
- [x] T031 Reglas de Storage para imágenes de producto
- [x] T032 Registrar auditoría en cambios de producto

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de precio y envío
- [x] T041 Pruebas de widget del catálogo y formulario
- [ ] T042 Prueba de integración de stock con transacción *(requiere el emulador
      de Firestore; el descuento usa `runTransaction` en
      `ProductosRepository.actualizarStock`)*
- [x] T043 Ejecutar `flutter analyze` y `flutter test` (133 pruebas)
- [x] T044 Actualizar documentación

---

## Decisiones tomadas al implementar

- **Precios:** se guardan `costo` y `margenes { contado, credito }` (opcionales);
  el **precio se calcula** (`costo × (1 + margen/100)`). No se persisten
  `precioDetal`/`precioMayor` (ver `data-model.md`).
- **Margen general dual:** se agregaron `margenContado` y `margenCredito` a los
  parámetros de la empresa (spec 002).
- **Stack:** se sigue el patrón existente (StatefulWidget + repositorios); **no**
  se introdujo Riverpod. Las fotos usan `image_picker` (con redimensionado).
- **Reglas:** por **perfil** (como 001/002), no por *custom claims*.
- **Búsqueda:** por subcadena en el cliente (nombre/código), sin índices
  compuestos.

- **Categorías estándar:** al abrir el catálogo, si la empresa no tiene
  categorías se siembra una **lista estándar** (`categorias_estandar.dart`),
  editable por cada empresa.
- **IVA por producto:** el producto tiene `iva` (opcional, hereda el de la
  empresa). La venta calcula los impuestos **por línea**.
- **Código de barras / QR:** el producto tiene `codigoBarras` y se puede
  **escanear** al registrar una venta (`mobile_scanner`).

## Pendiente (no bloqueante)

- Desplegar las reglas de Firestore y Storage de `productos`/`categorias`.
- Movimientos de inventario formales (van con la **spec 008 — Inventario**).
- Imagen de galería múltiple (hoy el formulario maneja la foto principal).

---

## Criterio de Terminado (Definition of Done)

- [x] Todos los criterios de aceptación de `spec.md` cumplidos
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando (133)
- [x] Márgenes y stock verificados
- [x] Código documentado: cada método y clase comentado en español (Principio 11)
- [ ] Commit y push realizados *(se hacen al cierre de esta spec)*
