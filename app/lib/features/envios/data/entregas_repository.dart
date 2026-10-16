import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../../ventas/domain/venta.dart';

/// Acceso a las **ventas pendientes de entrega** (spec 011, MVP
/// "Pendientes por entregar").
///
/// El estado de la entrega vive en la venta (`estadoEnvio`, `repartidorUid`,
/// `repartidorNombre`). Las lecturas filtran por `empresaId` y refinan en el
/// cliente.
class EntregasRepository {
  EntregasRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ventas =>
      _db.collection('ventas');

  /// Escucha las ventas que requieren entrega y aún no están entregadas,
  /// ordenadas de la más antigua a la más reciente (RF-01, RF-04).
  Stream<List<Venta>> escucharPorEntregar(String empresaId) {
    return _ventas
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) {
      final lista = snap.docs
          .map((DocumentSnapshot<Map<String, dynamic>> d) =>
              Venta.fromMap(d.id, d.data()!))
          .where((Venta v) => v.entregaPendiente)
          .toList();
      lista.sort((Venta a, Venta b) =>
          (a.fecha ?? DateTime(0)).compareTo(b.fecha ?? DateTime(0)));
      return lista;
    });
  }

  /// Cambia el estado de entrega de una venta (RF-04, RF-09).
  Future<void> marcarEstado(
    String ventaId,
    EstadoEnvio estado, {
    required String empresaId,
    String repartidorUid = '',
    String repartidorNombre = '',
  }) async {
    await _ventas.doc(ventaId).update(<String, dynamic>{
      'estadoEnvio': estado.id,
      if (repartidorUid.isNotEmpty) 'repartidorUid': repartidorUid,
      if (repartidorNombre.isNotEmpty) 'repartidorNombre': repartidorNombre,
    });
    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.update,
      tabla: 'ventas',
      documentoId: ventaId,
      datos: <String, dynamic>{
        'estadoEnvio': estado.id,
        'repartidorUid': repartidorUid,
      },
    );
  }
}
