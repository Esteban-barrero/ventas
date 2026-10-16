# Especificación: Tesorería y flujo del dinero

- **ID:** 016 | **Carpeta:** `specs/016-tesoreria-flujo-dinero/`
- **Fecha:** 2026-10-16
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Unifica el **dinero de la empresa** en un solo libro de movimientos (ingresos,
egresos y traslados) y responde dos preguntas: **¿cuánta plata hay?** y
**¿dónde está y quién la tiene?**. La caja por turno (spec 009) deja de ser *el*
módulo de dinero y pasa a ser **una ubicación** dentro del libro: la *caja física*.

## 2. Objetivo

- Un único **libro de movimientos de dinero** a nivel empresa (`movimientos_dinero`).
- Conocer el **saldo total** y el **desglose por ubicación** y **responsable**.
- Trazar el dinero: en caja física, en manos del vendedor, en tránsito (contra
  entrega), Nequi, banco, tarjeta por consignar.
- Poder **trasladar** dinero entre ubicaciones (ej. el vendedor entrega lo
  recaudado a la caja, o la caja consigna al banco) sin afectar el total.
- Registrar la **rentabilidad** de cada venta (costo, utilidad y margen %).

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Cajero** | Registra movimientos y traslados, cierra su turno. |
| **Vendedor** | Genera dinero (ventas, contado/contra entrega) y lo entrega. |
| **Administrador** | Autoriza retiros/gastos, ve la posición consolidada. |
| **Gerente** | Supervisa el flujo y la trazabilidad. |

## 4. Alcance

**Incluye:** libro único de movimientos, posición total y por ubicación,
trazabilidad por responsable, traslados, integración automática de ventas de
contado y cobros, snapshot de utilidad en ventas, pantalla de Tesorería.

**No incluye:** factura en PDF (005), pago a proveedor (007, pendiente),
cierre de caja con comprobante PDF (009, pendiente), conciliación bancaria.

## 5. Requisitos funcionales

- **RF-01** Registrar movimientos `ingreso`, `egreso` y `traslado`.
- **RF-02** Clasificar cada movimiento por **ubicación** y **responsable**.
- **RF-03** Calcular el **total de la empresa** y el **saldo por ubicación**.
- **RF-04** Listar movimientos con filtros (ubicación, responsable, fechas).
- **RF-05** **Trasladar** dinero entre ubicaciones (no cambia el total).
- **RF-06** Integrar automáticamente las **ventas de contado** y los **cobros**.
- **RF-07** Guardar en cada venta el **costo**, la **utilidad** y el **margen %**.

## 6. Reglas de negocio

- **RN-01** El libro es **inmutable**: no se editan ni borran movimientos.
- **RN-02** Un **traslado** resta en el origen y suma en el destino (neto 0).
- **RN-03** El dinero **no** puede quedar con saldo negativo en una ubicación
  (el traslado no puede exceder lo disponible).
- **RN-04** La **ubicación** se deduce así en una venta de contado:

  | Medio / entrega | Ubicación |
  |---|---|
  | Efectivo, entrega en local | `caja_fisica` |
  | Efectivo, contra entrega / domicilio | `contra_entrega` |
  | Transferencia Nequi | `nequi` |
  | Transferencia Bancolombia | `banco` |
  | Tarjeta | `tarjeta_por_consignar` |

- **RN-05** El **responsable** por defecto es quien registra; en contra entrega
  es el vendedor/domiciliario.
- **RN-06** El margen (%) es el del producto o, si no lo define, el general de la
  empresa (spec 003). La venta guarda el **snapshot**: `costo`, `utilidad` y
  `margenPct` por línea, y `utilidadTotal` en la venta.
- **RN-07** La venta **a crédito** no ingresa dinero al registrarse; ingresa al
  **cobrar**.
- **RN-08** Todo movimiento y traslado queda en **auditoría**.

## 7. Casos de aceptación

- **CA-01** Empresa con $1.000.000 en caja física; se compra inventario por
  $100.000 → total **$900.000**. Se venden 5 unidades con 50% de margen → entra
  el dinero y la venta muestra su **utilidad**.
- **CA-02** La pantalla de Tesorería muestra el **total** y el desglose:
  "$20.000 en pago contra entrega (responsable Pepito)", "$50.000 en Nequi
  (responsable Marta)", etc.
- **CA-03** Se **traslada** $50.000 de Nequi a caja física → el total no cambia y
  las dos ubicaciones se ajustan.
- **CA-04** Un egreso (gasto o retiro) baja el total y deja la trazabilidad.

## 8. Dependencias

- **Spec 003** (márgenes y precios), **Spec 005** (ventas), **Spec 006**
  (créditos y cobros), **Spec 009** (caja por turno). La spec 011 (envíos)
  concreta el flujo del dinero en tránsito.
