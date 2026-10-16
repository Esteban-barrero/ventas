---
name: Restablecer clave
description: Generar el enlace de restablecimiento (o fijar la contraseña) de un usuario de Firebase Auth usando la API de Admin con el token de la CLI, sin Firebase CLI. Útil cuando el correo del usuario no existe o no recibe mensajes.
---

# Restablecer contraseña de un usuario

Las cuentas se crean **sin contraseña** y se define con un **enlace de
restablecimiento** (`generatePasswordResetLink`). Esta herramienta genera ese
enlace (o fija la contraseña) por la **API de Admin** de Identity Toolkit, usando
el `refresh_token` de la CLI (igual que `desplegar-reglas`).

- Proyecto: `aplicativo-de-ventas-d8bcd`
- Endpoints: `accounts:lookup`, `accounts:update`, `accounts:sendOobCode`

## Uso (PowerShell, desde la raíz del repo)

```powershell
# Genera el enlace de restablecimiento (sirve aunque el correo no exista)
powershell -File .opencode/skills/restablecer-clave/scripts/restablecer-clave.ps1 -Correo usuario@correo.com

# Fija una contraseña directamente (para pruebas)
powershell -File .opencode/skills/restablecer-clave/scripts/restablecer-clave.ps1 -Correo usuario@correo.com -Clave 123456
powershell -File .opencode/skills/restablecer-clave/scripts/restablecer-clave.ps1 -Uid <uid> -Clave 123456
```

## En la app

En **Usuarios → Editar** hay un botón **"Restablecer contraseña"**. Intenta la
Cloud Function `generarEnlaceActivacion` (Admin SDK) y muestra el enlace para
copiar; si la función no está desplegada, cae a **enviar el correo** de
restablecimiento (solo llega si el correo existe).

> La Cloud Function `generarEnlaceActivacion` ya está en
> `functions/src/usuarios.ts`; falta **desplegarla** (`firebase deploy --only
> functions`) desde una máquina con Node 18+ y el Firebase CLI.
