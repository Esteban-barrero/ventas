# Contratos: Proveedores y Compras

- **ID:** 007 | **Fecha:** 2026-10-14

---

## 1. Interfaz `ProveedoresRepository` (Dart)

```dart
abstract class ProveedoresRepository {
  Future<List<Proveedor>> listar();
  Future<Proveedor?> obtener(String proveedorId);
  Future<String> crear(Proveedor proveedor);
  Future<void> actualizar(Proveedor proveedor);
  Future<void> desactivar(String proveedorId);   // borrado logico
}
```

---

## 2. Interfaz `ComprasRepository` (Dart)

```dart
abstract class ComprasRepository {
  Future<List<Compra>> listar({DateTime? desde, DateTime? hasta, String? proveedorId});
  Future<Compra?> obtener(String compraId);
  Future<String> registrar(Compra compra);              // transaccion
  Future<void> anular(String compraId, String motivo);  // reverso inventario
  Future<void> marcarPagada(String compraId);

  Future<Anexo> subirAnexo(String compraId, File archivo, String tipo);
  Future<List<Anexo>> listarAnexos(String compraId);
  Future<void> eliminarAnexo(String compraId, String anexoId); // solo Super Admin
}
```

---

## 3. Transaccion `registrar` (pseudocodigo)

```dart
Future<String> registrar(Compra c) async {
  return firestore.runTransaction((tx) async {
    // 1. Sumar inventario y (opcional) actualizar costo
    for (final it in c.items) {
      final pRef = firestore.collection('productos').doc(it.productoId);
      final p = await tx.get(pRef);
      final stock = (p['stock'] as num).toInt();
      final data = {'stock': stock + it.cantidad};
      if (c.actualizaCosto) data['costo'] = it.costoUnitario;
      tx.update(pRef, data);
      // 2. movimientos_inventario (entrada)
    }

    // 3. Compra
    final cRef = firestore.collection('compras').doc();
    tx.set(cRef, {...c.toMap(), 'estado': 'pendiente'});

    // 4. Cuenta por pagar (si es a credito)
    if (c.formaPago == 'credito') {
      tx.set(firestore.collection('cuentas_por_pagar').doc(),
        {'empresaId': c.empresaId, 'proveedorId': c.proveedorId,
         'compraId': cRef.id, 'monto': c.valorTotal, 'pagado': 0,
         'saldo': c.valorTotal, 'estado': 'pendiente'});
    }

    // 5. Auditoria
    return cRef.id;
  });
}
```

---

## 4. Subida de anexos (Storage + metadata)

```dart
Future<Anexo> subirAnexo(String compraId, File archivo, String tipo) async {
  final empresaId = sesion.empresaId;
  final nombre = '${DateTime.now().millisecondsSinceEpoch}_${archivo.nombre}';
  final path = 'empresas/$empresaId/compras/$compraId/$nombre';

  final ref = storage.ref(path);
  await ref.putFile(archivo);

  final meta = {
    'empresaId': empresaId,
    'nombre': archivo.nombre,
    'tipo': tipo, // factura_escaneada | factura_pdf | anexo_legal | otro
    'url': path,
    'tamano': await archivo.length(),
    'contentType': archivo.mimeType,
    'fechaSubida': FieldValue.serverTimestamp(),
    'subidoPor': sesion.uid,
  };
  final doc = await firestore
      .collection('compras').doc(compraId)
      .collection('anexos').add(meta);
  return Anexo.fromMap(doc.id, meta);
}
```

---

## 5. Totales de compra (Dart)

```dart
double calcularTotalCompra(Compra c) =>
    c.items.fold<double>(0, (a, i) => a + i.subtotal);
```

---

## 6. Reglas de Firestore

```
match /proveedores/{proveedorId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create, update: if esAdminDeEmpresa(request.resource.data.empresaId) ||
                           esGerenteDe(request.resource.data.empresaId);
  allow delete: if false;
}

match /compras/{compraId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create, update: if esAdminDeEmpresa(request.resource.data.empresaId) ||
                           esGerenteDe(request.resource.data.empresaId);
  allow delete: if false;

  match /anexos/{anexoId} {
    allow read, create: if esAdminDeEmpresa(request.resource.data.empresaId) ||
                           esGerenteDe(request.resource.data.empresaId);
    allow delete: if esSuperAdmin();
  }
}
```

## Reglas de Storage

```
match /empresas/{empresaId}/compras/{compraId}/{archivo} {
  allow read: if request.auth.token.empresaId == empresaId && esRolInterno();
  allow write: if request.auth.token.empresaId == empresaId &&
    request.auth.token.roles.hasAny(['administrador','gerente','cajero']) &&
    request.resource.size < 10 * 1024 * 1024;
}
```

---

## 7. Entidades (resumen)

```dart
class Proveedor {
  String id, empresaId, nombre, nit, direccion, telefono, correo, contacto;
  bool activo;
}

class Compra {
  String id, empresaId, numeroOrden, proveedorId, proveedorNombre;
  DateTime fecha;
  List<ItemCompra> items;
  double valorTotal;
  String formaPago; // contado | credito | transferencia
  String estado;    // pendiente | pagada | anulada
  bool actualizaCosto;
}

class ItemCompra {
  String productoId, codigo, nombre;
  int cantidad;
  double costoUnitario, subtotal;
}

class Anexo {
  String id, nombre, tipo, url, contentType, subidoPor;
  int tamano;
  DateTime fechaSubida;
}
```
