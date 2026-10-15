# Plan Técnico: Autenticación y Roles

- **ID:** 001 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Aprobado · implementado (ver [`tasks.md`](./tasks.md))

---

## 1. Resumen Técnico

Se usará **Firebase Authentication** para la identidad y **Firestore** para el perfil,
los roles y la empresa de cada usuario. Un **claim personalizado** (`empresaId` y `roles`)
se incluirá en el token para simplificar las reglas de seguridad y las consultas.
La vigencia de la licencia se valida al iniciar sesión mediante una **Cloud Function**.

## 2. Arquitectura

```
Flutter (presentation)
   │  login / usuarios / roles
   ▼
AuthRepository (data)  ──►  Firebase Authentication
   │                        Cloud Firestore (usuarios, empresas, roles)
   │                        Cloud Function: validarLicencia
   ▼
Permisos = unión de roles (domain/usecases)
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/auth/
├── data/
│   ├── auth_repository.dart
│   └── models/usuario_model.dart
├── domain/
│   ├── entities/usuario.dart
│   ├── entities/permiso.dart
│   └── usecases/calcular_permisos.dart
└── presentation/
    ├── login_screen.dart
    ├── licencia_vencida_screen.dart
    └── providers/auth_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `empresas`, `usuarios`, `roles`.

## 5. Contratos / Interfaces

Ver [`contracts/auth-contracts.md`](./contracts/auth-contracts.md).

- Cloud Function `validarLicencia(empresaId)` → `{ vigente, estado, fechaFin, diasRestantes }`
- Cloud Function `crearUsuario(datos)` → `{ uid, enlaceActivacion }` (Super Admin o Administrador).
- Cloud Function `onUsuarioCreado` (trigger) → asigna `empresaId` y roles al token.

## 6. Reglas de Seguridad (Firestore Rules)

```
match /usuarios/{userId} {
  allow read: if request.auth != null &&
    (esSuperAdmin() || resource.data.empresaId == tokenEmpresaId() || userId == request.auth.uid);
  allow write: if esSuperAdmin() || esAdminDeEmpresa(resource.data.empresaId);
}
```

Reglas clave:
- Toda lectura/escritura se limita a `empresaId` del token.
- Solo el Administrador de la empresa gestiona usuarios.
- El Super Admin tiene acceso global.

## 7. Dependencias y Librerías

- `firebase_core`
- `firebase_auth`
- `google_sign_in`
- `cloud_firestore`
- `cloud_functions`
- `flutter_riverpod` (gestión de estado)

## 8. Estrategia de Pruebas

- **Unit:** cálculo de permisos (unión de roles), validación de licencia.
- **Widget:** pantalla de login, mensaje de licencia vencida.
- **Integration:** login real contra emulador de Firebase.

## 9. Riesgos

- Claims del token no se actualizan hasta renovar el token → forzar `getIdToken(true)` tras cambios de rol.
- Consistencia offline de roles → cachear permisos localmente.

## 10. Decisiones Técnicas (ADR)

- **ADR-001:** Usar custom claims para `empresaId` y `roles` (mejora reglas y rendimiento).
- **ADR-002:** Validar licencia en Cloud Function (evita confiar en el cliente).
- **ADR-003:** Permisos como unión de roles en una capa `domain` reutilizable.
- **ADR-004:** Crear usuarios con la Cloud Function `crearUsuario` (Admin SDK),
  que fuerza el `empresaId` del llamante, impide asignar `superadmin` y aplica el
  límite del plan. Respaldo local con una **instancia secundaria de Firebase**
  (no cierra la sesión del Administrador) cuando la función no está disponible.
