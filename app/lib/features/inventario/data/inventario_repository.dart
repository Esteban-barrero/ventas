import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/conteo_inventario.dart';
import '../domain/movimiento_inventario.dart';
import 'kardex.dart';

/// Un ajuste sin motivo no es válido (RN-05).
class MotivoRequeridoException implements Exception {
  const MotivoRequeridoException();

  @override
  String toString() => 'El motivo es obligatorio para un ajuste.';
}

/// El movimiento dejaría el stock negativo y la empresa no lo permite (RN-02).
class StockNoPermitidoException implements Exception {
  const StockNoPermitidoException(this.producto);

  final String producto;

  @override
  String toString() => 'El ajuste dejaría el stock de "$producto" en negativo.';
}

/// Movimientos de inventario (kardex) y conteos físicos (spec 008).
class InventarioRepository {
  InventarioRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _movimientos =>
      _db.collection('movimientos_inventario');
  CollectionReference<Map<String, dynamic>> get _conteos =>
      _db.collection('conteos_inventario');
  CollectionReference<Map<String, dynamic>> get _productos =>
      _db.collection('productos');

  /// Escucha el **kardex** de un producto (más reciente primero).
  ///
  /// Se filtra por `empresaId` (lo exigen las reglas de Firestore) y por
  /// `productoId` en el cliente, para no necesitar índices compuestos.
  Stream<List<MovimientoInventario>> kardex(
    String empresaId,
    String productoId,
  ) {
    return _movimientos
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) => _aLista(snap)
            .where((MovimientoInventario m) => m.productoId == productoId)
            .toList(growable: false));
  }

  /// Lista el kardex de un producto (lectura puntual).
  Future<List<MovimientoInventario>> movimientos(
    String empresaId,
    String productoId,
  ) async {
    final snap =
        await _movimientos.where('empresaId', isEqualTo: empresaId).get();
    return _aLista(snap)
        .where((MovimientoInventario m) => m.productoId == productoId)
        .toList(growable: false);
  }

  /// Registra un **ajuste manual** con **motivo** (RF-05, RN-05).
  ///
  /// [delta] es la variación con signo. No permite stock negativo salvo que el
  /// producto tenga `permiteStockNegativo` (RN-02).
  Future<void> ajuste({
    required String empresaId,
    required String productoId,
    required int delta,
    required String motivo,
    required String usuarioUid,
  }) async {
    if (motivo.trim().isEmpty) throw const MotivoRequeridoException();
    if (delta == 0) {
      throw ArgumentError('La cantidad del ajuste debe ser distinta de cero.');
    }

    final pRef = _productos.doc(productoId);
    await _db.runTransaction((Transaction tx) async {
      final snap = await tx.get(pRef);
      final data = snap.data();
      if (data == null) throw StateError('El producto no existe.');
      final stockAnterior = (data['stock'] as num?)?.toInt() ?? 0;
      final nuevo = stockAnterior + delta;
      final permiteNegativo = data['permiteStockNegativo'] == true;
      if (nuevo < 0 && !permiteNegativo) {
        throw StockNoPermitidoException((data['nombre'] as String?) ?? productoId);
      }

      tx.update(pRef, <String, dynamic>{
        'stock': nuevo,
        'fechaActualizacion': DateTime.now().toUtc().toIso8601String(),
      });
      escribirMovimiento(
        _db,
        tx,
        empresaId: empresaId,
        productoId: productoId,
        codigo: (data['codigo'] as String?) ?? '',
        nombre: (data['nombre'] as String?) ?? '',
        tipo: delta > 0 ? 'ajuste_positivo' : 'ajuste_negativo',
        delta: delta,
        stockAnterior: stockAnterior,
        referenciaTipo: 'ajuste',
        referenciaId: '-',
        usuarioUid: usuarioUid,
        motivo: motivo,
      );
    });

    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'movimientos_inventario',
      documentoId: productoId,
      datos: <String, dynamic>{
        'tipo': delta > 0 ? 'ajuste_positivo' : 'ajuste_negativo',
        'cantidad': delta.abs(),
        'motivo': motivo,
      },
    );
  }

  /// Registra un **conteo físico** y genera los **ajustes** por diferencia
  /// (RF-10, RN-08) en una transacción.
  Future<String> registrarConteo(
    ConteoInventario conteo, {
    required String usuarioUid,
  }) async {
    final conteoRef =
        conteo.id.isNotEmpty ? _conteos.doc(conteo.id) : _conteos.doc();

    await _db.runTransaction((Transaction tx) async {
      // LECTURAS (todas antes de escribir).
      final datos = <String, Map<String, dynamic>>{};
      for (final ItemConteo it in conteo.items) {
        if (it.diferencia == 0) continue;
        final snap = await tx.get(_productos.doc(it.productoId));
        final data = snap.data();
        if (data == null) continue;
        datos[it.productoId] = data;
      }

      // ESCRITURAS.
      for (final ItemConteo it in conteo.items) {
        if (it.diferencia == 0) continue;
        final data = datos[it.productoId];
        if (data == null) continue;
        final stockAnterior = (data['stock'] as num?)?.toInt() ?? 0;
        tx.update(_productos.doc(it.productoId), <String, dynamic>{
          'stock': it.stockFisico < 0 ? 0 : it.stockFisico,
          'fechaActualizacion': DateTime.now().toUtc().toIso8601String(),
        });
        escribirMovimiento(
          _db,
          tx,
          empresaId: conteo.empresaId,
          productoId: it.productoId,
          codigo: (data['codigo'] as String?) ?? '',
          nombre: it.nombre,
          tipo: it.diferencia > 0 ? 'ajuste_positivo' : 'ajuste_negativo',
          delta: it.diferencia,
          stockAnterior: stockAnterior,
          referenciaTipo: 'conteo',
          referenciaId: conteoRef.id,
          usuarioUid: usuarioUid,
          motivo: 'Conteo físico',
        );
      }

      tx.set(conteoRef, <String, dynamic>{
        ...conteo.toMap(),
        'id': conteoRef.id,
        'usuarioUid': usuarioUid,
        'estado': EstadoConteo.cerrado.id,
      });
    });

    await _auditoria.registrarEvento(
      empresaId: conteo.empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'conteos_inventario',
      documentoId: conteoRef.id,
      datos: <String, dynamic>{'items': conteo.itemsConDiferencia},
    );
    return conteoRef.id;
  }

  List<MovimientoInventario> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            MovimientoInventario.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((MovimientoInventario a, MovimientoInventario b) =>
        (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
    return lista;
  }
}
