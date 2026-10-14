# Plan Técnico: Ventas

- **ID:** 005 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `ventas` en Flutter. La confirmación de venta es una **transacción** de Firestore que:
descuenta stock, asigna número de factura consecutivo, guarda la venta y (si aplica) crea el
crédito y el movimiento de caja. Reutiliza la lógica de precio del catálogo (`domain`).

## 2. Arquitectura

```
Flutter (ventas_nueva, ventas_list, venta_detalle)
   │
VentasRepository (data)
   └─ Firestore.runTransaction:
        1. leer consecutivo  -> asignar numeroFactura
        2. leer productos    -> validar stock y calcular totales
        3. escribir venta
        4. actualizar stock + movimientos_inventario
        5. si credito  -> crear credito y plan de cobros
        6. si contado  -> crear movimiento de caja (segun medio de pago)
        7. auditoria
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/ventas/
├── data/
│   ├── ventas_repository.dart
│   └── models/venta_model.dart
├── domain/
│   ├── entities/venta.dart
│   ├── entities/item_venta.dart
│   └── usecases/calcular_totales.dart
└── presentation/
    ├── ventas_list_screen.dart
    ├── venta_nueva_screen.dart
    ├── venta_detalle_screen.dart
    ├── factura_preview_screen.dart
    └── providers/ventas_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `ventas`, `consecutivos`.

## 5. Cálculo de totales (domain)

```
subtotal = Σ (precioUnitario * cantidad)
envio    = (entrega == envio || entrega == entrega_local) ? costoEnvio : 0
total    = subtotal + envio - descuento + impuestos
```

## 6. Contratos / Interfaces

Ver [`contracts/ventas-contracts.md`](./contracts/ventas-contracts.md).

- `VentasRepository.registrar(venta)` (transacción)
- `VentasRepository.anular(ventaId, motivo)`
- `siguienteNumeroFactura(empresaId)`

## 7. Reglas de Seguridad

```
match /ventas/{ventaId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId &&
     (esRolInterno() || resource.data.clienteUid == request.auth.uid));
  allow create: if esRolInternoDe(request.resource.data.empresaId);
  allow update: if esAdminDeEmpresa(resource.data.empresaId); // anulacion
  allow delete: if false; // anulacion logica
}
```

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`
- `pdf` + `printing` (factura en PDF)
- `intl` (formato de moneda/fecha)
- `flutter_riverpod`

## 9. Estrategia de Pruebas

- **Unit:** `calcularTotales`, asignación de consecutivo, reglas de envío.
- **Widget:** pantalla de venta nueva, selección de tipo y entrega.
- **Integration:** transacción completa (stock + factura + caja/crédito).

## 10. Riesgos

- **Concurrencia de consecutivo:** usar transacción sobre `consecutivos/{empresaId}`.
- **Ventas offline:** guardar borrador y reintentar la transacción.
- **Consistencia caja/stock:** toda la operación en una sola transacción.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Confirmar la venta en una **transacción** única (atomicidad).
- **ADR-002:** Consecutivo por empresa en `consecutivos/{empresaId}`.
- **ADR-003:** Reutilizar `calcular_precio` del catálogo.
- **ADR-004:** Anulación **lógica** (`estado = anulada`) con reverso de stock.
