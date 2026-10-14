# Contratos: Autenticación y Roles

- **ID:** 001 | **Fecha:** 2026-10-14

---

## 1. Cloud Function: `validarLicencia`

**Tipo:** HTTPS Callable
**Entrada:**

```json
{ "empresaId": "empresa_001" }
```

**Salida:**

```json
{
  "vigente": true,
  "estado": "activa",
  "fechaInicio": "2026-10-14",
  "fechaFin": "2026-11-14",
  "diasRestantes": 31,
  "contactoProveedor": "soporte@ventasapp.com / +57 300 000 0000"
}
```

**Errores:** `not-found` (empresa inexistente), `permission-denied`.

---

## 2. Cloud Function (trigger): `onUsuarioEscrito`

**Tipo:** Firestore trigger (`usuarios/{uid}` onWrite)

**Acción:** actualizar custom claims del usuario (`empresaId`, `roles`) y
registrar el cambio en `_auditoria`.

---

## 3. Custom Claims (token)

```json
{
  "empresaId": "empresa_001",
  "roles": ["administrador"],
  "superAdmin": false
}
```

---

## 4. Reglas de Firestore (resumen)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function esSuperAdmin() {
      return request.auth != null && request.auth.token.superAdmin == true;
    }
    function miEmpresa() {
      return request.auth.token.empresaId;
    }
    function esAdminDeEmpresa(e) {
      return request.auth != null &&
             request.auth.token.empresaId == e &&
             request.auth.token.roles.hasAny(['administrador']);
    }

    match /usuarios/{uid} {
      allow read: if esSuperAdmin() || uid == request.auth.uid ||
                     resource.data.empresaId == miEmpresa();
      allow write: if esSuperAdmin() || esAdminDeEmpresa(resource.data.empresaId);
    }

    match /empresas/{empresaId} {
      allow read: if esSuperAdmin() || empresaId == miEmpresa();
      allow write: if esSuperAdmin() || esAdminDeEmpresa(empresaId);
    }
  }
}
```

---

## 5. Interfaz `AuthRepository` (Dart)

```dart
abstract class AuthRepository {
  Future<Usuario> login(String email, String password);
  Future<Usuario> loginConGoogle();
  Future<void> logout();
  Future<void> recuperarPassword(String email);
  Future<ResultadoLicencia> validarLicencia(String empresaId);
}
```
