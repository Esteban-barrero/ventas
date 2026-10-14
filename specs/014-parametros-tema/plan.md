# Plan Técnico: Parámetros Generales y Tema

- **ID:** 014 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `parametros` en Flutter. La configuración vive en `parametros/{empresaId}` y las paletas en
`paletas`. El **tema se aplica en tiempo real** escuchando la paleta activa con un `StreamProvider`
y reconstruyendo `MaterialApp.theme`. La **licencia** se valida al iniciar sesión y con un job
periódico; los **avisos** los envía una **Cloud Function programada**.

## 2. Arquitectura

```
Flutter
 ├─ ParametrosRepository (data) -> parametros/{empresaId}
 ├─ PaletasRepository            -> paletas
 ├─ ThemeProvider (Stream)       -> MaterialApp (tiempo real)
 └─ LicenciaGuard                -> bloqueo al vencer
        │
Cloud Scheduler (diario)
 └─ Cloud Function verificarLicenciasYNotificar
        ├─ correo (diasAvisoVencimiento)
        └─ in-app (notificaciones)
Storage: empresas/{empresaId}/logo.png
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/parametros/
├── data/
│   ├── parametros_repository.dart
│   ├── paletas_repository.dart
│   └── models/{parametros_model,paleta_model,licencia_model}.dart
├── domain/
│   ├── entities/{parametros,paleta,licencia}.dart
│   └── usecases/{aplicar_tema,validar_logo,validar_licencia}.dart
└── presentation/
    ├── parametros_screen.dart
    ├── paletas_screen.dart
    ├── paleta_editor_screen.dart
    ├── logo_screen.dart
    ├── licencia_screen.dart
    └── providers/{parametros_provider,tema_provider}.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `parametros`, `paletas`, `licencias`.

## 5. Tema en tiempo real

```
paletaActiva$ = Firestore.collection('paletas')
    .where('empresaId', ==, empresaId)
    .where('activa', ==, true)
    .snapshots()

MaterialApp(theme: buildTheme(paletaActiva), ...)   // se reconstruye al cambiar
```

## 6. Contratos / Interfaces

Ver [`contracts/parametros-contracts.md`](./contracts/parametros-contracts.md).

- `ParametrosRepository.obtener/guardar`
- `PaletasRepository.crear/editar/duplicar/eliminar/activar`
- `LicenciaService.validar()` / `estado()`
- Cloud Function `verificarLicenciasYNotificar()`

## 7. Reglas de Seguridad

```
match /parametros/{empresaId} {
  allow read: if request.auth.token.empresaId == empresaId;
  allow write: if esAdminDeEmpresa(empresaId);
}

match /paletas/{paletaId} {
  allow read: if request.auth.token.empresaId == resource.data.empresaId;
  allow write: if esAdminDeEmpresa(request.resource.data.empresaId);
}

match /licencias/{empresaId} {
  allow read: if request.auth.token.empresaId == empresaId || esSuperAdmin();
  allow write: if esSuperAdmin();   // solo el proveedor
}
```

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`, `firebase_storage`, `cloud_functions`
- `image_picker`, `flutter_image_compress` (logo)
- `flutter_riverpod`, `intl`
- `flutter_local_notifications` (aviso in-app, opcional)

## 9. Estrategia de Pruebas

- **Unit:** validación de logo, contraste de paleta, cálculo de vencimiento.
- **Widget:** editor de paleta, cambio de tema en tiempo real.
- **Integration:** asignar licencia → aviso → vencimiento → bloqueo.

## 10. Riesgos

- Contraste bajo en paletas personalizadas → validar accesibilidad.
- Zona horaria del vencimiento → usar hora del servidor.
- Logo muy pesado → comprimir/validar.
- Avisos repetidos → control de "ya enviado".

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Tema **en tiempo real** con `StreamProvider` sobre la paleta activa.
- **ADR-002:** Paletas por empresa con **base + personalización**.
- **ADR-003:** Licencia validada al login y por **job programado**.
- **ADR-004:** Avisos por **correo + in-app** a `diasAvisoVencimiento` (mínimo 5 por defecto).
- **ADR-005:** Logo en **Storage** con **validación de tamaño en píxeles y peso**.
