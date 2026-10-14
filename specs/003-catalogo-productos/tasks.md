# Tareas: Catálogo de Productos

- **ID:** 003 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/catalogo`
- [ ] T002 Definir entidades `Producto` y `Categoria`
- [ ] T003 Definir la lógica de cálculo de precio (`domain`)

## Fase 2 — Lógica de Negocio

- [ ] T010 Implementar `ProductosRepository` (CRUD, búsqueda, por categoría)
- [ ] T011 Implementar `CategoriasRepository`
- [ ] T012 Implementar cálculo de precio contado/crédito (general e individual)
- [ ] T013 Implementar cálculo de costo de envío (individual o general)
- [ ] T014 Implementar control de stock y alerta de stock mínimo
- [ ] T015 Implementar subida y compresión de imágenes

## Fase 3 — Interfaz de Usuario

- [ ] T020 Pantalla de catálogo (tarjetas con foto, nombre, medidas y precio)
- [ ] T021 Pantalla de detalle de producto
- [ ] T022 Formulario de creación/edición de producto
- [ ] T023 Gestión de categorías
- [ ] T024 Búsqueda y filtros

## Fase 4 — Seguridad y Auditoría

- [ ] T030 Reglas de Firestore (lectura por empresa, escritura admin/marketing)
- [ ] T031 Reglas de Storage para imágenes de producto
- [ ] T032 Registrar auditoría en cambios de producto

## Fase 5 — Pruebas y Cierre

- [ ] T040 Pruebas unitarias de precio y envío
- [ ] T041 Pruebas de widget del catálogo y formulario
- [ ] T042 Prueba de integración de stock con transacción
- [ ] T043 Ejecutar `flutter analyze` y `flutter test`
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Margenes y stock verificados
- [ ] Commit y push realizados
