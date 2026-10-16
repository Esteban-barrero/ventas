# Plan Técnico: Tesorería y flujo del dinero

- **ID:** 016 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-16
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `tesoreria` en Flutter. Un **libro único** `movimientos_dinero` (ingreso,
egreso, traslado) con `ubicacion` y `responsableUid/Nombre`. La **posición** se
calcula sumando por ubicación. Se integra con ventas (contado) y cobros; la caja
por turno (009) pasa a escribir en el mismo libro.

## 2. Arquitectura

```
Flutter (tesoreria_screen: total, por ubicación, por responsable, traslados)
   │
TesoreriaRepository (data)
   ├─ registrarMovimiento / trasladar
   ├─ escucharMovimientos (stream)
   └─ posiciones / total  (a partir de los movimientos)

Orígenes de movimientos:
   ventas contado  -> ingreso (ubicación según medio/entrega)
   cobros crédito  -> ingreso
   compras/gastos  -> egreso (manual por ahora)
   turnos caja 009 -> ingreso/egreso con ubicacion caja_fisica
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/tesoreria/
├── domain/
│   ├── movimiento_dinero.dart   # MovimientoDinero, UbicacionDinero, tipos
│   └── posiciones.dart          # cálculo de saldos por ubicación
├── data/
│   └── tesoreria_repository.dart
└── presentation/
    └── tesoreria_screen.dart
```

La caja (009) se refactoriza para escribir/leer `movimientos_dinero` con
`ubicacion: caja_fisica`, sin mantener su propio libro.

## 4. Integración

- **Ventas (spec 005):** al registrar una venta de **contado**, se escribe un
  ingreso con la ubicación según RN-04. La venta guarda el **snapshot** de
  costo/utilidad. La venta a crédito no ingresa (RN-07).
- **Créditos (spec 006):** al **cobrar**, se escribe un ingreso.
- **Caja (spec 009):** sus movimientos son del mismo libro (ubicación física).

## 5. Seguridad

- Reglas de Firestore: `movimientos_dinero` solo lectura + creación (inmutable).
- Auditoría en cada movimiento (insert).

## 6. Pruebas

- Dominio: cálculo de posiciones (ingresos/egresos/traslados), total.
- Serialización de `MovimientoDinero`.
- Widget: la pantalla muestra total y desglose.
