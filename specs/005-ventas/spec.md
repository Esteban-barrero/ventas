# Especificación: Ventas

- **ID:** 005 | **Carpeta:** `specs/005-ventas/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Registra las ventas de cada empresa: productos, cantidades, precios, tipo de pago
(**contado o crédito**), **tipo de entrega** (presencial, entrega local, recoger en local o envío),
medio de pago (efectivo, tarjeta, transferencia Nequi/Bancolombia) y la **factura** con
numeración consecutiva. Descuenta inventario, alimenta la caja y (si es a crédito) genera
el plan de cobros.

## 2. Objetivo

- Registrar una venta completa en menos de 2 minutos.
- Calcular correctamente precios, totales, envío e impuestos.
- Saber siempre **quién vendió**, **quién tiene el dinero** y **en qué estado**.
- Emitir factura con numeración consecutiva por empresa.
- Descontar stock de forma transaccional.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Vendedor** | Registra ventas y consulta las suyas. |
| **Administrador** | Registra y anula ventas; configura descuentos. |
| **Cajero** | Registra cobros y ventas de mostrador. |
| **Gerente** | Consulta y aprueba anulaciones. |
| **Cliente** | Consulta sus compras. |

## 4. Historias de Usuario

- **Como** Vendedor, **quiero** registrar una venta rápido **para** atender al cliente.
- **Como** Vendedor, **quiero** elegir contado o crédito **para** aplicar el precio y flujo correctos.
- **Como** Vendedor, **quiero** indicar si es presencial, entrega local, recogida o envío.
- **Como** Cajero, **quiero** registrar el medio de pago (efectivo, transferencia).
- **Como** Administrador, **quiero** anular una venta con permiso **para** corregir errores.
- **Como** Cliente, **quiero** ver mis compras **para** hacer seguimiento.

## 5. Requisitos Funcionales

- RF-01 Fecha y hora de la venta.
- RF-02 Vendedor responsable.
- RF-03 Cliente con sus datos de contacto y dirección.
- RF-04 Lista de productos con cantidad, precio unitario y subtotal.
- RF-05 **Tipo de venta:** contado o crédito.
- RF-06 **Tipo de entrega:** presencial, entrega local, recoger en local o envío.
- RF-07 **Medio de pago:** efectivo, tarjeta, transferencia (Nequi, Bancolombia).
- RF-08 **Factura** con numeración consecutiva por empresa.
- RF-09 Cálculo de subtotal, costo de envío, descuentos y total.
- RF-10 Descuento de **stock** de forma transaccional.
- RF-11 Si es **envío** o **entrega local**: empresa de envío, fecha y estado.
- RF-12 Si es **presencial** o **recoger en local**: sin costo de envío.
- RF-13 **Anulación** con permisos (revierte stock y caja).
- RF-14 Registro para **caja/trazabilidad del dinero**.
- RF-15 Si es **crédito**: generar el plan de cobros (ver spec 006-créditos).
- RF-16 Registrar auditoría de cada venta.

## 6. Reglas de Negocio

- RN-01 El **precio** depende del tipo (contado/crédito) y del clasificado del cliente (detal/mayorista).
- RN-02 **Contado** usa el margen de contado; **crédito** usa el margen de crédito.
- RN-03 Si el tipo de entrega es presencial o recoger en local → **costo de envío = 0**.
- RN-04 El número de factura es **consecutivo por empresa**, sin saltos ni repeticiones.
- RN-05 El stock se descuenta en una **transacción**; no se permite stock negativo.
- RN-06 La anulación requiere rol con permiso y genera un registro en auditoría.
- RN-07 Una venta pertenece a una empresa (`empresaId`).
- RN-08 El total = suma de subtotales + envío − descuentos (+ impuestos si aplican).
- RN-09 La venta a crédito no recibe dinero al momento de la venta.

## 7. Criterios de Aceptación

- [ ] CA-01 Registrar una venta completa en menos de 2 minutos.
- [ ] CA-02 El total se calcula correctamente (subtotal + envío − descuentos).
- [ ] CA-03 El precio cambia según contado/crédito y detal/mayorista.
- [ ] CA-04 Presencial y recoger en local no cobran envío.
- [ ] CA-05 La factura toma un número consecutivo único por empresa.
- [ ] CA-06 El stock se descuenta correctamente y no queda negativo.
- [ ] CA-07 La anulación revierte stock y caja, y queda auditada.
- [ ] CA-08 La venta alimenta la caja/trazabilidad del dinero.
- [ ] CA-09 La venta a crédito genera su plan de cobros.

## 8. Datos Involucrados

- `ventas` (datos, ítems, tipo, entrega, pago, totales)
- `consecutivos` (contador de facturas por empresa)
- `movimientos_inventario` (salidas)
- `caja` / `movimientos_caja` (entradas)
- `creditos` (si aplica)
- `_auditoria`

## 9. Casos Borde / Errores

- Stock insuficiente al confirmar (transacción).
- Venta sin cliente (venta rápida / consumidor final).
- Anulación de una venta ya entregada o cobrada.
- Consecutivo duplicado por ventas concurrentes (usar transacción).
- Descuento mayor al total (validación).
- Pérdida de conexión a mitad de la venta (borrador offline).

## 10. Fuera de Alcance

- Pasarela de pago en línea.
- Facturación electrónica DIAN (se integra después; el modelo la contempla).
- Notas crédito/débito formales.

## 11. Dependencias

- 003 Catálogo (precios, márgenes, stock).
- 004 Clientes (datos y clasificación).
- 006 Créditos y Cobros (plan de pagos).
- 008 Caja y Trazabilidad del dinero.
- 002 Empresas (parámetros y consecutivos).
