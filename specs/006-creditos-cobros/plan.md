# Plan Técnico: Créditos y Cobros

- **ID:** 006 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `creditos` en Flutter. El **plan de cuotas** se genera al crear el crédito. Los pagos
se registran en una **transacción** que actualiza la cuota, el crédito, la caja y la auditoría.
Una **Cloud Function programada** evalúa vencimientos y mora, y envía avisos.

## 2. Arquitectura

```
Flutter (creditos_list, credito_detalle, registrar_pago)
   │
CreditosRepository (data)
   ├─ crear credito + cuotas (transacción)
   ├─ registrarPago (transacción: cuota + credito + caja + auditoria)
   └─ actualizarMora (job)

Cloud Scheduler (diario)
   └─ Cloud Function `actualizarMoraYNotificar`
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/creditos/
├── data/
│   ├── creditos_repository.dart
│   └── models/credito_model.dart
├── domain/
│   ├── entities/credito.dart
│   ├── entities/cuota.dart
│   ├── usecases/generar_plan_cuotas.dart
│   └── usecases/calcular_mora.dart
└── presentation/
    ├── creditos_list_screen.dart
    ├── credito_detalle_screen.dart
    ├── registrar_pago_screen.dart
    └── providers/creditos_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `creditos`, `creditos/{id}/cuotas`, `pagos_credito`.

## 5. Generación del plan de cuotas (domain)

```
montoConInteres = monto * (1 + tasaInteres/100)
montoCuota      = montoConInteres / numeroCuotas
fechaCuota[i]   = fechaPrimerPago + i * intervalo(periodicidad)
ultimaCuota     = montoConInteres - montoCuota*(numeroCuotas-1)  // ajuste de redondeo
```

Intervalo: semanal = 7 días, quincenal = 15 días, mensual = 1 mes.

## 6. Contratos / Interfaces

Ver [`contracts/creditos-contracts.md`](./contracts/creditos-contracts.md).

- `CreditosRepository.crearDesdeVenta(ventaId)`
- `CreditosRepository.aprobar(creditoId)`
- `CreditosRepository.registrarPago(creditoId, monto, medioPago)`
- `actualizarMoraYNotificar()` (programada)

## 7. Reglas de Seguridad

```
match /creditos/{creditoId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId &&
     (esRolInterno() || resource.data.clienteUid == request.auth.uid));
  allow create, update: if esRolInternoDe(request.resource.data.empresaId);
  allow delete: if false;
}
```

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`, `cloud_functions`
- `intl`
- `flutter_riverpod`

## 9. Estrategia de Pruebas

- **Unit:** generación de cuotas, cálculo de mora, saldo.
- **Widget:** detalle del crédito, registrar pago.
- **Integration:** pago que actualiza cuota + crédito + caja.

## 10. Riesgos

- Redondeo de cuotas → ajustar la última.
- Concurrencia en pagos → transacción.
- Cálculo de mora dependiente de la fecha del servidor.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Cuotas como **subcolección** (facilita consultas y avisos).
- **ADR-002:** Pagos en **transacción** (cuota + crédito + caja + auditoría).
- **ADR-003:** Mora y avisos calculados por **Cloud Function programada**.
- **ADR-004:** Interés simple configurable por empresa.
