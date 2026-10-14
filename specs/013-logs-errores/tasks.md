# Tareas: Logs de Errores

- **ID:** 013 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de `features/logs` (Flutter) y `functions/src/logs`
- [ ] T002 Definir entidad `ErrorLog` y enum de severidad
- [ ] T003 Definir utilidades de enmascarado y huella (fingerprint)

## Fase 2 — Captura de Errores

- [ ] T010 Implementar `ErrorLogger` (handlers globales)
- [ ] T011 Extraer archivo y línea desde el stack trace
- [ ] T012 Enmascarar datos sensibles
- [ ] T013 Encolar offline y enviar al reconectar
- [ ] T014 Proteger contra bucles del propio logger
- [ ] T015 Implementar wrapper de errores en Cloud Functions

## Fase 3 — Consulta y Gestión

- [ ] T020 Implementar `LogsRepository.listar` (orden: más reciente primero)
- [ ] T021 Implementar filtros: módulo, severidad, usuario, fechas, código
- [ ] T022 Implementar búsqueda por descripción/archivo
- [ ] T023 Implementar detalle con stack trace completo
- [ ] T024 Implementar marcado de reconocido/resuelto
- [ ] T025 Implementar exportación (CSV/JSON)

## Fase 4 — Interfaz de Usuario

- [ ] T030 Listado de logs (solo Developer)
- [ ] T031 Pantalla de detalle del log
- [ ] T032 Widgets de filtros
- [ ] T033 Indicadores de errores frecuentes

## Fase 5 — Seguridad y Cierre

- [ ] T040 Reglas de Firestore (acceso solo Developer)
- [ ] T041 Retención / TTL
- [ ] T042 Pruebas unitarias, de widget, integración y seguridad
- [ ] T043 Ejecutar `flutter analyze`, `flutter test` y pruebas de Functions
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] Captura app + Cloud Functions verificada
- [ ] Acceso exclusivo del rol Developer verificado
- [ ] Sin datos sensibles en los logs
- [ ] Commit y push realizados
