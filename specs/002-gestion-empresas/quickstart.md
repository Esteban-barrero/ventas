# Guía Rápida: Gestión de Empresas

- **ID:** 002 | **Fecha:** 2026-10-14

---

## Crear una empresa (Super Admin)

1. Entrar al módulo **Gestión de Empresas**.
2. Clic en **Nueva empresa**.
3. Completar datos: nombre, NIT, correo, teléfono.
4. Definir licencia: tipo (mensual/anual), fecha de inicio y fecha de fin.
5. Subir el logo (512x512 px recomendado).
6. Guardar. El sistema:
   - Crea el documento de la empresa.
   - Crea el usuario **Administrador** con credenciales temporales.
   - Crea los parámetros y roles por defecto.
7. Entregar las credenciales al cliente.

## Renovar una licencia (Super Admin)

1. Abrir la empresa.
2. Clic en **Renovar**.
3. Extender `fechaFin` (nuevo periodo).
4. Guardar (queda en `historialPagos`).

## Suspender / reactivar (Super Admin)

1. Abrir la empresa.
2. Cambiar **estado** a `suspendida` o `activa`.

## Tablero de vencimientos

Muestra tres grupos:
- **Por vencer:** licencias dentro de los días de aviso (por defecto 5).
- **Vencidas:** `fechaFin` ya pasó.
- **Activas:** vigentes sin riesgo.

## Estado de licencia

| Estado | Condición |
|---|---|
| `activa` | `fechaFin` > hoy + días de aviso |
| `por_vencer` | hoy <= `fechaFin` <= hoy + días de aviso |
| `vencida` | `fechaFin` < hoy |
| `suspendida` | estado manual de la empresa |

## Documentos relacionados

- [`spec.md`](./spec.md) — qué y por qué
- [`plan.md`](./plan.md) — cómo
- [`data-model.md`](./data-model.md) — estructura de datos
- [`contracts/empresas-contracts.md`](./contracts/empresas-contracts.md) — contratos

---

## Puesta en marcha del entorno (despliegue)

Pasos que se siguieron para dejar el proyecto operativo. Sirven para replicar el
entorno o para entender qué hace falta.

### 1. Activar el plan Blaze

Las Cloud Functions y Storage requieren **Blaze** (pago por uso, con capa gratuita):

1. Firebase Console → proyecto → **Upgrade** → **Blaze**.
2. Asociar una **cuenta de facturación** de Google Cloud (tarjeta).
3. Verificar que quedó vinculada:
   ```
   GET https://cloudbilling.googleapis.com/v1/projects/<proyecto>/billingInfo
   ```
   (`billingEnabled` debe ser `true`). Crear la cuenta de facturación **no** basta:
   hay que **vincularla** al proyecto.

### 2. Permisos de IAM para las Functions

El CLI no siempre puede fijar los *bindings* de los *service agents*. Hacen falta:

| Miembro | Rol |
|---|---|
| `service-<num>@gcp-sa-pubsub.iam.gserviceaccount.com` | `roles/iam.serviceAccountTokenCreator` |
| `<num>-compute@developer.gserviceaccount.com` | `roles/run.invoker` |
| `<num>-compute@developer.gserviceaccount.com` | `roles/eventarc.eventReceiver` |

(Si faltan, el despliegue falla con *«Failed to verify the project has the correct
IAM bindings»*.) Tras aplicarlos, Eventarc puede tardar unos minutos en propagar:
si `onUsuarioEscrito` falla, reintentar el despliegue.

### 3. Crear el bucket de Storage

`firebase deploy --only storage` exige que el bucket exista. Si la consola no se ha
usado, se crea el bucket por defecto con la API de Firebase Storage:

```
POST https://firebasestorage.googleapis.com/v1alpha/projects/<proyecto>/defaultBucket
{ "location": "us-central1" }
```

(Crear el bucket con la API cruda de GCS con el sufijo `.firebasestorage.app` falla
por verificación de dominio; la API de Storage sí lo crea correctamente.)

### 4. Desplegar

```bash
# Reglas (no requieren Blaze)
firebase deploy --only "firestore:rules"
firebase deploy --only "storage"

# Funciones (requieren Blaze). --force configura la política de limpieza de imágenes.
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions --force
```

### Notas de implementación

- **Runtime:** Node.js **22** (`nodejs22`); el 20 queda descontinuado en 2026-10-30.
- **`firebase-admin` en ESM:** el paquete `functions` es `"type": "module"`; hay que
  usar `import admin from 'firebase-admin'` (import por defecto). Con
  `import * as admin` el runtime falla con `admin.initializeApp is not a function`.
- **API key web para pruebas REST:** está en `app/lib/firebase_options.dart`
  (`web.apiKey`). Ojo: es fácil confundir un carácter.
- **Borrar cuentas por REST:** es `POST /v1/projects/<proyecto>/accounts:delete`,
  no `DELETE .../accounts`.

