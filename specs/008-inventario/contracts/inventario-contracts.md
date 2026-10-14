# Contratos: Inventario

- **ID:** 008 | **Fecha:** 2026-10-14

---

## 1. Interfaz `InventarioRepository` (Dart)

```dart
abstract class InventarioRepository {
  Future<int> stockActual(String productoId);
  Future<List<MovimientoInventario>> kardex(String productoId, {DateTime? desde, DateTime? hasta});
  Future<List<Producto>> bajoStock();
  Future<List<Producto>> agotados();
  Future<double> valorizacionTotal();

  Future<void> registrarAjuste(String productoId, int cantidad, String motivo, {String signo = '+'});
  Future<void> registrarConteo(ConteoInventario conteo);   // genera ajustes por diferencia
}
```

---

## 2. Registro de movimiento (helper transaccional)

```dart
/// Escribe el kardex y actualiza el stock en una transaccion.
Future<void> _mover(Transaction tx, {
  required String empresaId,
  required String productoId,
  required String tipo,
  required int cantidad,
  required String referenciaTipo,
  required String referenciaId,
  required String usuarioUid,
  String bodegaId = 'principal',
  String? motivo,
}) async {
  final pRef = firestore.collection('productos').doc(productoId);
  final p = await tx.get(pRef);
  final stockAnterior = (p['stock'] as num).toInt();

  final delta = switch (tipo) {
    'entrada' || 'ajuste_positivo' || 'reverso' => cantidad,   // reverso de venta suma
    'salida' || 'ajuste_negativo'               => -cantidad,
    _ => 0,
  };
  final stockResultante = stockAnterior + delta;

  final permiteNegativo = p['permiteStockNegativo'] == true;
  if (stockResultante < 0 && !permiteNegativo) {
    throw StockInsuficienteException(p['nombre']);
  }

  tx.update(pRef, {'stock': stockResultante});
  tx.set(firestore.collection('movimientos_inventario').doc(), {
    'empresaId': empresaId,
    'productoId': productoId,
    'codigo': p['codigo'],
    'nombre': p['nombre'],
    'tipo': tipo,
    'cantidad': cantidad,
    'stockAnterior': stockAnterior,
    'stockResultante': stockResultante,
    'motivo': motivo,
    'referenciaTipo': referenciaTipo,
    'referenciaId': referenciaId,
    'bodegaId': bodegaId,
    'usuarioUid': usuarioUid,
    'fecha': FieldValue.serverTimestamp(),
  });
}
```

> Nota: `reverso` puede sumar o restar según la operacion anulada; ajustar el `delta` acorde.

---

## 3. Ajuste manual

```dart
Future<void> registrarAjuste(String productoId, int cantidad, String motivo,
    {String signo = '+'}) async {
  if (motivo.trim().isEmpty) throw MotivoRequeridoException();
  await firestore.runTransaction((tx) => _mover(tx,
    empresaId: sesion.empresaId,
    productoId: productoId,
    tipo: signo == '+' ? 'ajuste_positivo' : 'ajuste_negativo',
    cantidad: cantidad,
    referenciaTipo: 'ajuste',
    referenciaId: '-',
    motivo: motivo,
    usuarioUid: sesion.uid,
  ));
}
```

---

## 4. Conteo fisico

```dart
Future<void> registrarConteo(ConteoInventario conteo) async {
  await firestore.runTransaction((tx) async {
    for (final it in conteo.items) {
      if (it.diferencia == 0) continue;
      await _mover(tx,
        empresaId: conteo.empresaId,
        productoId: it.productoId,
        tipo: it.diferencia > 0 ? 'ajuste_positivo' : 'ajuste_negativo',
        cantidad: it.diferencia.abs(),
        referenciaTipo: 'conteo',
        referenciaId: conteo.id,
        motivo: 'Conteo fisico',
        usuarioUid: sesion.uid,
      );
    }
    tx.set(firestore.collection('conteos_inventario').doc(conteo.id), conteo.toMap());
  });
}
```

---

## 5. Valorizacion (Dart)

```dart
double valorizar(List<Producto> productos) =>
    productos.fold<double>(0, (a, p) => a + p.stock * p.costo);
```

---

## 6. Reglas de Firestore

```
match /movimientos_inventario/{movId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create: if esRolInternoDe(request.resource.data.empresaId);
  allow update, delete: if false;   // inmutable
}

match /conteos_inventario/{conteoId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create, update: if esAdminDeEmpresa(request.resource.data.empresaId) ||
                           esGerenteDe(request.resource.data.empresaId);
  allow delete: if false;
}
```

---

## 7. Entidades (resumen)

```dart
class MovimientoInventario {
  String id, empresaId, productoId, codigo, nombre;
  String tipo;          // entrada | salida | ajuste_positivo | ajuste_negativo | reverso
  int cantidad, stockAnterior, stockResultante;
  String? motivo;
  String referenciaTipo; // venta | compra | ajuste | conteo | anulacion
  String referenciaId, bodegaId, usuarioUid;
  DateTime fecha;
}

class ConteoInventario {
  String id, empresaId, bodegaId;
  String estado;        // en_proceso | cerrado | anulado
  List<ItemConteo> items;
  String usuarioUid;
  DateTime fecha;
}
```
