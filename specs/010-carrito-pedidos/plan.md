# Plan Técnico: Carrito y Pedidos

- **ID:** 010 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `pedidos` en Flutter. El **carrito** del cliente vive en Firestore (`carritos/{carritoId}`);
el del invitado en `shared_preferences`. Al **realizar el pedido** se crea `pedidos/{pedidoId}` y
una **Cloud Function** envía la notificación por WhatsApp/Telegram. La conversión a venta reutiliza
el repositorio de ventas.

## 2. Arquitectura

```
Flutter (catalogo_cliente, carrito, checkout, mis_pedidos)
   │
CarritoRepository   -> carritos (cliente) | local (invitado)
PedidosRepository   -> pedidos + items + estado
   │
Cloud Function (onCreate pedido) -> notificar WhatsApp / Telegram
Cloud Function (cambio estado)   -> notificar al cliente (opcional)
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/pedidos/
├── data/
│   ├── carrito_repository.dart
│   ├── pedidos_repository.dart
│   └── models/{carrito_model,pedido_model}.dart
├── domain/
│   ├── entities/{carrito,item_carrito,pedido}.dart
│   └── usecases/{calcular_totales,convertir_a_venta}.dart
└── presentation/
    ├── carrito_screen.dart
    ├── checkout_screen.dart          // datos del invitado
    ├── confirmacion_screen.dart
    ├── mis_pedidos_screen.dart
    └── providers/pedidos_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `carritos`, `pedidos`.

## 5. Notificaciones

- **WhatsApp:** enlace `https://wa.me/<numero>?text=<pedido>` (abre la app) y/o Cloud Function con
  proveedor de API (según configuración de la empresa).
- **Telegram:** Cloud Function llama a la **Bot API** (`sendMessage`) con el `chatId` configurado.
- El **formato** del mensaje se arma desde los datos del pedido.

## 6. Contratos / Interfaces

Ver [`contracts/pedidos-contracts.md`](./contracts/pedidos-contracts.md).

- `CarritoRepository.agregar/quitar/obtener`
- `PedidosRepository.crearDesdeCarrito(carrito, datosInvitado?)`
- `PedidosRepository.cambiarEstado(pedidoId, estado)`
- `PedidosRepository.convertirAVenta(pedidoId)`

## 7. Reglas de Seguridad

```
match /pedidos/{pedidoId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null && (
       esRolInternoDe(resource.data.empresaId) ||
       resource.data.clienteUid == request.auth.uid));
  allow create: if true;   // invitado puede crear (validado por reglas especificas)
  allow update: if esRolInternoDe(resource.data.empresaId) ||
                   (request.auth != null && resource.data.clienteUid == request.auth.uid &&
                    request.resource.data.estado == 'cancelado');
  allow delete: if false;
}
```

> Las reglas deben restringir qué campos puede escribir un invitado (solo datos del pedido, nunca
> precios internos).

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`, `cloud_functions`
- `shared_preferences` (carrito del invitado)
- `url_launcher` (WhatsApp)
- `intl`, `flutter_riverpod`

## 9. Estrategia de Pruebas

- **Unit:** totales del carrito, conversión a venta, plantilla de mensaje.
- **Widget:** carrito, checkout de invitado, mis pedidos.
- **Integration:** crear pedido → Cloud Function → notificación (emulador).

## 10. Riesgos

- Stock/precio cambian entre carrito y pedido → revalidar al confirmar.
- Invitado escribe datos inválidos → validación fuerte.
- Fallo de notificación → reintento y aviso dentro de la app.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Carrito en **Firestore** (cliente) y **local** (invitado).
- **ADR-002:** Pedido **bloquea precio**; el stock se descuenta al convertirse en venta.
- **ADR-003:** Notificación vía **Cloud Function** a WhatsApp/Telegram (canales configurables).
- **ADR-004:** La **conversión a venta** reutiliza `VentasRepository` (spec 005).
