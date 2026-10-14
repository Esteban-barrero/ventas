# Especificación: Proveedores y Compras

- **ID:** 007 | **Carpeta:** `specs/007-proveedores-compras/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Gestiona los **proveedores** y las **compras** de cada empresa, incluyendo **anexos legales**
(facturas escaneadas, PDFs y otros documentos de sustento) con trazabilidad de quién los subió,
cuándo y qué archivo. Al registrar una compra se **actualiza el inventario** y el **costo** de
los productos.

## 2. Objetivo

- Llevar el registro de proveedores y sus compras.
- Adjuntar la **documentación de sustento** de cada compra (para declaración).
- Alimentar el **inventario** con las entradas de mercancía.
- Conocer las **cuentas por pagar** a proveedores.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Administrador** | CRUD de proveedores y compras; gestiona anexos. |
| **Gerente** | Consulta compras y cuentas por pagar. |
| **Cajero** | Registra pagos a proveedores. |
| **Vendedor / Marketing** | Sin acceso (o solo consulta, según configuración). |

## 4. Historias de Usuario

- **Como** Administrador, **quiero** registrar un proveedor **para** asociarle compras.
- **Como** Administrador, **quiero** registrar una compra con su valor y costo por artículo.
- **Como** Administrador, **quiero** **escanear la factura** y adjuntarla **para** tener el sustento legal.
- **Como** Administrador, **quiero** subir el PDF de la factura y otros anexos.
- **Como** Administrador, **quiero** que la compra actualice el inventario automáticamente.
- **Como** Cajero, **quiero** registrar el pago al proveedor y que quede en caja.

## 5. Requisitos Funcionales

- RF-01 Registrar proveedor: nombre, NIT/RIF, dirección, teléfono, correo, contacto.
- RF-02 Registrar compra: número de orden, fecha, proveedor, productos.
- RF-03 Valor total de la compra y **costo por artículo**.
- RF-04 **Anexos legales** de la compra:
  - Escanear factura (foto o PDF).
  - Subir PDF de la factura.
  - Subir otros anexos legales (contratos, remesas, etc.).
- RF-05 Guardar anexos en **Firebase Storage**.
- RF-06 Cada anexo registra: nombre, tipo, fecha de subida y usuario que lo subió (trazabilidad).
- RF-07 Forma de pago: contado, crédito, transferencia.
- RF-08 Estado de la compra: pendiente, pagada, anulada.
- RF-09 Al registrar la compra se **suma al inventario**.
- RF-10 Actualizar el **costo** del producto según la compra (opcional/configurable).
- RF-11 Cuentas por pagar a proveedores.
- RF-12 Registro de auditoría.

## 6. Reglas de Negocio

- RN-01 Toda compra pertenece a una empresa (`empresaId`) y a un proveedor.
- RN-02 El stock **suma** al confirmar la compra.
- RN-03 El costo del producto se actualiza según el costo de la compra (si la empresa lo habilita).
- RN-04 Una compra **anulada** revierte el inventario.
- RN-05 Los anexos no se eliminan sin permiso (se conservan para la declaración).
- RN-06 El pago a proveedor de una compra a crédito alimenta las cuentas por pagar.
- RN-07 El NIT del proveedor debe ser único por empresa.

## 7. Criterios de Aceptación

- [ ] CA-01 Se puede registrar un proveedor con sus datos.
- [ ] CA-02 Se puede registrar una compra con productos y costos.
- [ ] CA-03 Se puede **escanear** o subir el PDF de la factura.
- [ ] CA-04 Se pueden subir anexos adicionales.
- [ ] CA-05 Cada anexo muestra quién lo subió y cuándo.
- [ ] CA-06 La compra **suma al inventario**.
- [ ] CA-07 El estado de la compra cambia (pendiente → pagada / anulada).
- [ ] CA-08 Las cuentas por pagar reflejan las compras a crédito.
- [ ] CA-09 Los cambios quedan auditados.

## 8. Datos Involucrados

- `proveedores`
- `compras` (datos, ítems, totales, estado)
- `compras/{id}/anexos` (subcolección de documentos)
- `movimientos_inventario` (entradas)
- `cuentas_por_pagar`
- Firebase Storage: `empresas/{empresaId}/compras/{compraId}/...`
- `_auditoria`

## 9. Casos Borde / Errores

- Anexo pesado o formato no soportado.
- Compra sin proveedor.
- Anulación de una compra ya pagada.
- Producto de la compra inexistente (crear o asociar).
- Fallo de subida (reintento).
- NIT de proveedor duplicado.

## 10. Fuera de Alcance

- OCR automático de facturas (se evalúa después).
- Órdenes de compra formales con aprobación por flujo.
- Integración con contabilidad externa.

## 11. Dependencias

- 003 Catálogo (productos y costo).
- 008 Inventario (movimientos de entrada).
- 009 Caja (pagos a proveedores).
- 002 Empresas (parámetros).
