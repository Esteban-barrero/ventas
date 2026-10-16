# Especificación: Inventario

- **ID:** 008 | **Carpeta:** `specs/008-inventario/`
- **Fecha:** 2026-10-14
- **Estado:** Implementado (núcleo)
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Controla las **existencias** de cada empresa mediante un **kardex** de movimientos (entradas,
salidas y ajustes). Cada movimiento queda registrado con **quién, cuándo, cuánto, por qué** y el
**stock resultante**. Incluye **alertas de stock mínimo**, **valorización** y **conteo físico**.

## 2. Objetivo

- Conocer el stock real de cada producto en todo momento.
- Tener trazabilidad completa de cada movimiento (kardex).
- Alertar cuando un producto llega al mínimo o se agota.
- Valorizar el inventario (costo × existencias).
- Permitir ajustes y conteos con permisos.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Administrador** | Configura mínimos; aprueba ajustes y conteos. |
| **Gerente** | Consulta kardex, valorización y alertas. |
| **Bodeguero / Vendedor** | Registra movimientos autorizados (si se habilita). |
| **Marketing** | Consulta disponibilidad (solo lectura). |

## 4. Historias de Usuario

- **Como** Administrador, **quiero** ver el stock actual por producto **para** saber qué pedir.
- **Como** Administrador, **quiero** ver el **kardex** de un producto **para** rastrear sus movimientos.
- **Como** Administrador, **quiero** ajustar el inventario con motivo **para** corregir diferencias.
- **Como** Administrador, **quiero** que me alerten del **stock mínimo** **para** reabastecer a tiempo.
- **Como** Gerente, **quiero** ver la **valorización** del inventario **para** conocer mi capital en mercancía.

## 5. Requisitos Funcionales

- RF-01 Mostrar **stock actual** por producto.
- RF-02 **Kardex:** historial de movimientos por producto (entrada, salida, ajuste).
- RF-03 **Entrada** automática al registrar una compra (spec 007).
- RF-04 **Salida** automática al registrar una venta (spec 005).
- RF-05 **Ajuste manual** (positivo o negativo) con **motivo** y permiso.
- RF-06 Registrar por movimiento: tipo, cantidad, stock resultante, usuario, fecha y referencia.
- RF-07 **Alertas de stock mínimo** por producto.
- RF-08 **Alertas de agotado** (stock = 0).
- RF-09 **Valorización** del inventario (costo × existencias) total y por producto.
- RF-10 **Conteo físico** (toma de inventario) con diferencias.
- RF-11 Soporte de **bodegas / sucursales** (multibodega, configurable).
- RF-12 Registrar auditoría.

## 6. Reglas de Negocio

- RN-01 Todo movimiento pertenece a una empresa (`empresaId`).
- RN-02 El stock **no puede ser negativo** (salvo configuración que lo permita y con permiso).
- RN-03 Todo movimiento genera un registro en `movimientos_inventario` (kardex).
- RN-04 El **stock resultante** se guarda en cada movimiento (para auditoría).
- RN-05 Los ajustes requieren **motivo** y rol autorizado.
- RN-06 Los movimientos **no se eliminan** (inmutables); se corrigen con un movimiento inverso.
- RN-07 La **valorización** usa el costo vigente del producto.
- RN-08 El **conteo físico** genera ajustes por las diferencias encontradas.

## 7. Criterios de Aceptación

- [x] CA-01 El stock actual coincide con la suma de los movimientos del kardex.
- [x] CA-02 Las compras suman y las ventas restan automáticamente.
- [x] CA-03 Un ajuste manual pide motivo y queda auditado.
- [x] CA-04 Se alerta cuando el stock llega al mínimo.
- [x] CA-05 Se alerta cuando el producto se agota.
- [x] CA-06 La valorización se calcula correctamente.
- [x] CA-07 El conteo físico genera los ajustes por diferencia.
- [x] CA-08 Los movimientos no se pueden eliminar.

## 8. Datos Involucrados

- `productos` (stock, costo, stockMinimo)
- `movimientos_inventario` (kardex)
- `conteos_inventario` (tomas físicas)
- `alertas` (o bandera en producto)
- `_auditoria`

## 9. Casos Borde / Errores

- Venta que dejaría stock negativo.
- Ajuste sin motivo o sin permiso.
- Producto sin costo (valorización incompleta).
- Conteo en curso con ventas simultáneas.
- Movimientos concurrentes sobre el mismo producto (transacción).
- Reversos de anulación (compra/venta).

## 10. Fuera de Alcance

- Lotes, series y fechas de vencimiento (se evalúa después).
- Traslados entre sucursales (fase posterior).
- Integración con códigos de barras / lectores (posible mejora).

## 11. Dependencias

- 003 Catálogo (producto, stock, costo, mínimo).
- 005 Ventas (salidas).
- 007 Proveedores y Compras (entradas).
- 002 Empresas (parámetros y sucursales).
- 015 Reportes (valorización y rotación).
