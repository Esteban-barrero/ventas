# Especificación: Caja y Trazabilidad del dinero

- **ID:** 009 | **Carpeta:** `specs/009-caja-trazabilidad/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Controla el **dinero** de cada empresa: **apertura y cierre de caja**, todos los **movimientos de
efectivo** (ventas, cobros, pagos, gastos, retiros) y la **trazabilidad** de quién tiene el dinero
y en qué **estado** está (en caja, en tránsito con un domiciliario, en banco, entregado). Incluye
**arqueo** y **cuadre** por turno.

## 2. Objetivo

- Saber siempre **cuánto dinero** hay y **dónde** está.
- Registrar **quién vendió** y **quién tiene** el dinero.
- Cuadrar la caja al cerrar el turno (arqueo).
- Trazar los pagos por **Nequi / Bancolombia / efectivo / tarjeta**.
- Controlar el **pago contra entrega** (dinero en manos del domiciliario).

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Cajero** | Abre/cierra caja, registra movimientos, hace arqueo. |
| **Administrador** | Configura cajas, autoriza retiros y ajustes. |
| **Gerente** | Supervisa, aprueba diferencias y arqueos. |
| **Vendedor** | Consulta sus ventas y el dinero asociado. |

## 4. Historias de Usuario

- **Como** Cajero, **quiero** abrir mi caja con un monto inicial **para** empezar el turno.
- **Como** Cajero, **quiero** registrar ingresos y egresos **para** reflejar el efectivo real.
- **Como** Cajero, **quiero** hacer el **arqueo** al cerrar **para** cuadrar la caja.
- **Como** Administrador, **quiero** saber **quién tiene** el dinero **para** controlar el efectivo.
- **Como** Gerente, **quiero** ver el **estado del dinero** de un envío contra entrega.

## 5. Requisitos Funcionales

- RF-01 **Apertura de caja** con monto inicial por usuario/turno.
- RF-02 **Cierre de caja** con arqueo y cuadre.
- RF-03 Registrar **movimientos de caja**:
  - Ingresos por venta (efectivo).
  - Ingresos por cobro de crédito.
  - Egresos por pago a proveedor.
  - Gastos / retiros / consignaciones.
- RF-04 Medio de pago por movimiento: efectivo, Nequi, Bancolombia, tarjeta.
- RF-05 Registrar **quién vendió** y **quién tiene** el dinero (`responsableUid`).
- RF-06 **Estado del dinero:** `en_caja`, `en_transito` (con domiciliario), `en_banco`, `entregado`.
- RF-07 **Pago contra entrega:** registrar empresa de envío, domiciliario, fecha y monto en tránsito.
- RF-08 **Arqueo:** conteo físico del efectivo vs. sistema.
- RF-09 **Diferencia** (sobrante/faltante) y su justificación.
- RF-10 Consulta consolidada por caja, por usuario y por medio de pago.
- RF-11 Registro de auditoría.

## 6. Reglas de Negocio

- RN-01 Toda caja pertenece a una empresa (`empresaId`).
- RN-02 Solo se registra dinero **con la caja abierta**.
- RN-03 No se puede abrir una caja si ya hay una abierta para el mismo usuario.
- RN-04 **Total esperado** = monto inicial + ingresos − egresos.
- RN-05 **Diferencia** = efectivo contado − total esperado.
- RN-06 El **pago contra entrega** deja el dinero `en_transito` hasta que el domiciliario lo entrega.
- RN-07 Un retiro/ajuste requiere autorización según el monto configurado.
- RN-08 La caja cerrada queda **bloqueada** (solo Super Admin puede reabrir con auditoría).
- RN-09 Cada movimiento de caja registra su origen (venta, cobro, compra, gasto).

## 7. Criterios de Aceptación

- [ ] CA-01 Se abre una caja con monto inicial.
- [ ] CA-02 Se registran ingresos y egresos correctamente.
- [ ] CA-03 El saldo de caja se actualiza en cada movimiento.
- [ ] CA-04 El arqueo calcula la diferencia (sobrante/faltante).
- [ ] CA-05 Se registra quién tiene el dinero.
- [ ] CA-06 El dinero de un envío pasa a `en_transito` y luego a `entregado`.
- [ ] CA-07 Se bloquea una caja si ya está abierta.
- [ ] CA-08 Todo movimiento queda auditado.

## 8. Datos Involucrados

- `cajas` (caja/turno abierto)
- `movimientos_caja` (ingresos/egresos)
- `arqueos` (conteos y diferencias)
- `ventas`, `pagos_credito`, `compras` (origen)
- `_auditoria`

## 9. Casos Borde / Errores

- Cerrar caja con movimientos pendientes de sincronizar (offline).
- Diferencia sin justificación.
- Domiciliario que no entrega el dinero (en tránsito prolongado).
- Dos cajas abiertas del mismo usuario.
- Movimiento en caja ya cerrada.
- Montos negativos o no numéricos.

## 10. Fuera de Alcance

- Conciliación bancaria automática.
- Integración con pasarelas de pago (no hay por ahora).
- Nómina y gastos recurrentes formales.

## 11. Dependencias

- 005 Ventas (ingreso por venta).
- 006 Créditos y Cobros (ingresos por cobro).
- 007 Proveedores y Compras (egresos por pago).
- 011 Envíos y Entregas (dinero en tránsito).
- 002 Empresas (parámetros de caja y montos de autorización).
