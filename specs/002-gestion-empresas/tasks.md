# Tareas: Gestión de Empresas

- **ID:** 002 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14
- **Estado:** Implementado, desplegado y verificado

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/empresas`
- [x] T002 Definir entidades `Empresa` y `Licencia`
- [x] T003 Crear la colección `planes` con límites por defecto (se siembra al abrir el listado)

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar `EmpresasRepository` (CRUD de empresas)
- [x] T011 Implementar cálculo de estado de licencia (activa/por_vencer/vencida)
- [x] T012 Implementar creación de empresa vía Cloud Function (+ respaldo local, ADR-005)
- [x] T013 Implementar renovación, suspensión y reactivación
- [x] T014 Implementar validación/exhibición de límites por plan (se copian del plan y
      se muestran; la aplicación de topes llega con la gestión de usuarios)

## Fase 3 — Interfaz de Usuario

- [x] T020 Pantalla listado de empresas (Super Admin)
- [x] T021 Formulario de creación (datos + licencia + logo)
- [x] T022 Pantalla de detalle/edición de empresa
- [x] T023 Tablero de vencimientos (activas, por vencer, vencidas)
- [x] T024 Subida y previsualización del logo (512x512, máx 500 KB)
- [x] T025 Pantalla "Mi empresa" para el Administrador (logo + parámetros)

## Fase 4 — Cloud Functions y Seguridad

- [x] T030 Cloud Function `crearEmpresa` (empresa + admin + parámetros + roles) — escrita, sin desplegar
- [x] T031 Cloud Function `actualizarLicencia` — escrita, sin desplegar
- [x] T032 Cloud Function `cambiarEstadoEmpresa` — escrita, sin desplegar
- [x] T033 Cloud Function programada `notificarVencimientos` (correo + in-app) — escrita, sin desplegar
- [x] T034 Reglas de Firestore y Storage por empresa (Firestore desplegadas; Storage sin desplegar)
- [x] T035 Registrar auditoría en cambios de empresa

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de licencia y validaciones
- [x] T041 Pruebas de widget del formulario y del listado
- [x] T042 Prueba de integración: `crearEmpresa` contra las Functions desplegadas
      (empresa activa + administrador + límites del plan + auditoría)
- [x] T043 Ejecutar `flutter analyze` y `flutter test` (103 pruebas, análisis limpio)
- [x] T044 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [x] Todos los criterios de aceptación de `spec.md` cumplidos (CA-01..CA-09; ver `spec.md` §13)
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando (103 unitarias/widget + pruebas de reglas con tokens reales)
- [x] Aislamiento multi-tenant y auditoría verificados
- [x] Commit y push realizados

## Desplegado y verificado (plan Blaze activo)

- **Cloud Functions** desplegadas y verificadas end-to-end:
  `crearEmpresa`, `actualizarLicencia`, `cambiarEstadoEmpresa`, `validarLicencia`
  (us-central1) y `onUsuarioEscrito` (southamerica-east1, sincroniza *custom claims*).
- **Storage**: bucket `aplicativo-de-ventas-d8bcd.firebasestorage.app` creado y
  `app/storage.rules` desplegadas. Probado: subida propia OK; tipo de contenido
  inválido, más de 500 KB y logo de otra empresa → **403**.
- **Colección `planes`** sembrada (gratis/básico/premium).

