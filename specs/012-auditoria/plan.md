# Plan Técnico: Auditoría

- **ID:** 012 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

La auditoría se genera con **Cloud Functions** (triggers de Firestore `onCreate`, `onUpdate`,
`onDelete`) que escriben en `_auditoria`. La app **nunca** escribe auditoría. La colección es
**inmutable** por reglas de seguridad. La consulta se hace desde la app con filtros y exportación.

## 2. Arquitectura

```
Escritura (app / Cloud Functions)
        │
   Firestore (colecciones auditadas)
        │  trigger
Cloud Functions (auditarCreate / auditarUpdate / auditarDelete)
        │
   _auditoria (inmutable, retencion minima 6 meses)
        │
App: modulo Auditoria (consulta + filtros + exportacion)
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/auditoria/
├── data/
│   ├── auditoria_repository.dart
│   └── models/registro_auditoria_model.dart
├── domain/
│   ├── entities/registro_auditoria.dart
│   └── usecases/{diferencias_campos,exportar_auditoria}.dart
└── presentation/
    ├── auditoria_list_screen.dart
    ├── auditoria_detalle_screen.dart
    ├── auditoria_filtros_widget.dart
    └── providers/auditoria_provider.dart
```

Cloud Functions:
```
functions/src/auditoria/
├── auditoria.ts        // configuración de colecciones y helpers
├── onWrite.ts          // onCreate / onUpdate / onDelete
└── retencion.ts        // política de retención (>= 6 meses)
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colección: `_auditoria`.

## 5. Cálculo de diferencias (domain)

```
para cada clave en despues:
  si valorAntes != valorDespues:
     cambios[campo] = { antes: valorAntes, despues: valorDespues }
```

## 6. Contratos / Interfaces

Ver [`contracts/auditoria-contracts.md`](./contracts/auditoria-contracts.md).

- Cloud Functions `auditarCreate`, `auditarUpdate`, `auditarDelete`
- `AuditoriaRepository.listar(filtros)`
- `AuditoriaRepository.exportar(filtros)`

## 7. Reglas de Seguridad

```
match /_auditoria/{registroId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId &&
     request.auth.token.roles.hasAny(['administrador','gerente','auditor']));
  allow write: if false;   // solo Cloud Functions (Admin SDK)
}
```

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`, `cloud_functions`
- Cloud Functions: `firebase-functions`, `firebase-admin`
- `intl`, `flutter_riverpod`
- `csv` + `share_plus` / `pdf` (exportación)

## 9. Estrategia de Pruebas

- **Unit:** cálculo de diferencias, filtros, formato de exportación.
- **Integration (emulador):** crear/actualizar/borrar y verificar el registro.
- **Seguridad:** verificar que el cliente no puede escribir en `_auditoria`.

## 10. Riesgos

- Volumen alto de registros → particionar por mes y TTL.
- Escrituras directas que evaden la auditoría → reglas que obligan a pasar por Functions (o auditoría en el mismo path).
- Datos sensibles en claro → enmascarar campos configurados.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Auditoría con **Cloud Functions triggers** (decidido en el proyecto).
- **ADR-002:** Colección `_auditoria` **inmutable** (write: false para clientes).
- **ADR-003:** Un registro por **operación y documento**; `cambios` con antes/después.
- **ADR-004:** Retención **mínimo 6 meses**, configurable hacia arriba.
- **ADR-005:** Cobertura por **lista configurable** de colecciones auditadas.
