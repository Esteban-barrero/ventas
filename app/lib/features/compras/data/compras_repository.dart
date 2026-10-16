import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/anexo.dart';
import '../domain/compra.dart';

/// Acceso a `compras`, su subcolección `anexos` y `cuentas_por_pagar`
/// (spec 007). Multi-tenant por `empresaId`.
///
/// La confirmación (`registrar`) corre en una **transacción**: lee los
/// productos, suma inventario, (si aplica) actualiza el costo, escribe la compra
/// y crea la cuenta por pagar (ADR-002).
class ComprasRepository {
  ComprasRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _storageOverride = storage,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseStorage? _storageOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _compras =>
      _db.collection('compras');
  CollectionReference<Map<String, dynamic>> get _cuentas =>
      _db.collection('cuentas_por_pagar');
  CollectionReference<Map<String, dynamic>> get _consecutivos =>
      _db.collection('consecutivos');

  Stream<List<Compra>> escuchar(String empresaId) {
    return _compras.where('empresaId', isEqualTo: empresaId).snapshots().map(_aLista);
  }

  Future<List<Compra>> listar(
    String empresaId, {
    String? busqueda,
    EstadoCompra? estado,
    String? proveedorId,
  }) async {
    final snap = await _compras.where('empresaId', isEqualTo: empresaId).get();
    return filtrar(_aLista(snap),
        busqueda: busqueda, estado: estado, proveedorId: proveedorId);
  }

