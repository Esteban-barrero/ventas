# Tareas: Gestión de Empresas

- **ID:** 002 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de carpetas de `features/empresas`
- [ ] T002 Definir entidades `Empresa` y `Licencia`
- [ ] T003 Crear la colección `planes` con límites por defecto

## Fase 2 — Lógica de Negocio

- [ ] T010 Implementar `EmpresasRepository` (CRUD de empresas)
- [ ] T011 Implementar cálculo de estado de licencia (activa/por_vencer/vencida)
- [ ] T012 Implementar creación de empresa vía Cloud Function
- [ ] T013 Implementar renovación, suspensión y reactivación
- [ ] T014 Implementar validación/exhibición de límites por plan

## Fase 3 — Interfaz de Usuario

- [ ] T020 Pantalla listado de empresas (Super Admin)
- [ ] T021 Formulario de creación (datos + licencia + logo)
- [ ] T022 Pantalla de detalle/edición de empresa
- [ ] T023 Tablero de vencimientos (activas, por vencer, vencidas)
- [ ] T024 Subida y previsualización del logo (512x512, máx 500 KB)

## Fase 4 — Cloud Functions y Seguridad

- [ ] T030 Cloud Function `crearEmpresa` (empresa + admin + parámetros + roles)
- [ ] T031 Cloud Function `actualizarLicencia`
- [ ] T032 Cloud Function `cambiarEstadoEmpresa`
- [ ] T033 Cloud Function programada `notificarVencimientos` (correo + in-app)
- [ ] T034 Reglas de Firestore y Storage por empresa
- [ ] T035 Registrar auditoría en cambios de empresa

## Fase 5 — Pruebas y Cierre

- [ ] T040 Pruebas unitarias de licencia y validaciones
- [ ] T041 Pruebas de widget del formulario y tablero
- [ ] T042 Prueba de integración: `crearEmpresa`
- [ ] T043 Ejecutar `flutter analyze` y `flutter test`
- [ ] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] `flutter analyze` sin errores
- [ ] Pruebas pasando
- [ ] Aislamiento multi-tenant y auditoría verificados
- [ ] Commit y push realizados
