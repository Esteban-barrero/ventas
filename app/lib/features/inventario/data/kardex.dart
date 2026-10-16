import 'package:cloud_firestore/cloud_firestore.dart';

/// Escribe un **movimiento de inventario** (kardex) dentro de una transacción.
///
/// El kardex es **inmutable** (RN-06): solo se insertan movimientos. [delta] es
/// la variación **con signo** del stock (positiva suma, negativa resta).
///
/// Lo usan ventas y compras (confirmar y anular) y el propio inventario
/// (ajustes y conteos), para dejar el kardex y el stock siempre coherentes.
void escribirMovimiento(
  FirebaseFirestore db,
  Transaction tx, {
  required String empresaId,
  required String productoId,
  required String codigo,
  required String nombre,
  required String tipo,
  required int delta,
  required int stockAnterior,
  required String referenciaTipo,
  required String referenciaId,
  required String usuarioUid,
  String motivo = '',
  String bodegaId = 'principal',
}) {
  final ref = db.collection('movimientos_inventario').doc();
  tx.set(ref, <String, dynamic>{
    'id': ref.id,
    'empresaId': empresaId,
    'productoId': productoId,
    'codigo': codigo,
    'nombre': nombre,
    'tipo': tipo,
    'cantidad': delta.abs(),
    'stockAnterior': stockAnterior,
    'stockResultante': stockAnterior + delta,
    'motivo': motivo,
    'referenciaTipo': referenciaTipo,
    'referenciaId': referenciaId,
    'bodegaId': bodegaId,
    'usuarioUid': usuarioUid,
    'fecha': FieldValue.serverTimestamp(),
  });
}
