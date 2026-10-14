# Contratos: Carrito y Pedidos

- **ID:** 010 | **Fecha:** 2026-10-14

---

## 1. Interfaz `CarritoRepository` (Dart)

```dart
abstract class CarritoRepository {
  Future<Carrito> obtener();                       // cliente: Firestore | invitado: local
  Future<void> agregar(ItemCarrito item);
  Future<void> quitar(String productoId);
  Future<void> cambiarCantidad(String productoId, int cantidad);
  Future<void> vaciar();
  double calcularTotal(Carrito carrito);
}
```

---

## 2. Interfaz `PedidosRepository` (Dart)

```dart
abstract class PedidosRepository {
  Future<String> crearDesdeCarrito(Carrito carrito, {
    DatosInvitado? datosInvitado,
    String tipoEntrega = 'envio',
    String? observaciones,
  });
  Future<Pedido?> obtener(String pedidoId);
  Future<List<Pedido>> listar({String? estado});
  Future<List<Pedido>> misPedidos(String clienteUid);
  Future<void> cambiarEstado(String pedidoId, String estado);
  Future<void> cancelar(String pedidoId, String motivo);
  Future<String> convertirAVenta(String pedidoId);   // reutiliza VentasRepository
}
```

---

## 3. Crear pedido (pseudocodigo)

```dart
Future<String> crearDesdeCarrito(Carrito carrito, {
  DatosInvitado? datosInvitado,
  String tipoEntrega = 'envio',
  String? observaciones,
}) async {
  if (datosInvitado != null) datosInvitado.validar();   // nombre, cedula, telefono, direccion
  if (carrito.items.isEmpty) throw CarritoVacioException();

  final ref = firestore.collection('pedidos').doc();
  await ref.set({
    'empresaId': sesion.empresaId,
    'numero': await _siguienteNumeroPedido(),
    'origen': datosInvitado == null ? 'cliente' : 'invitado',
    'clienteUid': datosInvitado == null ? sesion.uid : null,
    'invitadoNombre': datosInvitado?.nombre,
    'invitadoCedula': datosInvitado?.cedula,
    'invitadoTelefono': datosInvitado?.telefono,
    'direccion': datosInvitado?.direccion?.toMap(),
    'items': carrito.items.map((i) => i.toMap()).toList(),
    'subtotal': carrito.subtotal,
    'costoEnvio': _calcularEnvio(carrito, tipoEntrega),
    'total': carrito.subtotal + _calcularEnvio(carrito, tipoEntrega),
    'tipoEntrega': tipoEntrega,
    'observaciones': observaciones,
    'estado': 'pendiente',
    'notificado': false,
    'fechaCreacion': FieldValue.serverTimestamp(),
  });
  // La Cloud Function onCreate envia la notificacion (WhatsApp/Telegram)
  await carritoRepo.vaciar();
  return ref.id;
}
```

---

## 4. Cloud Function: notificar pedido

```javascript
exports.notificarPedido = functions.firestore
  .document('pedidos/{pedidoId}')
  .onCreate(async (snap, ctx) => {
    const p = snap.data();
    const cfg = await getConfigEmpresa(p.empresaId);   // canales, numero WA, chatId TG
    const texto = armarMensajePedido(p);

    if (cfg.whatsapp && cfg.whatsappNumero) {
      await enviarWhatsApp(cfg.whatsappNumero, texto);
    }
    if (cfg.telegram && cfg.telegramChatId) {
      await fetch(`https://api.telegram.org/bot${cfg.telegramToken}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chat_id: cfg.telegramChatId, text: texto }),
      });
    }
    await snap.ref.update({ notificado: true });
  });
```

---

## 5. Conversion a venta

```dart
Future<String> convertirAVenta(String pedidoId) async {
  final pedido = await obtener(pedidoId);
  if (pedido == null || pedido.estado == 'cancelado') {
    throw PedidoInvalidoException();
  }
  // Revalida stock y precio y delega en VentasRepository (spec 005)
  final ventaId = await ventasRepo.registrar(pedido.aVenta());
  await firestore.collection('pedidos').doc(pedidoId).update({
    'ventaId': ventaId,
    'estado': 'entregado',
  });
  return ventaId;
}
```

---

## 6. Reglas de Firestore

```
match /pedidos/{pedidoId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null && (
       esRolInternoDe(resource.data.empresaId) ||
       resource.data.clienteUid == request.auth.uid));
  allow create: if true;   // cliente o invitado
  allow update: if esRolInternoDe(resource.data.empresaId) ||
                   (request.auth != null && resource.data.clienteUid == request.auth.uid &&
                    request.resource.data.estado == 'cancelado');
  allow delete: if false;
}

match /carritos/{carritoId} {
  allow read, write: if request.auth != null &&
    request.auth.uid == resource.data.clienteUid;
}
```

> Restringir en las reglas los campos que puede escribir un **invitado**: solo datos del pedido,
> nunca precios internos ni estados finales.

---

## 7. Entidades (resumen)

```dart
class Carrito {
  String id, empresaId;
  String? clienteUid;
  List<ItemCarrito> items;
  double subtotal, total;
}

class Pedido {
  String id, empresaId, numero, origen;
  String? clienteUid, ventaId;
  String? invitadoNombre, invitadoCedula, invitadoTelefono;
  Map<String, String>? direccion;
  List<ItemCarrito> items;
  double subtotal, costoEnvio, total;
  String tipoEntrega, estado, canalNotificado;
  bool notificado;
  DateTime fechaCreacion;
}

class DatosInvitado {
  String nombre, cedula, telefono;
  Direccion direccion;
  void validar();   // todos obligatorios
}
```
