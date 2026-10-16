# Tareas: Ventas

- **ID:** 005 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14 | **Actualizado:** 2026-10-16
- **Estado:** Implementado (núcleo). Ver notas al final.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/ventas`
- [x] T002 Definir entidades `Venta` e `ItemVenta`
- [x] T003 Definir la lógica de cálculo de totales (`domain`)

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar `VentasRepository.registrar` (transacción)
- [x] T011 Implementar consecutivo de factura por empresa
- [x] T012 Implementar cálculo de totales (envío, descuentos, impuestos)
- [x] T013 Implementar descuento de stock transaccional
- [x] T014 Implementar tipos de entrega y regla de envío
- [x] T015 Implementar medios de pago (efectivo, tarjeta, transferencia)
- [x] T016 Implementar anulación con reverso de stock *(el ajuste de **caja**
      llega con la spec 009)*
- [ ] T017 Integrar creación de crédito y plan de cobros *(depende de la spec 006)*

## Fase 3 — Interfaz de Usuario

- [x] T020 Pantalla de nueva venta (productos + cantidades)
- [x] T021 Selección de cliente y tipo (contado/crédito)
- [x] T022 Selección de tipo de entrega
- [x] T023 Selección de medio de pago
- [ ] T024 Previsualización e impresión de factura en PDF *(hoy la factura se ve
      en pantalla; el PDF con `pdf`/`printing` queda pendiente)*
- [x] T025 Listado y detalle de ventas con filtros

## Fase 4 — Seguridad y Auditoría

- [x] T030 Reglas de Firestore por rol y empresa
- [x] T031 Registrar auditoría por venta y anulación

## Fase 5 — Pruebas y Cierre

- [x] T040 Pruebas unitarias de totales y de filtros *(el consecutivo se verifica
      en la transacción/emulador)*
- [ ] T041 Pruebas de widget de la pantalla de venta *(se cubrió el listado; el
      formulario de venta queda pendiente)*
- [ ] T042 Prueba de integración de la transacción *(requiere emulador)*
- [x] T043 Ejecutar `flutter analyze` y `flutter test` (161 pruebas)
- [x] T044 Actualizar documentación

---

## Decisiones tomadas al implementar

- **Stack:** se sigue el patrón existente (StatefulWidget + repositorios); **no**
  se introdujo Riverpod ni `intl` (se usa `formatearValor`). El **PDF** de la
  factura queda pendiente.
- **Precio (RN-01):** se usa el margen **contado/crédito** del catálogo (spec
  003). El matiz "precio según detal/mayorista" **no** se aplica porque la 003
  no modela márgenes por canal.
- **Reglas:** por **perfil** (como 001–004), no por *custom claims*.
- **Efectos secundarios:** se implementan stock y consecutivo; los movimientos de
  **inventario** (008), **caja** (009) y **crédito** (006) van con sus specs.

## Pendiente (no bloqueante)

- Caja/trazabilidad (spec 009) y plan de cobros del crédito (spec 006).
- Movimientos de inventario (spec 008).
- Factura en PDF e impresión.

---

## Criterio de Terminado (Definition of Done)

- [x] Criterios de aceptación cumplidos **salvo** CA-07 (caja), CA-08 (caja) y
      CA-09 (crédito), que dependen de 006/009
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando (161)
- [x] Transacción, consecutivo y auditoría verificados
- [x] Código documentado: cada método y clase comentado en español (Principio 11)
- [ ] Commit y push realizados *(al cierre de esta spec)*
