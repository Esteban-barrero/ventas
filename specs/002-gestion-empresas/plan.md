# Plan Técnico: Gestión de Empresas

- **ID:** 002 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Implementado (Cloud Functions y Storage pendientes de desplegar con Blaze)

---

## 1. Resumen Técnico

La gestión de empresas se apoya en tres piezas:

1. **Flutter** — pantallas de listado, creación, edición y tablero de vencimientos (solo Super Admin).
2. **Cloud Functions (Admin SDK)** — creación atómica de la empresa + usuario administrador + parámetros + roles, usando privilegios de administrador.
3. **Cloud Scheduler + Functions** — job diario que calcula vencimientos y envía avisos (correo y notificación in-app).

El **logo** se guarda en Firebase Storage y su URL en el documento de la empresa.

## 2. Arquitectura

```
Flutter (Super Admin)
   │  crear / editar / suspender / renovar
   ▼
Cloud Function `crearEmpresa` (Admin SDK)
   ├─► Firestore: empresas/{id}
   ├─► Auth: createUser(admin) + custom claims {empresaId, roles}
   ├─► Firestore: usuarios/{uid}
   ├─► Firestore: parametros/roles por defecto
   └─► Storage: empresas/{id}/logo.png

Cloud Scheduler (diario)
   └─► Cloud Function `notificarVencimientos`
        ├─► correo (SendGrid / Extension)
        └─► Firestore: notificaciones/{empresaId}
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/empresas/
├── data/
│   ├── empresas_repository.dart
│   └── models/empresa_model.dart
├── domain/
│   ├── entities/empresa.dart
│   ├── entities/licencia.dart
│   └── usecases/crear_empresa.dart
└── presentation/
    ├── empresas_list_screen.dart
    ├── empresa_form_screen.dart
    ├── empresa_detalle_screen.dart
    ├── tablero_vencimientos_screen.dart
    └── providers/empresas_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `empresas`, `planes`, `usuarios`.

## 5. Contratos / Interfaces

Ver [`contracts/empresas-contracts.md`](./contracts/empresas-contracts.md).

- `crearEmpresa(datos, licencia, logoUrl)` → `{ empresaId, adminUid }`
- `actualizarLicencia(empresaId, tipo, fechaInicio, fechaFin)` → licencia
- `cambiarEstadoEmpresa(empresaId, estado)`
- `notificarVencimientos()` (programada, diaria)

## 6. Reglas de Seguridad

### Firestore
- `empresas`: lectura si Super Admin o `empresaId == token.empresaId`; escritura solo Super Admin (excepto logo/parámetros/tema que puede el Administrador de esa empresa).

### Storage
```
match /empresas/{empresaId}/logo.png {
  allow read: if true;
  allow write: if request.auth.token.superAdmin == true
               || request.auth.token.empresaId == empresaId
                  && request.auth.token.roles.hasAny(['administrador']);
}
```

## 7. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`, `firebase_storage`, `cloud_functions`
- `image_picker` (selección de logo), `cached_network_image`
- `flutter_riverpod`
- Cloud Functions: `firebase-admin`, `firebase-functions`, `nodemailer`/SendGrid, `sharp` (optimizar logo)

## 8. Estrategia de Pruebas

- **Unit:** cálculo de estado de licencia (activa/por_vencer/vencida), validación de fechas.
- **Widget:** formulario de creación, tablero de vencimientos.
- **Integration emulator:** `crearEmpresa` crea empresa + admin + parámetros.

## 9. Riesgos

- Creación parcial (empresa sin admin) → usar transacción / estado "creación incompleta" + reintento.
- Costo de envío de correos → agrupar avisos del día.
- Logo pesado → comprimir/validar antes de subir.

## 10. Decisiones Técnicas (ADR)

- **ADR-001:** Crear el usuario administrador con **Admin SDK** en una Cloud Function (no desde el cliente).
- **ADR-002:** Avisos de vencimiento con **Cloud Scheduler** diario (una sola ejecución).
- **ADR-003:** Eliminación **lógica** (`estado = eliminada`) para conservar datos y auditoría.
- **ADR-004:** Guardar `logoAncho`/`logoAlto` para renderizar sin deformar.
- **ADR-005:** **Respaldo local temporal** de `crearEmpresa`. Mientras el proyecto no esté en
  Blaze, el cliente crea la empresa y su Administrador usando una **instancia secundaria** de
  Firebase (`Firebase.initializeApp(name: ...)`), de modo que no se cierra la sesión del Super
  Admin. La empresa nace en `creacion_incompleta` y pasa a `activa`/`prueba` al terminar; así un
  fallo deja un estado recuperable. Al desplegar la Cloud Function, esta pasa a mandar y el
  respaldo queda solo como contingencia sin conexión.

## 11. Estado de la Implementación

Ver [`spec.md`](./spec.md) §12 y §13 (código, verificación y criterios de aceptación).

