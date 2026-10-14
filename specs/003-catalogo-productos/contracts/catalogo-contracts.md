# Contratos: Catálogo de Productos

- **ID:** 003 | **Fecha:** 2026-10-14

---

## 1. Interfaz `ProductosRepository` (Dart)

```dart
abstract class ProductosRepository {
  Future<List<Producto>> listar({String? categoriaId, String? busqueda});
  Future<Producto?> obtener(String productoId);
  Future<String> crear(Producto producto);
  Future<void> actualizar(Producto producto);
  Future<void> activar(String productoId, bool activo);
  Future<void> actualizarStock(String productoId, int delta); // transacción
  Future<String> subirImagen(String empresaId, String productoId, File archivo);
}
```

---

## 2. Lógica de precio (Dart)

```dart
double calcularPrecio(double costo, double margenPct) =>
    costo * (1 + margenPct / 100);

double margenEfectivo(Producto p, ParametrosEmpresa e, String tipoVenta) {
  return p.margenes[tipoVenta] ?? e.margenGeneral(tipoVenta);
}

double costoEnvioEfectivo(Producto p, ParametrosEmpresa e) =>
    p.costoEnvio ?? e.costoEnvio;
```

---

## 3. Reglas de Firestore

```
match /productos/{productoId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId);
  allow create: if esAdminOMarketing(request.resource.data.empresaId);
  allow update, delete: if esAdminOMarketing(resource.data.empresaId);
}

match /categorias/{categoriaId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId);
  allow write: if esAdminOMarketing(resource.data.empresaId);
}
```

---

## 4. Reglas de Storage

```
match /empresas/{empresaId}/productos/{productoId}/{archivo} {
  allow read: if true;
  allow write: if request.auth != null &&
    request.auth.token.empresaId == empresaId &&
    request.auth.token.roles.hasAny(['administrador', 'marketing']) &&
    request.resource.size < 5 * 1024 * 1024; // 5 MB máximo
}
```

---

## 5. Actualización de stock (transacción)

```dart
Future<void> actualizarStock(String productoId, int delta) {
  return firestore.runTransaction((tx) async {
    final ref = firestore.collection('productos').doc(productoId);
    final snap = await tx.get(ref);
    final stock = (snap['stock'] as num).toInt();
    final nuevo = stock + delta;
    if (nuevo < 0) throw StockInsuficienteException();
    tx.update(ref, {'stock': nuevo});
  });
}
```

---

## 6. Entidades (resumen)

```dart
class Producto {
  String id;
  String empresaId;
  String codigo;
  String nombre;
  String descripcion;
  Medidas medidas;
  String categoriaId;
  String? fotoPrincipal;
  List<String> galeria;
  double costo;
  double precioDetal;
  double precioMayor;
  Map<String, double>? margenes; // contado, credito
  double? costoEnvio;
  int stock;
  int stockMinimo;
  bool activo;
}
```
