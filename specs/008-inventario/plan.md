# Plan Técnico: Inventario

- **ID:** 008 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `inventario` en Flutter. Las entradas (compras) y salidas (ventas) se generan desde sus
propios módulos en **transacciones** que actualizan `productos.stock` y escriben en
`movimientos_inventario`. Los **ajustes** y **conteos** se manejan también de forma transaccional.

## 2. Arquitectura

```
Flutter (inventario_list, kardex, ajuste, conteo)
   │
InventarioRepository (data)
   ├─ consultar stock / kardex
   ├─ registrarAjuste (transaccion)
   ├─ registrarConteo (transaccion + ajustes)
   └─ alertas de minimo / agotado

Escritura desde otros modulos:
   ventas   -> salida (spec 005)
   compras  -> entrada (spec 007)
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/inventario/
├── data/
│   ├── inventario_repository.dart
│   └── models/movimiento_model.dart
├── domain/
│   ├── entities/movimiento_inventario.dart
│   ├── entities/conteo_inventario.dart
│   └── usecases/{calcular_stock.dart,valorizar_inventario.dart}
└── presentation/
    ├── inventario_list_screen.dart
    ├── kardex_screen.dart
    ├── ajuste_screen.dart
    ├── conteo_screen.dart
    └── providers/inventario_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `movimientos_inventario`, `conteos_inventario`.

## 5. Tipos de movimiento

| Tipo | Origen | Efecto |
|---|---|---|
| `entrada` | Compra | Suma |
| `salida` | Venta | Resta |
| `ajuste_positivo` | Manual / conteo | Suma |
| `ajuste_negativo` | Manual / conteo | Resta |
| `reverso` | Anulación | Resta o suma según corresponda |

## 6. Contratos / Interfaces

Ver [`contracts/inventario-contracts.md`](./contracts/inventario-contracts.md).

- `InventarioRepository.kardex(productoId)`
- `InventarioRepository.registrarAjuste(productoId, cantidad, motivo)`
- `InventarioRepository.registrarConteo(conteo)`
- `valorizarInventario(empresaId)`

## 7. Reglas de Seguridad

```
match /movimientos_inventario/{movId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create: if esRolInternoDe(request.resource.data.empresaId);
  allow update, delete: if false;   // inmutable
}

match /conteos_inventario/{conteoId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create, update: if esAdminDeEmpresa(request.resource.data.empresaId) ||
                           esGerenteDe(request.resource.data.empresaId);
  allow delete: if false;
}
```

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`
- `intl`, `flutter_riverpod`
- (Opcional) `mobile_scanner` para código de barras

## 9. Estrategia de Pruebas

- **Unit:** cálculo de stock, valorización, regla de no negativo.
- **Widget:** lista de inventario, kardex, ajuste.
- **Integration:** venta/compra que escribe el movimiento correspondiente.

## 10. Riesgos

- Concurrencia de movimientos → transacción sobre el producto.
- Descuadre por movimientos escritos fuera de transacción → prohibido.
- Reversos de anulación mal aplicados → validar doble reverso.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Kardex **inmutable** (`movimientos_inventario`); no se edita ni borra.
- **ADR-002:** `productos.stock` es la vista rápida; el kardex es la fuente de verdad.
- **ADR-003:** Movimientos en **transacción** con la operación de origen.
- **ADR-004:** El conteo físico genera **ajustes** por diferencia.
- **ADR-005:** Stock negativo solo si la empresa lo habilita y el rol lo permite.