  static List<Compra> filtrar(
    List<Compra> compras, {
    String? busqueda,
    EstadoCompra? estado,
    String? proveedorId,
  }) {
    final q = (busqueda ?? '').trim().toLowerCase();
    return compras.where((Compra c) {
      if (estado != null && c.estado != estado) return false;
      if (proveedorId != null && proveedorId.isNotEmpty && c.proveedorId != proveedorId) {
        return false;
      }
      if (q.isNotEmpty) {
        final orden = c.numeroOrden.toLowerCase();
        final prov = c.proveedorNombre.toLowerCase();
        if (!orden.contains(q) && !prov.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  Future<Compra?> obtener(String compraId) async {
    final doc = await _compras.doc(compraId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Compra.fromMap(doc.id, doc.data()!);
  }

  /// Registra una compra en una **transacción** (RN-02, RN-03):
  /// suma inventario, actualiza el costo (si aplica), crea la compra y —si es
  /// a crédito— la cuenta por pagar. Devuelve el id y el número de orden.
  Future<Compra> registrar(Compra compra) async {
    if (compra.items.isEmpty) {
      throw ArgumentError('La compra no tiene productos.');
    }
    final compraRef = _compras.doc();
    var numeroOrden = compra.numeroOrden;

    await _db.runTransaction((Transaction tx) async {
      // 1) LECTURAS (todas antes de escribir).
      final consRef = _consecutivos.doc(compra.empresaId);
      final consSnap = await tx.get(consRef);
      final actual = (consSnap.data()?['compraActual'] as num?)?.toInt() ?? 0;

      final stocks = <String, int>{};
      for (final ItemCompra it in compra.items) {
        final snap = await tx.get(_db.collection('productos').doc(it.productoId));
        if (!snap.exists) {
          throw StateError('Producto no encontrado: ${it.nombre}.');
        }
        stocks[it.productoId] = (snap.data()?['stock'] as num?)?.toInt() ?? 0;
      }

      // 2) ESCRITURAS.
      final siguiente = actual + 1;
      if (numeroOrden.trim().isEmpty) {
        numeroOrden = 'OC-${siguiente.toString().padLeft(6, '0')}';
      }
      tx.set(
        consRef,
        <String, dynamic>{'empresaId': compra.empresaId, 'compraActual': siguiente},
        SetOptions(merge: true),
      );

      for (final ItemCompra it in compra.items) {
        final datos = <String, dynamic>{
          'stock': (stocks[it.productoId] ?? 0) + it.cantidad,
          'fechaActualizacion': DateTime.now().toUtc().toIso8601String(),
        };
        if (compra.actualizaCosto) datos['costo'] = it.costoUnitario;
        tx.update(_db.collection('productos').doc(it.productoId), datos);
      }

      tx.set(compraRef, <String, dynamic>{
        ...compra.toMap(),
        'id': compraRef.id,
        'numeroOrden': numeroOrden,
        'estado': EstadoCompra.pendiente.id,
      });

      if (compra.formaPago == FormaPagoCompra.credito) {
        final cuentaRef = _cuentas.doc();
        tx.set(cuentaRef, <String, dynamic>{
          'id': cuentaRef.id,
          'empresaId': compra.empresaId,
          'proveedorId': compra.proveedorId,
          'proveedorNombre': compra.proveedorNombre,
          'compraId': compraRef.id,
          'monto': compra.valorTotal,
          'pagado': 0,
          'saldo': compra.valorTotal,
          'estado': 'pendiente',
          'fechaCreacion': DateTime.now().toUtc().toIso8601String(),
        });
      }
    });

    await _auditoria.registrarEvento(
      empresaId: compra.empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'compras',
      documentoId: compraRef.id,
      datos: <String, dynamic>{
        'numeroOrden': numeroOrden,
        'proveedorId': compra.proveedorId,
        'valorTotal': compra.valorTotal,
        'formaPago': compra.formaPago.id,
      },
    );

    final guardada = await obtener(compraRef.id);
    return guardada ?? compra;
  }

  /// Anula una compra y **revierte el inventario** (RN-04).
  Future<void> anular(String compraId, String motivo) async {
    final ref = _compras.doc(compraId);
    var empresa = '';

    await _db.runTransaction((Transaction tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw StateError('La compra no existe.');
      if ((data['estado'] as String?) == EstadoCompra.anulada.id) {
        throw StateError('La compra ya está anulada.');
      }
      empresa = (data['empresaId'] as String?) ?? '';

      // LECTURAS.
      final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>();
      final stocks = <String, int>{};
      final devoluciones = <String, int>{};
      for (final Map<dynamic, dynamic> it in items) {
        final productoId = it['productoId'] as String? ?? '';
        final cantidad = (it['cantidad'] as num?)?.toInt() ?? 0;
        if (productoId.isEmpty || cantidad <= 0) continue;
        final pSnap = await tx.get(_db.collection('productos').doc(productoId));
        if (!pSnap.exists) continue;
        stocks[productoId] = (pSnap.data()?['stock'] as num?)?.toInt() ?? 0;
        devoluciones[productoId] = (devoluciones[productoId] ?? 0) + cantidad;
      }

      // ESCRITURAS.
      for (final String productoId in stocks.keys) {
        final nuevo = (stocks[productoId] ?? 0) - (devoluciones[productoId] ?? 0);
        tx.update(_db.collection('productos').doc(productoId), <String, dynamic>{
          'stock': nuevo < 0 ? 0 : nuevo,
          'fechaActualizacion': DateTime.now().toUtc().toIso8601String(),
        });
      }
      tx.update(ref, <String, dynamic>{
        'estado': EstadoCompra.anulada.id,
        'motivoAnulacion': motivo,
      });
    });

    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'compras',
      documentoId: compraId,
      antes: <String, dynamic>{'estado': EstadoCompra.pendiente.id},
      despues: <String, dynamic>{
        'estado': EstadoCompra.anulada.id,
        'motivoAnulacion': motivo,
      },
    );
  }

  /// Marca una compra como pagada (RF-08).
  Future<void> marcarPagada(String compraId) async {
    final ref = _compras.doc(compraId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw StateError('La compra no existe.');
    final empresa = (data['empresaId'] as String?) ?? '';
    final cambios = <String, dynamic>{'estado': EstadoCompra.pagada.id};
    await ref.update(cambios);
    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'compras',
      documentoId: compraId,
      antes: <String, dynamic>{'estado': data['estado']},
      despues: cambios,
    );
  }

  // ───────────────────────────── Anexos ─────────────────────────────

  /// Escucha los anexos de una compra (RF-04..RF-06).
  Stream<List<Anexo>> escucharAnexos(String compraId) {
    return _compras
        .doc(compraId)
        .collection('anexos')
        .orderBy('fechaSubida', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
            .map((DocumentSnapshot<Map<String, dynamic>> d) =>
                Anexo.fromMap(d.id, d.data()!))
            .toList(growable: false));
  }

  /// Sube un anexo a Storage y guarda sus metadatos en
  /// `compras/{compraId}/anexos` con nombre, tipo, tamaño, fecha y usuario.
  Future<Anexo> subirAnexo(
    String empresaId,
    String compraId,
    Uint8List bytes, {
    required String nombre,
    required TipoAnexo tipo,
    required String contentType,
  }) async {
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      // Si no se puede refrescar, se intenta igualmente.
    }

    final marca = DateTime.now().millisecondsSinceEpoch;
    final path = 'empresas/$empresaId/compras/$compraId/${marca}_$nombre';
    final ref = _storage.ref(path);
    final tarea = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final url = await tarea.ref.getDownloadURL();

    final anexo = Anexo(
      id: '',
      empresaId: empresaId,
      nombre: nombre,
      tipo: tipo,
      url: url,
      tamano: bytes.lengthInBytes,
      contentType: contentType,
      fechaSubida: DateTime.now(),
      subidoPor: FirebaseAuth.instance.currentUser?.uid ?? '',
    );

    final doc = await _compras
        .doc(compraId)
        .collection('anexos')
        .add(anexo.toMap());
    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'compras/anexos',
      documentoId: doc.id,
      datos: <String, dynamic>{'nombre': nombre, 'tipo': tipo.id},
    );
    return Anexo.fromMap(doc.id, (await doc.get()).data()!);
  }

  /// Elimina un anexo (archivo en Storage y metadatos). Solo Super Admin.
  Future<void> eliminarAnexo(Anexo anexo, {required String compraId}) async {
    try {
      await _storage.refFromURL(anexo.url).delete();
    } on FirebaseException {
      // Si el archivo no existe, no es error.
    }
    await _compras.doc(compraId).collection('anexos').doc(anexo.id).delete();
  }

  List<Compra> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            Compra.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((Compra a, Compra b) =>
        (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
    return lista;
  }
}
