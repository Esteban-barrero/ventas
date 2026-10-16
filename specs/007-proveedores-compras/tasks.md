# Tareas: Proveedores y Compras

- **ID:** 007 | **Plan:** [`plan.md`](./plan.md)
- **Fecha:** 2026-10-14 | **Actualizado:** 2026-10-16
- **Estado:** Implementado (núcleo). Ver notas al final.

---

## Fase 1 — Preparación

- [x] T001 Crear estructura de carpetas de `features/compras`
- [x] T002 Definir entidades `Proveedor`, `Compra`, `ItemCompra` y `Anexo`
- [x] T003 Definir la lógica de cálculo de totales de compra (con retenciones)

## Fase 2 — Lógica de Negocio

- [x] T010 Implementar `ProveedoresRepository` (CRUD, unicidad de NIT)
- [x] T011 Implementar `ComprasRepository.registrar` (transacción)
- [x] T012 Implementar suma de inventario (entradas)
- [x] T013 Implementar actualización de costo de producto (configurable)
- [x] T014 Implementar cuentas por pagar (compras a crédito)
- [x] T015 Implementar anulación con reverso de inventario

## Fase 3 — Anexos y Archivos

- [x] T020 Implementar escaneo de factura (cámara, `image_picker`)
- [x] T021 Implementar subida de PDF (`file_picker`)
- [x] T022 Implementar subida de otros anexos legales
- [x] T023 Implementar metadatos de anexos (nombre, tipo, fecha, usuario)
- [x] T024 Visualización de anexos (URL de descarga)

## Fase 4 — Interfaz de Usuario

- [x] T030 Listado y formulario de proveedores
- [x] T031 Listado y formulario de compras
- [x] T032 Widget de anexos en el detalle de compra
- [x] T033 Filtros y búsqueda de compras

## Fase 5 — Seguridad y Cierre

- [x] T040 Reglas de Firestore y Storage
- [x] T041 Registrar auditoría en compras, proveedores y anexos
- [x] T042 Pruebas unitarias y de widget *(la integración con emulador queda
      pendiente)*
- [x] T043 Ejecutar `flutter analyze` y `flutter test` (180 pruebas)
- [x] T044 Actualizar documentación

---

## Decisiones tomadas al implementar

- **Retenciones (pedido del usuario):** las compras incluyen **retención en la
  fuente**, **reteIVA** y **reteICA**. Las tasas (%) se configuran en los
  parámetros de la empresa y el **total a pagar = subtotal + IVA − retenciones**.
- **IVA de la compra:** por línea, según el IVA de cada producto.
- **Anexos:** `image_picker` (escaneo de factura) y `file_picker` (PDF/otros);
  archivos en Storage (`empresas/{empresaId}/compras/{compraId}/...`) y metadatos
  en `compras/{id}/anexos` con **quién** y **cuándo**.
- **Stack:** patrón existente (StatefulWidget + repositorios); **no** Riverpod ni
  `intl`.
- **Reglas:** por **perfil** (como 001–006).
- **Numero de orden:** consecutivo `OC-######` por empresa si no se escribe.

## Pendiente (no bloqueante)

- Movimientos de inventario formales (spec 008) y **pago a proveedor por caja**
  (spec 009).
- OCR de facturas y órdenes de compra con aprobación (fuera de alcance).

---

## Criterio de Terminado (Definition of Done)

- [x] Todos los criterios de aceptación de `spec.md` cumplidos
- [x] `flutter analyze` sin errores
- [x] Pruebas pasando (180)
- [x] Inventario, costo y anexos verificados
- [x] Código documentado: cada método y clase comentado en español (Principio 11)
- [ ] Commit y push realizados *(al cierre de esta spec)*
