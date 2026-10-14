# Plan Técnico: Logs de Errores

- **ID:** 013 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `logs_errores` en Flutter. La captura se hace con un **manejador global de errores**
(`FlutterError.onError` + `PlatformDispatcher.instance.onError` + `runZonedGuarded`), que arma el
log y lo escribe en `logs_errores` (o lo encola local si no hay red). Los errores de servidor los
captura una **Cloud Function** envoltorio. El módulo de consulta es **exclusivo del rol Developer**.

## 2. Arquitectura

```
App Flutter
 ├─ FlutterError.onError ─┐
 ├─ PlatformDispatcher    ├─► ErrorLogger (domain)
 └─ runZonedGuarded ──────┘        │
                                   ├─ enmascara datos sensibles
                                   ├─ arma ErrorLog
                                   └─ encola (offline) -> Firestore logs_errores

Cloud Functions
 └─ wrapper con try/catch -> logs_errores

App: modulo Logs (rol Developer) -> lista + filtros + detalle + resolver
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/logs/
├── data/
│   ├── logs_repository.dart
│   └── models/error_log_model.dart
├── domain/
│   ├── entities/error_log.dart
│   ├── services/error_logger.dart     // captura global
│   └── usecases/{enmascarar,fingerprint}.dart
└── presentation/
    ├── logs_list_screen.dart
    ├── log_detalle_screen.dart
    ├── logs_filtros_widget.dart
    └── providers/logs_provider.dart
```

Cloud Functions:
```
functions/src/logs/
├── errorWrapper.ts    // envuelve handlers y registra errores
└── limpieza.ts        // retencion / TTL
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colección: `logs_errores`.

## 5. Captura global (domain)

```
runZonedGuarded(() {
  FlutterError.onError = (detalles) => errorLogger.registrar(detalles.exception, detalles.stack);
  PlatformDispatcher.instance.onError = (error, stack) {
    errorLogger.registrar(error, stack);
    return true;
  };
  runApp(App());
}, (error, stack) => errorLogger.registrar(error, stack));
```

El **archivo/línea** se extrae del stack trace (primer frame de la app).

## 6. Contratos / Interfaces

Ver [`contracts/logs-contracts.md`](./contracts/logs-contracts.md).

- `ErrorLogger.registrar(error, stack, {modulo, opcion, accion, severidad})`
- `LogsRepository.listar(filtros)`
- `LogsRepository.marcarResuelto(logId)`

## 7. Reglas de Seguridad

```
match /logs_errores/{logId} {
  allow read: if esDeveloper();   // solo rol Developer
  allow create: if request.auth != null ||
                   request.resource.data.empresaId != null;  // app/anonimo con validacion
  allow update: if esDeveloper(); // solo para cambiar estado (resuelto)
  allow delete: if false;
}
```

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`
- `stack_trace` (parsear archivo/línea)
- `connectivity_plus` (encolar offline)
- `device_info_plus` (plataforma y versión)
- `intl`, `flutter_riverpod`

## 9. Estrategia de Pruebas

- **Unit:** enmascarado, fingerprint, extracción de archivo/línea.
- **Widget:** lista y detalle del log.
- **Integration:** provocar un error y verificar el registro.
- **Seguridad:** verificar que un no-Developer no puede leer.

## 10. Riesgos

- Bucle del logger → protección con bandera.
- Datos sensibles en el stack → enmascarar.
- Volumen alto → agrupación por huella y TTL.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Captura con **handlers globales** de Flutter.
- **ADR-002:** Acceso **exclusivo del rol Developer**.
- **ADR-003:** Logs **inmutables** salvo el estado de gestión (reconocido/resuelto).
- **ADR-004:** **Agrupación por huella** (código + archivo + línea) para no duplicar ruido.
- **ADR-005:** Encolado **offline** y envío al reconectar.
