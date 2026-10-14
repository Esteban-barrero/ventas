# Tareas: Clientes

- **ID:** 004 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/clientes`
- [ ] T002 Definir entidades `Cliente`, `Direccion` y `UbicacionGPS`
- [ ] T003 Cargar dataset de departamentos y ciudades

## Fase 2 — Lógica de Negocio

- [ ] T010 Implementar `ClientesRepository` (CRUD, búsqueda, por cédula)
- [ ] T011 Implementar validaciones (obligatorios, cédula única, teléfono)
- [ ] T012 Implementar filtro de ciudades por departamento
- [ ] T013 Implementar captura y guardado de ubicación GPS
- [ ] T014 Implementar apertura en Google Maps / Waze
- [ ] T015 Implementar historial de compras y pedidos por cliente

## Fase 3 — Interfaz de Usuario

- [ ] T020 Pantalla listado de clientes (con búsqueda)
- [ ] T021 Formulario de cliente (crear/editar)
- [ ] T022 Selector de departamento/ciudad
- [ ] T023 Pantalla de selección de ubicación GPS (mapa)
- [ ] T024 Pantalla de detalle con historial

## Fase 4 — Seguridad y Auditoría

- [ ] T030 Reglas de Firestore (interno por empresa, cliente solo su registro)
- [ ] T031 Registrar auditoría en cambios de cliente

## Fase 5 — Pruebas y Cierre

- [ ] T040 Pruebas unitarias de validaciones y filtro de ciudades
- [ ] T041 Pruebas de widget del formulario y ubicación
- [ ] T042 Prueba de integración de guardado de GPS
- [ ] T043 Ejecutar `flutter analyze` y `flutter test`
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Obligatorios, GPS y aislamiento verificados
- [ ] Commit y push realizados
