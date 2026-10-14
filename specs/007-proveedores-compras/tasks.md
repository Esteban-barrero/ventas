# Tareas: Proveedores y Compras

- **ID:** 007 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/compras`
- [ ] T002 Definir entidades `Proveedor`, `Compra`, `ItemCompra` y `Anexo`
- [ ] T003 Definir la lógica de cálculo de totales de compra

## Fase 2 — Lógica de Negocio

- [ ] T010 Implementar `ProveedoresRepository` (CRUD, unicidad de NIT)
- [ ] T011 Implementar `ComprasRepository.registrar` (transacción)
- [ ] T012 Implementar suma de inventario (entradas)
- [ ] T013 Implementar actualización de costo de producto (configurable)
- [ ] T014 Implementar cuentas por pagar (compras a crédito)
- [ ] T015 Implementar anulación con reverso de inventario

## Fase 3 — Anexos y Archivos

- [ ] T020 Implementar escaneo de factura (cámara)
- [ ] T021 Implementar subida de PDF
- [ ] T022 Implementar subida de otros anexos legales
- [ ] T023 Implementar metadatos de anexos (nombre, tipo, fecha, usuario)
- [ ] T024 Implementar visualización y descarga de anexos

## Fase 4 — Interfaz de Usuario

- [ ] T030 Listado y formulario de proveedores
- [ ] T031 Listado y formulario de compras
- [ ] T032 Widget de anexos en el detalle de compra
- [ ] T033 Filtros y búsqueda de compras

## Fase 5 — Seguridad y Cierre

- [ ] T040 Reglas de Firestore y Storage
- [ ] T041 Registrar auditoría en compras, proveedores y anexos
- [ ] T042 Pruebas unitarias, de widget e integración
- [ ] T043 Ejecutar `flutter analyze` y `flutter test`
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Inventario, costo y anexos verificados
- [ ] Commit y push realizados
