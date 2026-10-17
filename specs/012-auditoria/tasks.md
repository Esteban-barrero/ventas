# Tareas: Auditoría

- **ID:** 012 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14
- **Estado:** implementado el **registro** (desde el cliente) y el **módulo de
  consulta** con filtros y exportación CSV. Los triggers de Cloud Functions, el
  enmascarado y la retención TTL quedan pendientes.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de `features/auditoria`
- [x] T002 Definir entidad `RegistroAuditoria`
- [x] T003 Definir la lógica de diferencias de campos (`domain`)

## Fase 2 — Escritura de la auditoría

- [x] T010 Registrar `INSERT`
- [x] T011 Registrar `UPDATE` (campo, valor anterior y nuevo)
- [x] T012 Registrar `DELETE` con valores
- [ ] T013 Lista configurable de colecciones auditadas (pendiente)
- [ ] T014 Enmascarado de campos sensibles (pendiente)
- [ ] T015 Retención TTL ≥ 6 meses (pendiente)

## Fase 3 — Consulta y Exportación

- [x] T020 `AuditoriaRepository.listar/escuchar` con filtros
- [x] T021 Filtros: tabla, operación, fechas y documento (en la app)
- [x] T022 Búsqueda por palabra/frase
- [~] T023 Exportación a CSV (PDF/Excel pendientes)

## Fase 4 — Interfaz de Usuario

- [x] T030 Listado de auditoría con filtros
- [x] T031 Detalle de un registro (antes/después)
- [ ] T032 Meta-auditoría de consultas (pendiente)

## Fase 5 — Seguridad y Cierre

- [x] T040 Reglas de Firestore (solo lectura autorizada: admin/gerente/dev)
- [x] T041 Escritura de auditoría solo por inserción
- [x] T042 Pruebas unitarias del dominio y de los filtros
- [x] T043 Ejecutar `flutter analyze` y `flutter test`
- [x] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [x] Consulta, filtros y exportación funcionando
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando
- [x] Commit y push realizados
