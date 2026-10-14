# Plan Técnico: Clientes

- **ID:** 004 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature de Flutter `clientes` con Firestore. La **dirección** se guarda como objeto embebido.
El catálogo de **departamentos y ciudades** es estático (dataset local) para no depender de red.
La **ubicación GPS** se obtiene con `geolocator` y se abre con `url_launcher` (Google Maps/Waze).

## 2. Arquitectura

```
Flutter (presentation: clientes_list, cliente_form, cliente_detalle)
   │
ClientesRepository (data)  ──►  Firestore: clientes
   │
domain:
   ├─ ValidarCliente (obligatorios, cédula única)
   └─ ObtenerUbicacion (geolocator)
   │
url_launcher ──► Google Maps / Waze
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/clientes/
├── data/
│   ├── clientes_repository.dart
│   ├── models/cliente_model.dart
│   └── ubicaciones/departamentos_ciudades.dart   # dataset local
├── domain/
│   ├── entities/cliente.dart
│   ├── entities/direccion.dart
│   ├── entities/ubicacion_gps.dart
│   └── usecases/validar_cliente.dart
└── presentation/
    ├── clientes_list_screen.dart
    ├── cliente_form_screen.dart
    ├── cliente_detalle_screen.dart
    ├── seleccion_ubicacion_screen.dart
    └── providers/clientes_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colección: `clientes`.

## 5. Ubicación GPS (tipo WhatsApp)

- Solicitar permiso con `geolocator`.
- Obtener `latitud`, `longitud` y `direccionAproximada` (geocodificación inversa).
- Guardar en el cliente.
- Abrir con `url_launcher`:
  - Google Maps: `https://www.google.com/maps/search/?api=1&query=LAT,LNG`
  - Waze: `https://waze.com/ul?ll=LAT,LNG&navigate=yes`

## 6. Contratos / Interfaces

Ver [`contracts/clientes-contracts.md`](./contracts/clientes-contracts.md).

- `ClientesRepository` (CRUD, búsqueda, por cédula, historial)
- Reglas de Firestore

## 7. Reglas de Seguridad

```
match /clientes/{clienteId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId &&
     (esRolInterno() || resource.data.uid == request.auth.uid));
  allow create, update: if esRolInternoDe(request.resource.data.empresaId) ||
    resource.data.uid == request.auth.uid;
}
```
- Un cliente solo ve/edita su propio documento.
- Vendedores/Administradores ven los clientes de su empresa.

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`
- `geolocator`, `geocoding`
- `url_launcher`
- `flutter_riverpod`

## 9. Estrategia de Pruebas

- **Unit:** validación de obligatorios, unicidad de cédula, filtro de ciudades.
- **Widget:** formulario de cliente, selector de ubicación.
- **Integration:** guardar ubicación GPS y abrir en Maps.

## 10. Riesgos

- Permisos de ubicación denegados → permitir dirección manual.
- Datos de departamentos/ciudades desactualizados → usar dataset oficial actualizado.
- Cédulas con formato variable (extranjeros) → validación flexible.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Dirección como objeto **embebido** en el cliente (no colección aparte).
- **ADR-002:** Catálogo de departamentos/ciudades **local** (dataset estático).
- **ADR-003:** Abrir mapas con `url_launcher` (sin SDK de mapas embebido).
- **ADR-004:** El cliente puede autoeditarse, pero no cambiar su `empresaId` ni su estado.
