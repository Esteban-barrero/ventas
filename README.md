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
- [Gestión de empresas (multi-tenant)](#gestión-de-empresas-multi-tenant)
- [Gestión de usuarios](#gestión-de-usuarios)
- [Auditoría](#auditoría)
- [Funcionamiento sin conexión](#funcionamiento-sin-conexión)
- [Base de datos](#base-de-datos)
- [Especificaciones](#especificaciones)
- [Pruebas y verificación](#pruebas-y-verificación)
- [Notas y decisiones](#notas-y-decisiones)

---

## Estado del proyecto

**Spec 001 — Autenticación y Roles:** implementada y verificada (incluida la
gestión de usuarios, CA-06).
**Spec 002 — Gestión de Empresas:** implementada, desplegada y verificada. El
proyecto está en el plan **Blaze** con las Cloud Functions y las reglas de
Firestore y Storage ya desplegadas.

**Spec 003 — Catálogo de Productos:** implementada (núcleo). Precios por **margen
dual contado/crédito** (general y por producto), categorías (con una **lista
estándar** sembrada y editable por empresa), fotos, costo de envío, stock con
alerta de mínimo y auditoría. Las reglas de `productos`/`categorias` están
**desplegadas**.

**Spec 004 — Clientes:** implementada (núcleo). Registro con **dirección completa**
(departamento/ciudad/dirección/barrio), **ubicación GPS** (abre en Google Maps o
Waze), clasificación (detal/mayorista), estados (activo/inactivo/moroso), límite
de crédito y auditoría. Funciona en Web; la geocodificación inversa (dirección
aproximada) solo en móvil. El **historial** de compras/pedidos llega con las
specs 005 y 010.

**Spec 005 — Ventas:** implementada (núcleo). Registro con productos y cantidades,
tipo de pago (contado/crédito), tipo de entrega, medio de pago, **factura
consecutiva por empresa** y descuento de **stock transaccional**; la anulación
revierte el stock. La **caja** (009) y la factura en PDF quedan pendientes.

**Spec 006 — Créditos y Cobros:** implementada (núcleo). La **venta a crédito
genera** el crédito y su **plan de cuotas** (semanal/quincenal/mensual, con
interés opcional); aprobación, **abonos parciales** (transacción que baja el
saldo y marca cuotas/crédito) y **cálculo de mora**. La **caja** del pago (009) y
el marcado automático de moroso por Cloud Function quedan pendientes.

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
| Listado, creación y detalle de empresas (Super Admin) | ✅ |
| Licencia, plan, renovación y suspensión | ✅ |
| Tablero de vencimientos | ✅ |
| Logo de la empresa y "Mi empresa" (Administrador) | ✅ |
| Interfaz de administración de usuarios (CA-06) | ✅ |
| Cloud Functions desplegadas | ✅ |
| Reglas de Firestore y Storage desplegadas | ✅ |

Las demás especificaciones (007 a 015) están definidas y pendientes de
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
firebase deploy --only "storage"
```

### Cloud Functions

```bash
# Desde la raíz del repositorio
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions --force
```

Funciones desplegadas:

| Función | Región | Tipo |
|---|---|---|
| `crearEmpresa` | us-central1 | Callable (Super Admin) |
| `crearUsuario` | us-central1 | Callable (Super Admin / Administrador) |
| `actualizarLicencia` | us-central1 | Callable (Super Admin) |
| `cambiarEstadoEmpresa` | us-central1 | Callable (Super Admin) |
| `validarLicencia` | us-central1 | Callable |
| `notificarVencimientos` | us-central1 | Programada (diaria 8:00) |
| `onUsuarioEscrito` | southamerica-east1 | Disparador de Firestore (claims) |

> Runtime **Node.js 22**. El proyecto está en el plan **Blaze**; los pasos
> detallados de puesta en marcha están en
> [`specs/002-gestion-empresas/quickstart.md`](./specs/002-gestion-empresas/quickstart.md).

### CORS del bucket de Storage

Flutter **Web** descarga las imágenes por HTTP (no con un `<img>`), así que el
bucket de Storage debe responder con cabeceras **CORS**; si faltan, los logos no
se ven en el navegador (el widget cae a las iniciales). La configuración está en
[`cors.json`](./cors.json):

```bash
# Requiere Google Cloud SDK (gsutil) autenticado en el proyecto.
gsutil cors set cors.json gs://aplicativo-de-ventas-d8bcd.firebasestorage.app

# Alternativa con gcloud:
gcloud storage buckets update gs://aplicativo-de-ventas-d8bcd.firebasestorage.app --cors-file=cors.json

# Verificar:
gsutil cors get gs://aplicativo-de-ventas-d8bcd.firebasestorage.app
```

> Es independiente de `app/storage.rules`: las reglas controlan **quién** puede
> leer/escribir; la CORS controla **desde qué origen** el navegador puede
> descargar el archivo.

---

## Estructura del repositorio

```
.
├── AGENTS.md                 Guía para agentes de IA
├── README.md                 Este archivo
├── firebase.json             Configuración de Firebase
├── cors.json                 CORS del bucket de Storage (logos en Web)
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
    │   │   ├── catalogo/     Productos, categorías, precios, stock
    │   │   ├── clientes/     Clientes, dirección, GPS, crédito
    │   │   ├── creditos/     Créditos, cuotas, pagos y mora
    │   │   ├── empresas/     Empresas, licencias, planes, logo
    │   │   ├── home/         Pantalla de inicio
    │   │   ├── licencia/     Validación y bloqueo por licencia
    │   │   └── ventas/       Ventas: factura, entrega y pago
    │   ├── firebase_options.dart
    │   └── main.dart
    ├── test/                 Pruebas
    ├── firestore.rules       Reglas de seguridad
    └── storage.rules         Reglas del logo en Storage
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

> **Super Admin en el inicio:** aunque tiene todos los permisos, los módulos
> *operativos* (Catálogo, Clientes, Ventas, Inventario, Caja, Reportes) solo se
> muestran a usuarios que **pertenecen a una empresa**. Un Super Admin sin
> empresa ve únicamente los módulos globales: **Empresas**, **Usuarios** y
> **Logs de errores**.

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

1. **Cloud Function `validarLicencia`** — autoritativa (ya desplegada).
2. **Respaldo local** — lee `empresas/{empresaId}` y aplica la misma lógica
   (permite operar si la función no responde).
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

## Gestión de empresas (multi-tenant)

Solo el **Super Admin** administra las empresas. Desde su panel puede:

- **Crear** una empresa definiendo su licencia (mensual/anual), su plan y su logo;
  se crean automáticamente su **Administrador** y sus **parámetros por defecto**.
- **Editar**, **renovar**, **suspender** y **reactivar** empresas.
- Ver el **tablero de vencimientos**: activas, por vencer, vencidas, suspendidas,
  en prueba y eliminadas.

El **Administrador** de cada empresa dispone del módulo **"Mi empresa"**, donde
actualiza su logo y sus parámetros (márgenes, costo de envío, tema), pero no
gestiona otras empresas.

El **logo** se guarda en Firebase Storage (`empresas/{empresaId}/logo.{ext}`).
Las reglas (`app/storage.rules`) solo permiten escribirlo al **Super Admin** o al
**Administrador de esa misma empresa**, y exigen una imagen PNG/JPG/WebP de
**máximo 500 KB**. Antes de subir, la app refresca el ID token para que las
reglas vean los *custom claims* vigentes.

Al crear una empresa se ejecuta la Cloud Function `crearEmpresa` (Admin SDK),
que en una sola operación crea el documento de la empresa, el usuario
Administrador y sus *custom claims*.

> **Respaldo local (ADR-005).** Mientras el proyecto no esté en el plan Blaze, la
> creación se hace desde el cliente con una **instancia secundaria de Firebase**
> (para no cerrar la sesión del Super Admin): la empresa nace en
> `creacion_incompleta` y pasa a `activa`/`prueba` al terminar. Al desplegar la
> Cloud Function, esta pasa a mandar; el respaldo queda solo como contingencia.

---

## Gestión de usuarios

El **Administrador** de cada empresa gestiona su equipo desde el módulo
**"Usuarios"**:

- **Crear** usuarios indicando nombre, correo, teléfono y uno o varios **roles**
  (los permisos son la **unión** de los roles). El usuario nace **activo**.
- **Editar** el nombre, el teléfono, los roles y el estado (activo/inactivo). El
  correo de acceso no se cambia desde aquí.
- **Buscar** por nombre o correo y ver el **límite de usuarios** de su plan.

El **Super Admin** ve los usuarios de **todas** las empresas y elige la empresa
al crear uno.

Al crear un usuario se ejecuta la Cloud Function `crearUsuario` (Admin SDK),
que:

- toma el `empresaId` de los *custom claims* de quien llama (un Administrador no
  puede crear usuarios en otra empresa),
- **impide** asignar el rol `superadmin` (solo lo reparte el Super Admin),
- valida el **límite de usuarios** del plan de la empresa, y
- devuelve un **enlace de activación** para que el usuario defina su contraseña.

> **Respaldo local (ADR-004).** Si la función no está disponible, la app crea la
> cuenta con una **instancia secundaria de Firebase** (sin cerrar la sesión del
> Administrador) y escribe el perfil; las reglas de Firestore permiten al
> Administrador crear usuarios en su empresa, nunca con el rol `superadmin`.

La cuenta se crea **sin contraseña**: el usuario define la suya desde el enlace
de activación o con "¿Olvidaste tu contraseña?".

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
después y deja constancia automáticamente. La creación de usuarios se audita en
el servidor (dentro de `crearUsuario`) y, en el respaldo local, desde el cliente.

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
| `empresas/{empresaId}` | Datos de la empresa, estado, licencia, parámetros y límites. |
| `usuarios/{uid}` | Perfil, `empresaId`, `roles[]`. |
| `productos/{productoId}` | Catálogo: datos, medidas, costos, márgenes, stock. |
| `categorias/{categoriaId}` | Categorías del catálogo por empresa. |
| `clientes/{clienteId}` | Clientes: datos, dirección, GPS, clasificación, estado y crédito. |
| `ventas/{ventaId}` | Ventas: ítems, tipo (contado/crédito), entrega, pago y totales. |
| `consecutivos/{empresaId}` | Último número de factura asignado por empresa. |
| `creditos/{creditoId}` | Créditos: monto, cuotas, saldo y mora. |
| `creditos/{id}/cuotas/{cuotaId}` | Cuotas del plan de pagos. |
| `pagos_credito/{pagoId}` | Abonos/pagos recibidos de un crédito. |
| `planes/{planId}` | Límites y valor por plan (gratis, básico, premium). Ya sembrados. |
| `notificaciones/{id}` | Avisos de vencimiento dentro de la app. |
| `mail/{id}` | Correos pendientes (extensión *Trigger Email*). |
| `_auditoria/{id}` | Registro de cambios (solo inserción). |
| `roles/{rolId}` | Reservada para roles personalizados por empresa. |

Las reglas de seguridad están en `app/firestore.rules` (y `app/storage.rules`
para los archivos) y se despliegan con Firebase CLI. El detalle de campos está en
`specs/001-autenticacion-roles/data-model.md`,
`specs/002-gestion-empresas/data-model.md` y
`specs/003-catalogo-productos/data-model.md`.

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
flutter test      # 173 pruebas
```

Las pruebas cubren: permisos y unión de roles, cálculo de la licencia (incluido
el de las empresas), pantallas de licencia y acceso denegado, guardas de
navegación, caché de sesión, clasificación de errores de red, el registro de
auditoría, el dominio e interfaz de la gestión de empresas (validaciones del
formulario, resumen de vencimientos y validación del logo), la gestión de
usuarios (validación de datos, roles asignables, lista, búsqueda y formulario) y
el catálogo (cálculo de precios contado/crédito, herencia de márgenes y de costo
de envío, stock, filtros y tarjetas) y los clientes (validaciones de
obligatorios y cédula única, filtro de departamento/ciudad, serialización,
filtros y listado) y las ventas (cálculo de totales, regla de envío,
serialización, filtros y listado) y los créditos (generación de cuotas, cálculo
de mora, serialización, filtros y listado).

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
- **Custom claims y licencia (2026-10-15):** la Cloud Function `validarLicencia`
  autoriza comparando el `empresaId` solicitado con el **custom claim**
  `empresaId` del ID token. Si el token no trae los claims —por ejemplo, en
  cuentas o empresas creadas con el **respaldo local** antes de desplegar las
  Functions— la función responde `403` y la app muestra «No pudimos verificar tu
  licencia». Solución: los claims deben existir (los asigna el trigger
  `onUsuarioEscrito` al escribir `usuarios/{uid}`) y la app **refresca el ID
  token** antes de validar la licencia.
- **Documentación del código (constitución, Principio 11):** todo método, clase y
  función se documentan con comentarios claros en **español** (docstrings `///`
  en Dart, JSDoc en TypeScript). Forma parte del Definition of Done.

## Repositorios y respaldos

- **Principal:** <https://github.com/Esteban-barrero/ventas> — historial completo.
- **Core (snapshot):** <https://github.com/Esteban-barrero/proyecto_core> — foto
  única del estado actual, sin historial (ver abajo).

### Repositorio `core` (snapshot)

`proyecto_core` es un espejo con **un solo commit**: solo los archivos
**versionados** (código, specs, documentación y configuración). No incluye el
historial de commits, ni artefactos locales (`build/`, `.dart_tool/`), ni
archivos sin trackear.

Se regenera desde la raíz del repositorio principal:

```bash
git archive --format=tar -o /tmp/core.tar HEAD      # 1) exportar lo versionado
mkdir /tmp/core && tar -xf /tmp/core.tar -C /tmp/core
cd /tmp/core
git init && git branch -M main && git add -A        # 2) repo nuevo, un commit
git commit -m "Snapshot del core (<fecha>)"
git remote add origin https://github.com/Esteban-barrero/proyecto_core.git
git push -f origin main                             # 3) reemplazar el snapshot
```

> En Windows: usa `tar -xf` (incluido en Win10+) y una carpeta temporal en lugar
> de `/tmp`. El `git push -f` es intencional: el repo core tiene un historial
> independiente y se reemplaza por la nueva foto.

### Respaldo de datos

El código vive en GitHub; los **datos** se respaldan en **tres capas**. El bucket
de respaldo (`aplicativo-de-ventas-backups`) debe estar en **`southamerica-east1`**,
la misma región de la base de datos.

**Firestore** (documentos de `empresas`, `usuarios`, `planes`, `_auditoria`, …):

```bash
gcloud firestore export gs://aplicativo-de-ventas-backups/firestore/<fecha>
# restaurar
gcloud firestore import gs://aplicativo-de-ventas-backups/firestore/<fecha>
```

**Authentication** (usuarios, proveedores y *custom claims*):

```bash
# Requiere Firebase CLI
firebase auth:export auth_usuarios_<fecha>.json --format=json
# restaurar
firebase auth:import auth_usuarios_<fecha>.json
```

> El archivo contiene datos sensibles (UIDs, correos, *claims*); por eso
> `auth_usuarios*.json` está en `.gitignore` y **nunca** se sube al repositorio.
> Sin Firebase CLI también se pueden listar con el Admin SDK
> (`admin.auth().listUsers()`).

**Storage** (archivos, p. ej. `empresas/{id}/logo.png`):

```bash
gcloud storage rsync -r \
  gs://aplicativo-de-ventas-d8bcd.firebasestorage.app \
  gs://aplicativo-de-ventas-backups/storage
# restaurar (se invierten origen y destino)
gcloud storage rsync -r \
  gs://aplicativo-de-ventas-backups/storage \
  gs://aplicativo-de-ventas-d8bcd.firebasestorage.app
```

> `gcloud` y `firebase` vienen del **Google Cloud SDK** y la **Firebase CLI**.
> La exportación de Firestore respalda los **documentos**; los archivos y los
> usuarios van aparte, como se muestra arriba.
