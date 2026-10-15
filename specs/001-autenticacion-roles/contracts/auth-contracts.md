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
      allow create: if esSuperAdmin() || uid == request.auth.uid ||
                       (esAdminDeEmpresa(request.resource.data.empresaId) &&
                        !request.resource.data.roles.hasAny(['superadmin']));
      allow update: if esSuperAdmin() ||
                       esAdminDeEmpresa(resource.data.empresaId);
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

---

## 6. Cloud Function: `crearUsuario`

**Tipo:** HTTPS Callable (us-central1)
**Autorización:** Super Admin, o Administrador de la empresa.

**Entrada:**

```json
{
  "nombre": "Ana Pérez",
  "email": "ana@empresa.com",
  "telefono": "3001234567",
  "roles": ["vendedor"],
  "activo": true,
  "empresaId": "empresa_001"
}
```

> `empresaId` solo lo usa el Super Admin; el Administrador crea siempre dentro de
> su propia empresa (se toma de sus *custom claims*). El rol `superadmin` solo lo
> puede asignar el Super Admin.

**Salida:**

```json
{ "uid": "abc123", "enlaceActivacion": "https://…" }
```

**Errores:**

| Código | Motivo |
|---|---|
| `unauthenticated` | Sin sesión |
| `permission-denied` | No es Super Admin/Administrador, o intenta asignar `superadmin` |
| `invalid-argument` | Nombre/correo vacíos o sin roles |
| `already-exists` | El correo ya está registrado |
| `failed-precondition` | Empresa inexistente o límite de usuarios del plan alcanzado |

**Respaldo local (ADR-004):** si la función no está disponible, la app crea la
cuenta con una **instancia secundaria de Firebase** (sin cerrar la sesión del
Administrador) y escribe el perfil. Las reglas permiten al Administrador crear
usuarios en su empresa, nunca con el rol `superadmin`.
