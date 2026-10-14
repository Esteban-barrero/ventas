# Guía Rápida: Autenticación y Roles

- **ID:** 001 | **Fecha:** 2026-10-14

---

## Flujo de Login

1. El usuario abre la app.
2. Ingresa correo y contraseña (o Google Sign-In).
3. Firebase Authentication valida las credenciales.
4. Se obtiene el token con claims `empresaId` y `roles`.
5. Se llama a la Cloud Function `validarLicencia(empresaId)`.
   - Si la licencia está **vigente** → ingresa.
   - Si está **por vencer** → ingresa con aviso.
   - Si está **vencida/suspendida** → se bloquea y muestra contacto del proveedor.
6. Se calculan los permisos (unión de roles) y se arma la navegación.

## Ejemplo de permisos (unión)

Un usuario con roles `["vendedor", "developer"]` obtiene:

```
permisos = permisos(vendedor) ∪ permisos(developer)
```

## Ejemplo de validación de licencia (respuesta)

```json
{
  "vigente": false,
  "estado": "vencida",
  "fechaFin": "2026-11-14",
  "diasRestantes": -2,
  "contactoProveedor": "soporte@ventasapp.com / +57 300 000 0000"
}
```

## Documentos relacionados

- [`spec.md`](./spec.md) — qué y por qué
- [`plan.md`](./plan.md) — cómo
- [`data-model.md`](./data-model.md) — estructura de datos
- [`contracts/auth-contracts.md`](./contracts/auth-contracts.md) — contratos
