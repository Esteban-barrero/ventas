# Plan Técnico: Caja y Trazabilidad del dinero

- **ID:** 009 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `caja` en Flutter. La **caja abierta** es un documento `cajas/{cajaId}` con `estado:
abierta`. Cada ingreso/egreso escribe en `movimientos_caja` y recalcula el `saldo`. El **arqueo**
compara el conteo físico con el esperado y guarda la diferencia. La **trazabilidad del dinero** se
modela con `responsableUid` y `estadoDinero`.

## 2. Arquitectura

```
Flutter (caja_abrir, caja_panel, caja_movimiento, caja_cierre, trazabilidad)
   │
CajaRepository (data)
   ├─ abrirCaja (valida no abierta)
   ├─ registrarMovimiento (transaccion: movimiento + saldo)
   ├─ cerrarCaja (arqueo + diferencia)
   └─ estadoDinero (consulta)

Origenes de movimientos:
   ventas        -> ingreso (spec 005)
   pagos_credito -> ingreso (spec 006)
   compras       -> egreso  (spec 007)
   envios        -> en_transito -> entregado (spec 011)
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/caja/
├── data/
│   ├── caja_repository.dart
│   └── models/{caja_model,movimiento_caja_model}.dart
├── domain/
│   ├── entities/{caja,movimiento_caja,arqueo}.dart
│   └── usecases/{calcular_saldo,calcular_diferencia}.dart
└── presentation/
    ├── caja_abrir_screen.dart
    ├── caja_panel_screen.dart
    ├── caja_movimiento_screen.dart
    ├── caja_cierre_screen.dart
    ├── trazabilidad_screen.dart
    └── providers/caja_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `cajas`, `movimientos_caja`, `arqueos`.

## 5. Cálculo de saldo y diferencia (domain)

```
saldo       = montoInicial + Σ ingreso - Σ egreso
esperado    = saldo
diferencia  = efectivoContado - esperado   // + sobrante, - faltante
```

## 6. Contratos / Interfaces

Ver [`contracts/caja-contracts.md`](./contracts/caja-contracts.md).

- `CajaRepository.abrirCaja(montoInicial)`
- `CajaRepository.registrarMovimiento(...)`
- `CajaRepository.cerrarCaja(conteoFisico, justificacion)`
- `CajaRepository.estadoDinero(filtro)`

## 7. Reglas de Seguridad

```
match /cajas/{cajaId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create, update: if esRolInternoDe(request.resource.data.empresaId);
  allow delete: if false;
}

match /movimientos_caja/{movId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create: if esRolInternoDe(request.resource.data.empresaId);
  allow update, delete: if false;   // inmutable
}
```

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`
- `intl`, `flutter_riverpod`
- `pdf` + `printing` (comprobantes y cierre)

## 9. Estrategia de Pruebas

- **Unit:** cálculo de saldo y diferencia, validación de caja abierta.
- **Widget:** panel de caja, registro de movimiento, cierre.
- **Integration:** venta → movimiento de caja → saldo → arqueo.

## 10. Riesgos

- Movimientos offline que descuadran al sincronizar → reconciliación al reconectar.
- Doble apertura de caja → validación transaccional.
- Diferencia grande sin control → autorización del gerente.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Una **caja abierta por usuario** a la vez (validado en transacción).
- **ADR-002:** Movimientos de caja **inmutables** (corregir con contramovimiento).
- **ADR-003:** La caja cerrada se **bloquea**; reapertura solo Super Admin con auditoría.
- **ADR-004:** `estadoDinero` + `responsableUid` para trazabilidad del efectivo y del "contra entrega".
- **ADR-005:** El saldo se recalcula en **transacción** con cada movimiento.
