# Contratos: Gestión de Empresas

- **ID:** 002 | **Fecha:** 2026-10-14

---

## 1. Cloud Function: `crearEmpresa`

**Tipo:** HTTPS Callable (solo Super Admin)
**Entrada:**

```json
{
  "nombre": "Comercial ABC",
  "nit": "900123456",
  "correoNotificacion": "admin@comercialabc.com",
  "telefono": "+573000000000",
  "logoUrl": "empresas/empresa_001/logo.png",
  "logoAncho": 512,
  "logoAlto": 512,
  "licencia": {
    "tipo": "mensual",
    "fechaInicio": "2026-10-14",
    "fechaFin": "2026-11-14",
    "diasAvisoVencimiento": 5
  },
  "admin": {
    "nombre": "Admin ABC",
    "email": "admin@comercialabc.com"
  }
}
```

**Salida:**

```json
{ "empresaId": "empresa_001", "adminUid": "uid_abc123" }
```

**Acciones internas (Admin SDK):**
1. Crea `empresas/{empresaId}`.
2. Crea el usuario en Auth + `usuarios/{uid}` con `roles: ["administrador"]`.
3. Asigna custom claims `{ empresaId, roles }`.
4. Crea parámetros y roles por defecto.
5. Registra auditoría.

**Errores:** `already-exists` (NIT duplicado), `invalid-argument` (fechas inválidas), `permission-denied`.

---

## 2. Cloud Function: `actualizarLicencia`

**Entrada:**

```json
{ "empresaId": "empresa_001", "tipo": "anual", "fechaInicio": "2026-11-14", "fechaFin": "2027-11-14" }
```

**Salida:** licencia actualizada y agregada a `historialPagos`.

---

## 3. Cloud Function: `cambiarEstadoEmpresa`

**Entrada:**

```json
{ "empresaId": "empresa_001", "estado": "suspendida" }
```

**Salida:** `{ "ok": true, "estado": "suspendida" }`

---

## 4. Cloud Function programada: `notificarVencimientos`

**Tipo:** Cloud Scheduler (diario, ej. 8:00 a. m.)

**Acción:**
1. Busca empresas con `fechaFin` dentro de los días de aviso y vencidas.
2. Envía **correo** al `correoNotificacion` y al Super Admin.
3. Crea **notificación in-app** en `notificaciones/{empresaId}`.

---

## 5. Reglas de Storage

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /empresas/{empresaId}/logo.png {
      allow read: if true;
      allow write: if request.auth != null &&
        (request.auth.token.superAdmin == true ||
         (request.auth.token.empresaId == empresaId &&
          request.auth.token.roles.hasAny(['administrador']))) &&
        request.resource.size < 500 * 1024;
    }
  }
}
```

---

## 6. Reglas de Firestore (resumen)

```
match /empresas/{empresaId} {
  allow read: if esSuperAdmin() || empresaId == miEmpresa();
  allow create, delete: if esSuperAdmin();
  allow update: if esSuperAdmin() ||
    (empresaId == miEmpresa() && esAdminDeEmpresa(empresaId)
     && restringeCampos(['logo','logoAncho','logoAlto','parametros','correoNotificacion']));
}

match /planes/{planId} {
  allow read: if request.auth != null;
  allow write: if esSuperAdmin();
}
```

---

## 7. Interfaz `EmpresasRepository` (Dart)

```dart
abstract class EmpresasRepository {
  Future<List<Empresa>> listar();
  Future<Empresa> crear(DatosEmpresa datos, Licencia licencia, String? logoUrl);
  Future<void> actualizarLicencia(String empresaId, Licencia licencia);
  Future<void> cambiarEstado(String empresaId, String estado);
  Future<void> subirLogo(String empresaId, File archivo);
  Future<List<Empresa>> porVencer();
}
```
