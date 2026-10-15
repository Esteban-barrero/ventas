import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/plan.dart';

/// Acceso a la colección `planes` (spec 002, RF-11 / T003).
///
/// Si la colección está vacía (o no hay conexión), se usan los planes por
/// defecto definidos en [Plan.porDefecto] para no bloquear la interfaz.
class PlanesRepository {
  PlanesRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _planes =>
      _db.collection('planes');

  /// Lista los planes activos. Cae a los planes por defecto si algo falla.
  Future<List<Plan>> listar() async {
    try {
      final snap = await _planes.get();
      if (snap.docs.isEmpty) return Plan.porDefecto;

      final planes = snap.docs
          .map((DocumentSnapshot<Map<String, dynamic>> d) =>
              Plan.fromMap(<String, dynamic>{'id': d.id, ...d.data()!}))
          .toList(growable: false);

      planes.sort((Plan a, Plan b) => a.valor.compareTo(b.valor));
      return planes;
    } catch (_) {
      return Plan.porDefecto;
    }
  }

  /// Escribe los planes por defecto si la colección está vacía (T003).
  ///
  /// Devuelve cuántos planes se sembraron.
  Future<int> sembrarPorDefecto() async {
    final existentes = await _planes.limit(1).get();
    if (existentes.docs.isNotEmpty) return 0;

    final batch = _db.batch();
    for (final plan in Plan.porDefecto) {
      batch.set(_planes.doc(plan.id), plan.toMap());
    }
    await batch.commit();
    return Plan.porDefecto.length;
  }

  /// Devuelve un plan por su id.
  Future<Plan?> obtener(String planId) async {
    final porDefecto = Plan.porDefectoConId(planId);
    try {
      final doc = await _planes.doc(planId).get();
      if (!doc.exists || doc.data() == null) return porDefecto;
      return Plan.fromMap(<String, dynamic>{'id': doc.id, ...doc.data()!});
    } catch (_) {
      return porDefecto;
    }
  }
}
