import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/producto.dart';

/// El código de producto ya existe dentro de la empresa (RN-06).
class CodigoDuplicadoException implements Exception {
  const CodigoDuplicadoException(this.codigo);

  final String codigo;

  @override
  String toString() => 'Ya existe un producto con el código "$codigo".';
}

/// No hay stock suficiente para descontar (transacción, RN-07).
class StockInsuficienteException implements Exception {
  const StockInsuficienteException(this.disponible, this.solicitado);

  final int disponible;
  final int solicitado;

  @override
  String toString() =>
      'Stock insuficiente: hay $disponible y se pidieron $solicitado.';
}

/// Acceso a la colección `productos` (spec 003). Multi-tenant por `empresaId`.
///
/// Los filtros por categoría y la búsqueda se aplican **en el cliente** para no
/// depender de índices compuestos en Firestore (ADR-004); el volumen por empresa
/// es manejable. El stock se actualiza con **transacciones** (ADR-003).
class ProductosRepository {
  ProductosRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productos =>
      _db.collection('productos');

  /// Escucha, en tiempo real, los productos de una empresa.
  Stream<List<Producto>> escuchar(String empresaId) {
    return _productos
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map(_aLista);
  }

  /// Lista los productos de una empresa, con filtros opcionales.
  Future<List<Producto>> listar(
    String empresaId, {
    String? categoriaId,
    String? busqueda,
    bool soloActivos = false,
  }) async {
    final snap =
        await _productos.where('empresaId', isEqualTo: empresaId).get();
    return filtrar(
      _aLista(snap),
      categoriaId: categoriaId,
      busqueda: busqueda,
      soloActivos: soloActivos,
    );
  }

  /// Aplica los filtros de la lista (categoría, búsqueda y estado).
  ///
  /// La búsqueda es por **prefijo** en nombre o código (ADR-004).
  static List<Producto> filtrar(
    List<Producto> productos, {
    String? categoriaId,
    String? busqueda,
    bool soloActivos = false,
  }) {
    final q = (busqueda ?? '').trim().toLowerCase();
    return productos.where((p) {
      if (soloActivos && !p.activo) return false;
      if (categoriaId != null &&
          categoriaId.isNotEmpty &&
          p.categoriaId != categoriaId) {
        return false;
      }
      if (q.isNotEmpty) {
        final nombre = p.nombre.toLowerCase();
        final codigo = p.codigo.toLowerCase();
        if (!nombre.contains(q) && !codigo.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Obtiene un producto por su id.
  Future<Producto?> obtener(String productoId) async {
    final doc = await _productos.doc(productoId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Producto.fromMap(doc.id, doc.data()!);
  }

  /// `true` si ya existe un producto con ese código en la empresa (RN-06).
  ///
  /// [exceptoId] permite excluir el propio producto al editarlo.
  Future<bool> codigoExiste(
    String empresaId,
    String codigo, {
    String? exceptoId,
  }) async {
    final objetivo = codigo.trim().toLowerCase();
    if (objetivo.isEmpty) return false;
    final productos = await listar(empresaId);
    return productos.any((p) =>
        p.id != exceptoId && p.codigo.trim().toLowerCase() == objetivo);
  }

  /// Genera un id nuevo para un producto (sin escribir todavía).
  ///
  /// Permite usar la ruta de Storage `empresas/{empresaId}/productos/{id}/...`
  /// antes de crear el documento.
  String nuevoId() => _productos.doc().id;

  /// Crea un producto y deja constancia en la auditoría. Devuelve su id.
  Future<String> crear(Producto producto) async {
    final codigo = producto.codigo.trim();
    if (codigo.isEmpty) throw ArgumentError('El código es obligatorio.');
    if (producto.nombre.trim().isEmpty) {
      throw ArgumentError('El nombre es obligatorio.');
    }
    if (await codigoExiste(producto.empresaId, codigo, exceptoId: producto.id)) {
      throw CodigoDuplicadoException(codigo);
    }

    final ref =
        producto.id.isNotEmpty ? _productos.doc(producto.id) : _productos.doc();
    final datos = producto.toMap()..['id'] = ref.id;
    await ref.set(datos);

    await _auditoria.registrarEvento(
      empresaId: producto.empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'productos',
      documentoId: ref.id,
      datos: datos,
    );
    return ref.id;
  }

  /// Actualiza un producto y registra los cambios en la auditoría.
  Future<void> actualizar(Producto producto) async {
    final ref = _productos.doc(producto.id);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};
    final despues = producto.toMap();

    final antesParcial = <String, dynamic>{
      for (final clave in despues.keys) clave: antes[clave],
    };

    await ref.set(despues, SetOptions(merge: true));

    await _auditoria.registrarCambios(
      empresaId: producto.empresaId,
      tabla: 'productos',
      documentoId: producto.id,
      antes: antesParcial,
      despues: despues,
    );
  }

  /// Activa o desactiva un producto (RN-08: no se borra, se oculta).
  Future<void> activar(String productoId, bool activo, {String? empresaId}) async {
    final ref = _productos.doc(productoId);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};
    final empresa = empresaId ?? (antes['empresaId'] as String?) ?? '';
    final despues = <String, dynamic>{
      'activo': activo,
      'fechaActualizacion': DateTime.now().toUtc().toIso8601String(),
    };
    await ref.update(despues);
    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'productos',
      documentoId: productoId,
      antes: <String, dynamic>{'activo': antes['activo']},
      despues: despues,
    );
  }

  /// Suma (o resta, con `delta` negativo) unidades con una **transacción**
  /// (ADR-003). Lanza [StockInsuficienteException] si el resultado es negativo.
  ///
  /// [motivo] y [referenciaId] describen el movimiento (venta, compra, ajuste).
  Future<void> actualizarStock(
    String productoId,
    int delta, {
    String motivo = 'ajuste',
    String? referenciaId,
  }) async {
    final ref = _productos.doc(productoId);
    var empresa = '';
    var stockAntes = 0;
    var stockDespues = 0;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw StateError('El producto no existe.');
      empresa = (data['empresaId'] as String?) ?? '';
      stockAntes = (data['stock'] as num?)?.toInt() ?? 0;
      stockDespues = stockAntes + delta;
      if (stockDespues < 0) {
        throw StockInsuficienteException(stockAntes, delta.abs());
      }
      tx.update(ref, <String, dynamic>{
        'stock': stockDespues,
        'fechaActualizacion': DateTime.now().toUtc().toIso8601String(),
      });
    });

    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'productos',
      documentoId: productoId,
      antes: <String, dynamic>{'stock': stockAntes},
      despues: <String, dynamic>{'stock': stockDespues},
      autor: null,
    );
  }

  List<Producto> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            Producto.fromMap(d.id, d.data()!))
        .toList();
    lista.sort(
        (Producto a, Producto b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }
}
