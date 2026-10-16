# Guía Rápida: Tesorería y flujo del dinero

- **ID:** 016 | **Fecha:** 2026-10-16

---

## Ver la posición del dinero

1. Módulo **Tesorería**.
2. Arriba, el **total** de la empresa.
3. Debajo, el **desglose por ubicación** (y responsable):
   - Caja física
   - Efectivo con el vendedor
   - Pago contra entrega (en tránsito)
   - Nequi
   - Banco (Bancolombia)
   - Tarjeta (por consignar)
4. La lista muestra cada movimiento con su origen.

## Registrar un movimiento

1. Tesorería → **Movimiento**.
2. Elegir **tipo** (ingreso, egreso, gasto, retiro), **monto**, **ubicación**,
   **medio** y **descripción**.
3. Guardar. El total y la ubicación se actualizan.

## Trasladar dinero

1. Tesorería → **Traslado**.
2. Elegir **origen**, **destino** y **monto**.
3. Guardar. El total **no cambia**; se mueve entre ubicaciones.

> Ejemplo: el vendedor entrega lo recaudado → traslado de *efectivo con el
> vendedor* a *caja física*. La caja consigna → traslado de *caja física* a
> *banco*.

## De dónde sale el dinero (trazabilidad)

- **Ventas de contado** → ingreso (ubicación según medio y entrega).
- **Cobros de crédito** → ingreso.
- **Turnos de caja (009)** → ingresos/egresos en caja física.
- **Gastos y retiros** → egreso.
