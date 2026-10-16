# Tareas: Inventario

- **ID:** 008 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14 | **Actualizado:** 2026-10-16
- **Estado:** Implementado (núcleo). Ver notas al final.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/inventario`
- [x] T002 Definir entidades `MovimientoInventario` y `ConteoInventario`
- [x] T003 Definir la lógica de cálculo de stock y valorización (`domain`)

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar consulta de stock y kardex por producto
- [x] T011 Implementar entrada automática desde compras (spec 007)
- [x] T012 Implementar salida automática desde ventas (spec 005)
- [x] T013 Implementar ajuste manual (positivo/negativo) con motivo
- [x] T014 Implementar regla de no stock negativo
- [x] T015 Implementar reversos por anulación (compra/venta)
- [x] T016 Implementar valorización del inventario
- [x] T017 Implementar alertas de stock mínimo y agotado

## Fase 3 — Conteo Físico

- [x] T020 Implementar registro de conteo físico
- [x] T021 Implementar cálculo de diferencias y generación de ajustes
- [ ] T022 Cierre de conteo con aprobación *(hoy el cierre genera los ajustes
      directamente; el flujo de aprobación queda pendiente)*

## Fase 4 — Interfaz de Usuario

- [x] T030 Listado de inventario con filtros (bajo stock, agotado)
- [x] T031 Pantalla de kardex de un producto
- [x] T032 Ajuste de inventario (desde el kardex)
- [x] T033 Pantalla de conteo físico
- [ ] T034 Indicadores/alertas en el panel principal

## Fase 5 — Seguridad y Cierre

- [x] T040 Reglas de Firestore (kardex inmutable)
- [x] T041 Registrar auditoría en ajustes y conteos
- [x] T042 Pruebas unitarias y de widget *(la integración con emulador queda
      pendiente)*
- [x] T043 Ejecutar `flutter analyze` y `flutter test` (187 pruebas)
- [x] T044 Actualizar documentación

---

## Decisiones tomadas al implementar

- **Kardex inmutable** (`movimientos_inventario`): solo inserción; un error se
  corrige con un movimiento inverso (RN-06).
- **Integración:** las transacciones de **ventas** (salida / reverso) y
  **compras** (entrada / reverso) escriben el movimiento con el helper
  compartido `escribirMovimiento` (`features/inventario/data/kardex.dart`).
- **Stock negativo:** solo si el producto tiene `permiteStockNegativo` (RN-02).
- **Conteo:** al cerrar genera los ajustes por diferencia y guarda el conteo.
- **Multibodega:** `bodegaId = 'principal'` (el multibodega real queda para
  después).
- **Stack:** patrón existente; **no** Riverpod ni `intl`.

## Pendiente (no bloqueante)

- Multibodega / sucursales y aprobación del cierre de conteo.
- Indicadores/alertas en el panel principal (T034).

---

## Criterio de Terminado (Definition of Done)

- [x] Todos los criterios de aceptación de `spec.md` cumplidos
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando (187)
- [x] Kardex, ajustes y valorización verificados
- [x] Código documentado: cada método y clase comentado en español (Principio 11)
- [ ] Commit y push realizados *(al cierre de esta spec)*
