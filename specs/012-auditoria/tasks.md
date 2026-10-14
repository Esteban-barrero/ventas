# Tareas: Auditoría

- **ID:** 012 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de `features/auditoria` (Flutter) y `functions/src/auditoria`
- [ ] T002 Definir entidad `RegistroAuditoria`
- [ ] T003 Definir la lógica de diferencias de campos (`domain`)

## Fase 2 — Cloud Functions de Auditoría

- [ ] T010 Implementar `auditarCreate` (INSERT)
- [ ] T011 Implementar `auditarUpdate` (UPDATE con antes/después)
- [ ] T012 Implementar `auditarDelete` (DELETE con valores eliminados)
- [ ] T013 Implementar lista configurable de colecciones auditadas
- [ ] T014 Implementar enmascarado de campos sensibles
- [ ] T015 Implementar política de retención (mínimo 6 meses)

## Fase 3 — Consulta y Exportación

- [ ] T020 Implementar `AuditoriaRepository.listar` con filtros
- [ ] T021 Implementar filtros: empresa, usuario, colección, operación, fechas, documentoId
- [ ] T022 Implementar búsqueda por palabra/frase
- [ ] T023 Implementar exportación (CSV/Excel/PDF)

## Fase 4 — Interfaz de Usuario

- [ ] T030 Listado de auditoría con filtros
- [ ] T031 Detalle de un registro con tabla de cambios (antes/después)
- [ ] T032 Indicadores/meta-auditoría de consultas

## Fase 5 — Seguridad y Cierre

- [ ] T040 Reglas de Firestore (solo lectura autorizada)
- [ ] T041 Restringir escritura de auditoría solo a Cloud Functions
- [ ] T042 Pruebas unitarias, de integración y de seguridad
- [ ] T043 Ejecutar `flutter analyze`, `flutter test` y pruebas de Functions
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] INSERT/UPDATE/DELETE auditados y verificados
- [ ] Inmutabilidad y retención (≥ 6 meses) verificadas
- [ ] Exportación funcionando
- [ ] Commit y push realizados
