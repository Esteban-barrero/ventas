# Tareas: Clientes

- **ID:** 004 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14 | **Actualizado:** 2026-10-16
- **Estado:** Implementado (núcleo). Ver notas al final.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/clientes`
- [x] T002 Definir entidades `Cliente`, `Direccion` y `UbicacionGPS`
- [x] T003 Cargar dataset de departamentos y ciudades

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar `ClientesRepository` (CRUD, búsqueda, por cédula, por uid)
- [x] T011 Implementar validaciones (obligatorios, cédula única, teléfono)
- [x] T012 Implementar filtro de ciudades por departamento
- [x] T013 Implementar captura y guardado de ubicación GPS
- [x] T014 Implementar apertura en Google Maps / Waze
- [ ] T015 Implementar historial de compras y pedidos por cliente *(depende de
      las specs 005 — Ventas y 010 — Pedidos; hoy muestra un aviso)*

## Fase 3 — Interfaz de Usuario

- [x] T020 Pantalla listado de clientes (con búsqueda y filtros)
- [x] T021 Formulario de cliente (crear/editar)
- [x] T022 Selector de departamento/ciudad
- [x] T023 Captura de ubicación GPS (botón "Compartir ubicación" en el formulario)
- [x] T024 Pantalla de detalle con ubicación y estado

## Fase 4 — Seguridad y Auditoría

- [x] T030 Reglas de Firestore (interno por empresa, cliente solo su registro)
- [x] T031 Registrar auditoría en cambios de cliente

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de validaciones y filtro de ciudades
- [ ] T041 Pruebas de widget del formulario y ubicación *(se cubrió el listado;
      el formulario/ubicación usan plugins que requieren dispositivo)*
- [ ] T042 Prueba de integración de guardado de GPS *(requiere emulador/dispositivo)*
- [x] T043 Ejecutar `flutter analyze` y `flutter test` (151 pruebas)
- [x] T044 Actualizar documentación

---

## Decisiones tomadas al implementar

- **Stack:** se sigue el patrón existente (StatefulWidget + repositorios); **no**
  se introdujo Riverpod. Se agregaron `geolocator`, `geocoding` y `url_launcher`.
- **Reglas:** por **perfil** (como 001/002/003), no por *custom claims*.
- **Historial:** las compras y pedidos llegan con las specs 005 y 010; por ahora
  el detalle muestra un aviso.
- **Ubicación GPS:** se captura con `geolocator`; la dirección aproximada por
  geocodificación inversa solo funciona en móvil (en Web se guardan las
  coordenadas).

## Pendiente (no bloqueante)

- Desplegar/verificar en Android/iOS los permisos de ubicación (ya están en
  `AndroidManifest.xml` e `Info.plist`).
- Historial de compras/pedidos (specs 005/010).
- Validación contra registros oficiales y multi-dirección (fuera de alcance).

---

## Criterio de Terminado (Definition of Done)

- [x] Todos los criterios de aceptación de `spec.md` cumplidos (salvo CA-06,
      que depende de Ventas/Pedidos)
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando (151)
- [x] Obligatorios, aislamiento y auditoría verificados
- [x] Código documentado: cada método y clase comentado en español (Principio 11)
- [ ] Commit y push realizados *(al cierre de esta spec)*
