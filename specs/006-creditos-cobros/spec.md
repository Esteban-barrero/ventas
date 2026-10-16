# Especificación: Créditos y Cobros

- **ID:** 006 | **Carpeta:** `specs/006-creditos-cobros/`
- **Fecha:** 2026-10-14
- **Estado:** Implementado (núcleo)
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Gestiona las ventas a crédito: apertura del crédito, **plan de cuotas** (semanal, quincenal o
mensual), **seguimiento de pagos**, **saldo**, **días de mora** y **estados**. Registra cada abono
con **quién cobró, cuándo, cuánto y por qué medio**, y alimenta la caja.

## 2. Objetivo

- Dar crédito de forma controlada y con aprobación.
- Generar automáticamente el plan de cuotas.
- Conocer en todo momento el saldo y la mora de cada cliente.
- Registrar cada cobro con trazabilidad completa.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Administrador** | Configura créditos; aprueba y cancela. |
| **Gerente** | Aprueba créditos y supervisa cartera. |
| **Vendedor** | Registra cobros de sus clientes. |
| **Cajero** | Recibe pagos y los registra en caja. |
| **Cliente** | Ve su crédito, sus cuotas y su saldo. |

## 4. Historias de Usuario

- **Como** Vendedor, **quiero** que al vender a crédito se genere el plan de cuotas **para** saber cuándo cobrar.
- **Como** Gerente, **quiero** aprobar el crédito **para** controlar el riesgo.
- **Como** Vendedor, **quiero** registrar un abono **para** actualizar el saldo.
- **Como** Administrador, **quiero** ver la cartera y la mora **para** gestionar el cobro.
- **Como** Cliente, **quiero** ver mis cuotas y mi saldo **para** saber qué debo.

## 5. Requisitos Funcionales

- RF-01 Generar el crédito automáticamente desde una venta a crédito (o manual).
- RF-02 Definir monto, plazo y **periodicidad**: semanal, quincenal o mensual.
- RF-03 Calcular automáticamente las **cuotas diferidas** (con o sin interés).
- RF-04 Aprobación del crédito por rol autorizado.
- RF-05 Registrar **abonos y pagos parciales**.
- RF-06 Seguimiento de cuotas pendientes vs. pagadas.
- RF-07 Mostrar **saldo actual** y **días de mora**.
- RF-08 **Estados:** activo, pagado, vencido, cancelado.
- RF-09 Historial de pagos por crédito.
- RF-10 Notificaciones de cuota por vencer y vencida.
- RF-11 Marcar automáticamente al cliente como **moroso**.
- RF-12 Registrar quién cobró, cuándo, cuánto y medio de pago.
- RF-13 Alimentar la caja con cada pago recibido.
- RF-14 Registrar auditoría.

## 6. Reglas de Negocio

- RN-01 El crédito solo se genera para ventas de tipo `credito`.
- RN-02 `montoCuota = montoTotal / numeroCuotas` (+ interés si aplica).
- RN-03 La fecha de vencimiento de cada cuota depende de la periodicidad.
- RN-04 Se permiten **abonos parciales**; el saldo se recalcula.
- RN-05 **Días de mora** = días desde la fecha de vencimiento sin pago completo.
- RN-06 Si la mora supera el límite configurado, el cliente pasa a **moroso**.
- RN-07 Un crédito **pagado** no admite más pagos.
- RN-08 Todo crédito pertenece a una empresa (`empresaId`).
- RN-09 Cada pago genera un movimiento de caja.

## 7. Criterios de Aceptación

- [x] CA-01 Una venta a crédito genera su crédito y su plan de cuotas.
- [x] CA-02 Las cuotas se calculan según monto, número y periodicidad.
- [x] CA-03 Se puede aprobar un crédito.
- [x] CA-04 Se registran abonos y el saldo se actualiza.
- [x] CA-05 Los días de mora se calculan correctamente.
- [x] CA-06 El crédito cambia de estado (activo → pagado / vencido).
- [ ] CA-07 El cliente moroso se marca automáticamente. *(Cloud Function programada)*
- [ ] CA-08 Cada pago queda en la caja y en la auditoría. *(caja: spec 009; auditoría: hecha)*

## 8. Datos Involucrados

- `creditos` (monto, plazo, periodicidad, saldo, estado, mora)
- `creditos/{id}/cuotas` (subcolección de cuotas)
- `pagos_credito` (abonos)
- `clientes` (estado moroso)
- `caja` / `movimientos_caja`
- `_auditoria`

## 9. Casos Borde / Errores

- Pago mayor al saldo (validación).
- Pago después de cancelado/pagado.
- Crédito sin aprobación.
- Cliente sin cupo de crédito.
- Interés mal configurado.
- Redondeo de cuotas (la última ajusta la diferencia).

## 10. Fuera de Alcance

- Cobranza jurídica.
- Refinanciación / reestructuración (se evalúa después).
- Interés compuesto avanzado.

## 11. Dependencias

- 005 Ventas (origen del crédito).
- 004 Clientes (datos, cupo y estado moroso).
- 008 Caja (registro de pagos).
- 002 Empresas (parámetros: interés, días de mora, días de aviso).
