# Plan Técnico: Envíos y Entregas

- **ID:** 011 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `envios` en Flutter. Cada envío es un documento `envios/{envioId}` que referencia la venta
o el pedido de origen. Los cambios de estado se registran con historial y disparan notificación al
cliente. La evidencia se sube a **Firebase Storage**. El **contra entrega** se conecta con la caja
(spec 009) para el estado del dinero.

## 2. Arquitectura

```
Flutter (envios_list, envio_detalle, despacho, evidencia, rastreo_cliente)
   │
EnviosRepository (data)
   ├─ crearDesdeVenta(ventaId) / crearDesdePedido(pedidoId)
   ├─ cambiarEstado(envioId, estado, {evidencia})
   └─ asignarRepartidor(envioId, repartidorUid)

Cloud Function (cambio estado) -> notificar cliente (WhatsApp/Telegram)
Integracion:
   caja    -> contra entrega (en_transito -> entregado) [spec 009]
   inventario -> reingreso por devolucion [spec 008]
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/envios/
├── data/
│   ├── envios_repository.dart
│   └── models/envio_model.dart
├── domain/
│   ├── entities/envio.dart
│   ├── entities/estado_envio.dart
│   └── usecases/calcular_costo_envio.dart
└── presentation/
    ├── envios_list_screen.dart
    ├── envio_detalle_screen.dart
    ├── despacho_screen.dart
    ├── evidencia_screen.dart
    ├── rastreo_cliente_screen.dart
    └── providers/envios_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `envios`, `empresas_envio`.

## 5. Estados del envío

```
preparando -> despachado -> en_transito -> en_reparto -> entregado
                                                  |-> devuelto
                                                  |-> novedad
```

## 6. Contratos / Interfaces

Ver [`contracts/envios-contracts.md`](./contracts/envios-contracts.md).

- `EnviosRepository.crearDesdeVenta(ventaId, datosEnvio)`
- `EnviosRepository.cambiarEstado(envioId, estado, {evidenciaUrl, firmaUrl})`
- `EnviosRepository.asignarRepartidor(envioId, repartidorUid)`
- `EnviosRepository.rastrear(envioId)`

## 7. Reglas de Seguridad

```
match /envios/{envioId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null && (
       esRolInternoDe(resource.data.empresaId) ||
       resource.data.clienteUid == request.auth.uid));
  allow create, update: if esRolInternoDe(request.resource.data.empresaId);
  allow delete: if false;
}

match /empresas_envio/{empresaEnvioId} {
  allow read: if esRolInternoDe(resource.data.empresaId);
  allow write: if esAdminDeEmpresa(request.resource.data.empresaId);
}
```

Storage:
```
match /empresas/{empresaId}/evidencias/{archivo} {
  allow read: if request.auth.token.empresaId == empresaId && esRolInterno();
  allow write: if request.auth.token.empresaId == empresaId &&
    request.auth.token.roles.hasAny(['administrador','vendedor','repartidor']) &&
    request.resource.size < 10 * 1024 * 1024;
}
```

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`, `firebase_storage`, `cloud_functions`
- `image_picker` (evidencia), `url_launcher` (WhatsApp/Maps), `signature` (firma)
- `intl`, `flutter_riverpod`

## 9. Estrategia de Pruebas

- **Unit:** transición de estados, cálculo de costo de envío.
- **Widget:** despacho, evidencia, rastreo del cliente.
- **Integration:** despachar → en tránsito → entregar con evidencia + contra entrega a caja.

## 10. Riesgos

- Estados fuera de orden → máquina de estados con validación.
- Evidencia no subida → bloquear `entregado` si la empresa lo exige.
- Contra entrega sin cuadre → integrar con spec 009.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** El envío es un documento propio que **referencia** venta o pedido.
- **ADR-002:** Estados con **historial** (`historialEstados`) para trazar tiempos.
- **ADR-003:** Evidencia en **Storage**; URL en el envío.
- **ADR-004:** Notificación al cliente por **Cloud Function** en cada cambio.
- **ADR-005:** Devolución con **reingreso de stock** configurable (spec 008).
