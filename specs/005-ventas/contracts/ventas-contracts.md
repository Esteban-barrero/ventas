# Contratos: Ventas

- **ID:** 005 | **Fecha:** 2026-10-14

---

## 1. Interfaz `VentasRepository` (Dart)

```dart
abstract class VentasRepository {
  Future<List<Venta>> listar({DateTime? desde, DateTime? hasta, String? vendedorUid});
  Future<Venta?> obtener(String ventaId);
  Future<String> registrar(Venta venta);       // transacción
  Future<void> anular(String ventaId, String motivo);
  Future<String> siguienteNumeroFactura(String empresaId); // preview
}
```

---

## 2. Transacción `registrar` (pseudocódigo)

```dart
Future<String> registrar(Venta v) async {
  return firestore.runTransaction((tx) async {
    // 1. Consecutivo
    final consRef = firestore.collection('consecutivos').doc(v.empresaId);
    final cons = await tx.get(consRef);
    final next = ((cons.data()?['facturaActual'] ?? 0) + 1);
    final numero = 'FV-${next.toString().padLeft(6, '0')}';
    tx.set(consRef, {'facturaActual': next}, SetOptions(merge: true));

    // 2. Stock
    for (final it in v.items) {
      final pRef = firestore.collection('productos').doc(it.productoId);
      final p = await tx.get(pRef);
      final stock = (p['stock'] as num).toInt();
      if (stock < it.cantidad) throw StockInsuficienteException(it.nombre);
      tx.update(pRef, {'stock': stock - it.cantidad});
    }

    // 3. Venta
    final vRef = firestore.collection('ventas').doc();
    tx.set(vRef, {...v.toMap(), 'numeroFactura': numero, 'estado': 'registrada'});

    // 4. Inventario (movimientos)
    // 5. Caja o Crédito
    // 6. Auditoría
    return vRef.id;
  });
}
```

---

## 3. Cálculo de totales (Dart)

```dart
double calcularTotal(Venta v) {
  final subtotal = v.items.fold<double>(0, (a, i) => a + i.subtotal);
  final envio = (v.tipoEntrega == 'envio' || v.tipoEntrega == 'entrega_local')
      ? v.costoEnvio : 0;
  return subtotal + envio - v.descuento + v.impuestos;
}
```

---

## 4. Reglas de Firestore

```
match /ventas/{ventaId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId &&
     (esRolInterno() || resource.data.clienteUid == request.auth.uid));
  allow create: if esRolInternoDe(request.resource.data.empresaId);
  allow update: if esAdminDeEmpresa(resource.data.empresaId);
  allow delete: if false;
}

match /consecutivos/{empresaId} {
  allow read: if esRolInternoDe(empresaId);
  allow write: if esRolInternoDe(empresaId);
}
```

---

## 5. Entidades (resumen)

```dart
class Venta {
  String id;
  String empresaId;
  String numeroFactura;
  DateTime fecha;
  String vendedorUid;
  String? clienteId;
  String? clienteUid;
  List<ItemVenta> items;
  String tipoVenta;    // contado | credito
  String tipoEntrega;  // presencial | entrega_local | recoger_local | envio
  String medioPago;    // efectivo | tarjeta | transferencia_nequi | transferencia_bancolombia
  double subtotal, costoEnvio, descuento, impuestos, total;
  String estado;       // registrada | anulada
}

class ItemVenta {
  String productoId;
  String codigo;
  String nombre;
  int cantidad;
  double precioUnitario;
  double subtotal;
}
```
