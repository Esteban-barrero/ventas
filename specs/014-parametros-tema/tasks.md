# Tareas: Parámetros Generales y Tema

- **ID:** 014 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14

---

## Fase 1 — Preparación

- [ ] T001 Crear estructura de `features/parametros`
- [ ] T002 Definir entidades `Parametros`, `Paleta` y `Licencia`
- [ ] T003 Definir la conversión de paleta a `ThemeData` (`domain`)

## Fase 2 — Paletas y Tema

- [ ] T010 Implementar CRUD de paletas (crear, editar, duplicar, eliminar)
- [ ] T011 Implementar activación de paleta por empresa
- [ ] T012 Implementar aplicación del tema **en tiempo real**
- [ ] T013 Implementar modo claro/oscuro
- [ ] T014 Validar contraste/accesibilidad de la paleta

## Fase 3 — Logo y Apariencia

- [ ] T020 Implementar subida de logo (Storage)
- [ ] T021 Implementar validación de formato, peso y tamaño en píxeles
- [ ] T022 Implementar previsualización móvil y web

## Fase 4 — Licencia y Avisos

- [ ] T030 Implementar CRUD de licencia (inicio/fin, mensual/anual)
- [ ] T031 Implementar validación y **bloqueo** por vencimiento
- [ ] T032 Implementar mensaje de licencia vencida con contacto del proveedor
- [ ] T033 Cloud Function programada `verificarLicenciasYNotificar`
- [ ] T034 Implementar aviso por correo
- [ ] T035 Implementar aviso in-app (`diasAvisoVencimiento`, defecto 5)
- [ ] T036 Controlar avisos repetidos

## Fase 5 — Parámetros Generales

- [ ] T040 Implementar parámetros: moneda, impuestos, interés, días de mora
- [ ] T041 Implementar canales de notificación (WhatsApp/Telegram)
- [ ] T042 Implementar datos y contacto de la empresa

## Fase 6 — Seguridad y Cierre

- [ ] T050 Reglas de Firestore por rol y empresa
- [ ] T051 Registrar auditoría de cambios de parámetros
- [ ] T052 Pruebas unitarias, de widget e integración
- [ ] T053 Ejecutar `flutter analyze`, `flutter test` y pruebas de Functions
- [ ] T054 Actualizar documentación

---

## Criterio de Terminado (Definition of Done)

- [ ] Todos los criterios de aceptación de `spec.md` cumplidos
- [ ] Tema en tiempo real verificado
- [ ] Licencia, bloqueo y avisos verificados
- [ ] Validación de logo verificada
- [ ] Commit y push realizados
