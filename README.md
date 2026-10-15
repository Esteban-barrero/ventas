# Aplicativo de Ventas

Aplicación multiplataforma de gestión de ventas (**Android, iOS y Web**) para
distribuidores, venta al detal (minorista) y al por mayor (mayorista), con
arquitectura **multi-tenant**: una sola aplicación atiende a varias empresas.

Desarrollada con **Flutter + Firebase** bajo metodología **SDD**
(Spec-Driven Development): la especificación es la fuente de verdad y el código
se deriva de ella.

---

## Índice

- [Estado del proyecto](#estado-del-proyecto)
- [Requisitos](#requisitos)
- [Cómo ejecutar](#cómo-ejecutar)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Arquitectura](#arquitectura)
- [Seguridad: roles, permisos y multi-tenant](#seguridad-roles-permisos-y-multi-tenant)
- [Licencias](#licencias)
- [Auditoría](#auditoría)
- [Funcionamiento sin conexión](#funcionamiento-sin-conexión)
- [Base de datos](#base-de-datos)
- [Especificaciones](#especificaciones)
- [Pruebas y verificación](#pruebas-y-verificación)
- [Notas y decisiones](#notas-y-decisiones)

---

## Estado del proyecto

**Spec 001 — Autenticación y Roles:** implementada y verificada.

| Funcionalidad | Estado |
|---|---|
| Login con correo/contraseña y Google Sign-In | ✅ |
| Recuperar contraseña y cerrar sesión | ✅ |
| Roles y permisos (unión de roles) | ✅ |
| Bloqueo por licencia vencida / empresa suspendida | ✅ |
| Aviso de vencimiento (5 días) | ✅ |
| Guardas de navegación por permiso | ✅ |
| Auditoría de cambios de usuarios y roles | ✅ |
| Caché de sesión para uso sin conexión | ✅ |
| Reglas de Firestore por rol y `empresaId` | ✅ |
| Interfaz de administración de usuarios | ⏳ spec 002 |
| Cloud Functions desplegadas | ⏳ requiere plan Blaze |

Las demás especificaciones (002 a 015) están definidas y pendientes de
implementación. Ver [`specs/`](./specs).

---

## Requisitos

| Herramienta | Versión usada |
|---|---|
| Flutter | 3.41.8 |
| Dart | 3.11.5 |
| Node.js | 24.21.0 |
| Firebase CLI | 15.33.0 |
| FlutterFire CLI | 1.4.1 |

Proyecto Firebase: **`aplicativo-de-ventas-d8bcd`**.

---

## Cómo ejecutar

```bash
cd app

flutter pub get

# Web (Chrome)
flutter run -d chrome --web-port=5000

# Android
flutter run -d <dispositivo>

# Analizar y probar
flutter analyze
flutter test
```

### Reglas de Firestore

```bash
cd app
firebase deploy --only "firestore:rules"
```

### Cloud Functions

```bash
# Desde la raíz del repositorio
cd functions
npm install
npm run build
firebase deploy --only functions
```

> ⚠️ El despliegue de Cloud Functions requiere el plan **Blaze** (pago por uso).
> Mientras no esté activo, la validación de licencia usa el respaldo local
> descrito en [Licencias](#licencias).

---

## Estructura del repositorio

```
.
├── AGENTS.md                 Guía para agentes de IA
├── README.md                 Este archivo
├── firebase.json             Configuración de Firebase
├── .specify/memory/          Constitución del proyecto
├── Documentacion/            Levantamiento de requerimientos (Word)
├── specs/                    Especificaciones SDD (001 a 015)
├── functions/                Cloud Functions (TypeScript)
└── app/                      Aplicación Flutter
    ├── lib/
    │   ├── core/             Utilidades transversales
    │   │   ├── avisos/       Marcos y avisos visuales reutilizables
    │   │   ├── firebase/     Helpers de Firebase
    │   │   ├── navegacion/   Guardas de navegación por permiso
    │   │   └── theme.dart    Paleta y tema
    │   ├── features/         Módulos por funcionalidad
    │   │   ├── auth/         Sesión, roles, permisos, caché
    │   │   ├── auditoria/    Registro de cambios
    │   │   ├── home/         Pantalla de inicio
    │   │   └── licencia/     Validación y bloqueo por licencia
    │   ├── firebase_options.dart
    │   └── main.dart
    ├── test/                 Pruebas
    └── firestore.rules       Reglas de seguridad
```

Cada `feature` sigue la estructura `data/` (acceso a datos), `domain/`
(entidades y reglas de negocio) y `presentation/` (interfaz).

---

## Arquitectura

- **Multi-tenant:** todo dato lleva `empresaId` y toda consulta se filtra por él.
- **RBAC:** los permisos se calculan en el cliente (`Permiso`) y se **vuelven a
  validar en el servidor** mediante las reglas de Firestore.
- **Offline-first:** Firestore guarda una copia local y sincroniza al recuperar
  la conexión; además hay una caché propia para la sesión y la licencia.
- **Auditoría centralizada:** los cambios en usuarios y roles quedan en
  `_auditoria`; la colección es de solo inserción.

---

## Seguridad: roles, permisos y multi-tenant

Los permisos efectivos de un usuario son la **unión** de los permisos de todos
sus roles (`permisosDeRoles`). Un usuario puede tener varios roles, por ejemplo
`Administrador + Developer`.

### Roles

| Rol | Alcance |
|---|---|
| **Super Admin** | Acceso global a todo. No pertenece a ninguna empresa. |
| **Administrador** | Acceso total dentro de su empresa (excepto gestión global de empresas y logs). |
| **Gerente** | Consulta y aprobaciones: reportes, inventario, caja, auditoría. |
| **Vendedor** | Ventas y sus clientes. |
| **Marketing** | Catálogo y promociones. |
| **Cajero** | Caja y cobros. |
| **Cliente** | Catálogo, pedidos e historial propios. |
| **Invitado** | Solo catálogo. |
| **Developer** | Solo logs de errores (no accede a datos del negocio). |

### Permisos por rol

`●` incluido · `—` no incluido

| Permiso | Super Admin | Admin. | Gerente | Vendedor | Marketing | Cajero | Cliente | Invitado | Developer |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Ver catálogo | ● | ● | ● | ● | ● | — | ● | ● | — |
| Editar catálogo | ● | ● | — | — | ● | — | — | — | — |
| Ver clientes | ● | ● | ● | ● | ● | ● | — | — | — |
| Gestionar clientes | ● | ● | — | ● | — | — | — | — | — |
| Ver ventas | ● | ● | ● | ● | — | ● | — | — | — |
| Registrar ventas | ● | ● | — | ● | — | — | — | — | — |
| Anular ventas | ● | ● | — | — | — | — | — | — | — |
| Ver inventario | ● | ● | ● | — | — | — | — | — | — |
| Gestionar inventario | ● | ● | — | — | — | — | — | — | — |
| Ver caja | ● | ● | ● | — | — | ● | — | — | — |
| Operar caja | ● | ● | — | — | — | ● | — | — | — |
| Ver créditos | ● | ● | ● | ● | — | ● | — | — | — |
| Gestionar créditos | ● | ● | — | — | — | ● | — | — | — |
| Ver compras | ● | ● | ● | — | — | — | — | — | — |
| Gestionar compras | ● | ● | — | — | — | — | — | — | — |
| Ver envíos | ● | ● | ● | ● | — | — | — | — | — |
| Gestionar envíos | ● | ● | — | — | — | — | — | — | — |
| Ver pedidos | ● | ● | ● | ● | ● | — | ● | — | — |
| Crear pedidos | ● | ● | — | — | — | — | ● | — | — |
| Ver reportes | ● | ● | ● | — | — | — | — | — | — |
| Gestionar usuarios | ● | ● | — | — | — | — | — | — | — |
| Gestionar empresas | ● | — | — | — | — | — | — | — | — |
| Editar parámetros | ● | ● | — | — | — | — | — | — | — |
| Ver auditoría | ● | ● | ● | — | — | — | — | — | — |
| Ver logs de errores | ● | — | — | — | — | — | — | — | ● |

> La tabla se deriva de `app/lib/features/auth/domain/roles.dart`. Si cambia
> ese archivo, actualice también esta tabla.

### Guardas de navegación

`app/lib/core/navegacion/guardia_permiso.dart` aplica doble barrera:

1. **`irAProtegido()`** no navega si falta el permiso (avisa con un mensaje).
2. **`RutaProtegida`** vuelve a comprobar al construir la pantalla, de modo que
   un acceso directo (deep link) tampoco se salta la validación.

El servidor repite la validación en `app/firestore.rules`: un usuario solo lee y
modifica datos de **su** empresa, y no puede ascenderse a sí mismo de rol.

---

## Licencias

Cada empresa tiene una licencia con fecha de inicio y fin (plan mensual, anual,
gratis o personalizado).

Cadena de validación (`licencias_repository.dart`):

1. **Cloud Function `validarLicencia`** — autoritativa (requiere plan Blaze).
2. **Respaldo local** — lee `empresas/{empresaId}` y aplica la misma lógica
   (permite operar mientras las funciones no estén desplegadas).
3. **Caché del dispositivo** — si no hay conexión, recalcula con la copia
   guardada de la empresa, usando la **fecha actual** (si la licencia venció
   sin conexión, el ingreso igualmente se bloquea).

Si nada responde, se bloquea el ingreso (*fail-closed*).

- **Aviso de vencimiento** (RN-06): banner ámbar informativo cuando faltan 5 días
  o menos. Se oculta solo a los 40 segundos o al pulsar ✕.
- **Pantalla de bloqueo:** tono cordial y mensaje amable — «Tu licencia se ha
  agotado, comunícate con tu proveedor para renovarla» — con el contacto del
  proveedor de la empresa.
- El **Super Admin** no pertenece a ninguna empresa, por lo que no se le valida
  licencia.

---

## Auditoría

Toda escritura relevante (INSERT/UPDATE/DELETE) se registra en la colección
`_auditoria`, con:

`empresaId`, `usuario`, `fecha`, `operacion`, `tabla`, `documentoId`, `campo`,
`valorViejo`, `valorNuevo`.

- Un registro **por cada campo** modificado.
- `fecha` usa la **marca de tiempo del servidor** (no la del dispositivo).
- La colección es de **solo inserción**: las reglas prohíben editar y borrar.
- Lectura: Super Admin, o Administrador/Developer de la propia empresa.
- Retención mínima: **6 meses**.

El cambio de roles (`UsuariosRepository.actualizarRoles`) compara el antes y el
después y deja constancia automáticamente.

---

## Funcionamiento sin conexión

- **Firestore**: persistencia local activada (`main.dart`). En Web vía IndexedDB.
- **Caché de sesión** (`cache_sesion.dart`, sobre `shared_preferences`):
  - Guarda el perfil (roles y `empresaId`) y el documento de la empresa.
  - Si no hay conexión al arrancar, la app entra con los datos guardados.
  - Muestra un aviso: «Sin conexión · estás viendo la información guardada».
  - Se **borra al cerrar sesión**, para no dejar datos de otra cuenta.
- Un error de **permisos** nunca usa la caché: solo los errores de red
  (`unavailable`, `deadline-exceeded`, `network-request-failed`).

---

## Base de datos

Firestore (NoSQL, con soporte offline).

| Colección | Descripción |
|---|---|
| `empresas/{empresaId}` | Datos de la empresa, estado, licencia y parámetros. |
| `usuarios/{uid}` | Perfil, `empresaId`, `roles[]`. |
| `_auditoria/{id}` | Registro de cambios (solo inserción). |
| `roles/{rolId}` | Reservada para roles personalizados por empresa. |

Las reglas de seguridad están en `app/firestore.rules` y se despliegan con
Firebase CLI. El detalle de campos está en
`specs/001-autenticacion-roles/data-model.md`.

---

## Especificaciones

| # | Especificación |
|---|---|
| 001 | [Autenticación y Roles](./specs/001-autenticacion-roles/) |
| 002 | [Gestión de Empresas](./specs/002-gestion-empresas/) |
| 003 | [Catálogo de Productos](./specs/003-catalogo-productos/) |
| 004 | [Clientes](./specs/004-clientes/) |
| 005 | [Ventas](./specs/005-ventas/) |
| 006 | [Créditos y Cobros](./specs/006-creditos-cobros/) |
| 007 | [Proveedores y Compras](./specs/007-proveedores-compras/) |
| 008 | [Inventario](./specs/008-inventario/) |
| 009 | [Caja y Trazabilidad](./specs/009-caja-trazabilidad/) |
| 010 | [Carrito y Pedidos](./specs/010-carrito-pedidos/) |
| 011 | [Envíos y Entregas](./specs/011-envios-entregas/) |
| 012 | [Auditoría](./specs/012-auditoria/) |
| 013 | [Logs de Errores](./specs/013-logs-errores/) |
| 014 | [Parámetros y Tema](./specs/014-parametros-tema/) |
| 015 | [Reportes](./specs/015-reportes/) |

Cada carpeta contiene `spec.md`, `plan.md` y `tasks.md`.

---

## Pruebas y verificación

```bash
cd app
flutter analyze   # sin errores
flutter test      # 68 pruebas
```

Las pruebas cubren: permisos y unión de roles, cálculo de la licencia, pantallas
de licencia y acceso denegado, guardas de navegación, caché de sesión,
clasificación de errores de red y el registro de auditoría.

Además, las **reglas de Firestore se verifican con ID tokens reales** (no con el
token de administrador, que las ignora). Se comprueba, entre otras cosas, que un
usuario no puede verse ascendido a Super Admin ni acceder a datos de otra
empresa.

---

## Notas y decisiones

- **`google-services.json` se versiona** (a diferencia de lo indicado en
  `AGENTS.md` §4): son identificadores públicos del cliente y el plugin de
  Gradle de Android los necesita para compilar. La seguridad real está en las
  reglas de Firestore y en Authentication. `firebase_options.dart` también se
  versiona. Ver la nota en `.gitignore`.
- **Sin pasarela de pago**: por ahora la renovación de licencias es manual.
- **Jerarquía de la fuente de verdad**: `constitución` → `spec.md` → `plan.md` →
  `tasks.md` → documento de requerimientos.

## Repositorio

- GitHub: <https://github.com/Esteban-barrero/ventas>
