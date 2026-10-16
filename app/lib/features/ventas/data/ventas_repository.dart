import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/venta.dart';

/// Stock insuficiente al confirmar la venta (transacción, RN-05).
class StockInsuficienteVentaException implements Exception {
  const StockInsuficienteVentaException(
    this.producto,
    this.disponible,
    this.solicitado,
  );

  final String producto;
  final int disponible;
  final int solicitado;

  @override
  String toString() =>
      'Stock insuficiente de "$producto": hay $disponible y se pidieron $solicitado.';
}

/// Acceso a `ventas` y `consecutivos` (spec 005). Multi-tenant por `empresaId`.
///
/// La confirmación (`registrar`) y la anulación corren en una **transacción**
/// de Firestore: asignan el número de factura, descuentan/repiten el stock y
/// escriben la venta de forma atómica (ADR-001).
class VentasRepository {
  VentasRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ventas =>
      _db.collection('ventas');

  CollectionReference<Map<String, dynamic>> get _consecutivos =>
      _db.collection('consecutivos');

  /// Escucha, en tiempo real, las ventas de una empresa (más recientes primero).
  Stream<List<Venta>> escuchar(String empresaId) {
    return _ventas
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map(_aLista);
  }

  /// Lista las ventas de una empresa con filtros opcionales.
  Future<List<Venta>> listar(
    String empresaId, {
    String? busqueda,
    EstadoVenta? estado,
    String? vendedorUid,
  }) async {
    final snap = await _ventas.where('empresaId', isEqualTo: empresaId).get();
    return filtrar(_aLista(snap),
        busqueda: busqueda, estado: estado, vendedorUid: vendedorUid);
  }

  /// Filtra ventas por búsqueda (factura/cliente), estado y vendedor.
  static List<Venta> filtrar(
    List<Venta> ventas, {
    String? busqueda,
    EstadoVenta? estado,
    String? vendedorUid,
  }) {
    final q = (busqueda ?? '').trim().toLowerCase();
    return ventas.where((Venta v) {
      if (estado != null && v.estado != estado) return false;
      if (vendedorUid != null &&
          vendedorUid.isNotEmpty &&
          v.vendedorUid != vendedorUid) {
        return false;
      }
      if (q.isNotEmpty) {
        final factura = v.numeroFactura.toLowerCase();
        final cliente = v.clienteNombre.toLowerCase();
        if (!factura.contains(q) && !cliente.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);
  }

  /// Obtiene una venta por su id.
  Future<Venta?> obtener(String ventaId) async {
    final doc = await _ventas.doc(ventaId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Venta.fromMap(doc.id, doc.data()!);
  }

  /// Vista previa del próximo número de factura (sin consumirlo).
  Future<String> siguienteNumeroFactura(String empresaId) async {
    final doc = await _consecutivos.doc(empresaId).get();
    final data = doc.data() ?? const <String, dynamic>{};
    final actual = (data['facturaActual'] as num?)?.toInt() ?? 0;
    final prefijo = (data['prefijo'] as String?) ?? 'FV-';
    return _formatear(prefijo, actual + 1);
  }

  /// Registra la venta en una transacción: número de factura consecutivo, stock
  /// y la venta. Devuelve el id de la venta.
  Future<String> registrar(Venta venta) async {
    if (venta.items.isEmpty) {
      throw ArgumentError('La venta no tiene productos.');
    }

    final ventaRef = _ventas.doc();
    var numeroFinal = venta.numeroFactura;

    await _db.runTransaction((Transaction tx) async {
      // 1) Consecutivo de factura por empresa (RN-04).
      final consRef = _consecutivos.doc(venta.empresaId);
      final consSnap = await tx.get(consRef);
      final actual = (consSnap.data()?['facturaActual'] as num?)?.toInt() ?? 0;
      final prefijo = (consSnap.data()?['prefijo'] as String?) ?? 'FV-';
      final siguiente = actual + 1;
      numeroFinal = _formatear(prefijo, siguiente);
      tx.set(
        consRef,
        <String, dynamic>{
          'empresaId': venta.empresaId,
          'facturaActual': siguiente,
          'prefijo': prefijo,
        },
        SetOptions(merge: true),
      );

      // 2) Stock de cada producto (RN-05).
      for (final ItemVenta it in venta.items) {
        final pRef = _db.collection('productos').doc(it.productoId);
        final pSnap = await tx.get(pRef);
        final data = pSnap.data();
        if (data == null) {
          throw StateError('Producto no encontrado: ${it.nombre}.');
        }
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        if (stock < it.cantidad) {
          throw StockInsuficienteVentaException(it.nombre, stock, it.cantidad);
        }
        tx.update(pRef, <String, dynamic>{
          'stock': stock - it.cantidad,
          'fechaActualizacion': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // 3) La venta.
      tx.set(ventaRef, <String, dynamic>{
        ...venta.toMap(),
        'id': ventaRef.id,
        'numeroFactura': numeroFinal,
        'estado': EstadoVenta.registrada.id,
      });
    });

    final datos = <String, dynamic>{
      ...venta.toMap(),
      'id': ventaRef.id,
      'numeroFactura': numeroFinal,
      'estado': EstadoVenta.registrada.id,
    };
    await _auditoria.registrarEvento(
      empresaId: venta.empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'ventas',
      documentoId: ventaRef.id,
      datos: datos,
    );
    return ventaRef.id;
  }

  /// Anula una venta (lógica) y **revierte el stock** en una transacción
  /// (RN-06). Devuelve nada; lanza si la venta no existe o ya está anulada.
  Future<void> anular(
    String ventaId,
    String motivo, {
    String? empresaId,
  }) async {
    final ref = _ventas.doc(ventaId);
    var empresa = empresaId ?? '';

    await _db.runTransaction((Transaction tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw StateError('La venta no existe.');
      if ((data['estado'] as String?) == EstadoVenta.anulada.id) {
        throw StateError('La venta ya está anulada.');
      }
      empresa = (data['empresaId'] as String?) ?? empresa;

      final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>();
      for (final Map<dynamic, dynamic> it in items) {
        final productoId = it['productoId'] as String? ?? '';
        final cantidad = (it['cantidad'] as num?)?.toInt() ?? 0;
        if (productoId.isEmpty || cantidad <= 0) continue;
        final pRef = _db.collection('productos').doc(productoId);
        final pSnap = await tx.get(pRef);
        if (!pSnap.exists) continue;
        final stock = (pSnap.data()?['stock'] as num?)?.toInt() ?? 0;
        tx.update(pRef, <String, dynamic>{
          'stock': stock + cantidad,
          'fechaActualizacion': DateTime.now().toUtc().toIso8601String(),
        });
      }

      tx.update(ref, <String, dynamic>{
        'estado': EstadoVenta.anulada.id,
        'motivoAnulacion': motivo,
      });
    });

    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'ventas',
      documentoId: ventaId,
      antes: <String, dynamic>{'estado': EstadoVenta.registrada.id},
      despues: <String, dynamic>{
        'estado': EstadoVenta.anulada.id,
        'motivoAnulacion': motivo,
      },
    );
  }

  String _formatear(String prefijo, int numero) =>
      '$prefijo${numero.toString().padLeft(6, '0')}';

  List<Venta> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            Venta.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((Venta a, Venta b) =>
        (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
    return lista;
  }
}
