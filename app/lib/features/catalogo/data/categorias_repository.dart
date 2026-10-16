import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/categoria.dart';
import 'categorias_estandar.dart';

/// Acceso a la colección `categorias` (spec 003, RF-10). Multi-tenant.
class CategoriasRepository {
  CategoriasRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
  })  : _firestoreOverride = firestore,
        _auditoria = auditoria ?? AuditoriaRepository();

  final FirebaseFirestore? _firestoreOverride;
  final AuditoriaRepository _auditoria;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categorias =>
      _db.collection('categorias');

  /// Escucha, en tiempo real, las categorías de una empresa.
  Stream<List<Categoria>> escuchar(String empresaId) {
    return _categorias
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map(_aLista);
  }

  /// Lista las categorías de una empresa.
  Future<List<Categoria>> listar(
    String empresaId, {
    bool soloActivas = false,
  }) async {
    final snap =
        await _categorias.where('empresaId', isEqualTo: empresaId).get();
    final lista = _aLista(snap);
    return soloActivas
        ? lista.where((Categoria c) => c.activo).toList(growable: false)
        : lista;
  }

  /// Crea una categoría y la audita. Devuelve su id.
  Future<String> crear(Categoria categoria) async {
    if (categoria.nombre.trim().isEmpty) {
      throw ArgumentError('El nombre de la categoría es obligatorio.');
    }
    final ref = _categorias.doc();
    final datos = categoria.toMap()..['id'] = ref.id;
    await ref.set(datos);
    await _auditoria.registrarEvento(
      empresaId: categoria.empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'categorias',
      documentoId: ref.id,
      datos: datos,
    );
    return ref.id;
  }

  /// Actualiza una categoría y registra los cambios.
  Future<void> actualizar(Categoria categoria) async {
    final ref = _categorias.doc(categoria.id);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};
    final despues = categoria.toMap();
    final antesParcial = <String, dynamic>{
      for (final clave in despues.keys) clave: antes[clave],
    };
    await ref.set(despues, SetOptions(merge: true));
    await _auditoria.registrarCambios(
      empresaId: categoria.empresaId,
      tabla: 'categorias',
      documentoId: categoria.id,
      antes: antesParcial,
      despues: despues,
    );
  }

  /// Activa o desactiva una categoría (baja lógica).
  Future<void> activar(
    String categoriaId,
    bool activo, {
    String? empresaId,
  }) async {
    final ref = _categorias.doc(categoriaId);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};
    final empresa = empresaId ?? (antes['empresaId'] as String?) ?? '';
    final despues = <String, dynamic>{'activo': activo};
    await ref.update(despues);
    await _auditoria.registrarCambios(
      empresaId: empresa,
      tabla: 'categorias',
      documentoId: categoriaId,
      antes: <String, dynamic>{'activo': antes['activo']},
      despues: despues,
    );
  }

  /// Crea la lista **estándar** de categorías para una empresa si no tiene
  /// ninguna (spec 003). Devuelve cuántas creó (0 si ya había).
  ///
  /// Así el formulario de producto tiene opciones desde el inicio y cada empresa
  /// puede luego editarlas a su gusto.
  Future<int> sembrarEstandar(String empresaId) async {
    if (empresaId.isEmpty) return 0;
    final existentes = await listar(empresaId);
    if (existentes.isNotEmpty) return 0;

    var creadas = 0;
    for (final nombre in categoriasEstandar) {
      await crear(Categoria(id: '', empresaId: empresaId, nombre: nombre));
      creadas++;
    }
    return creadas;
  }

  List<Categoria> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            Categoria.fromMap(d.id, d.data()!))
        .toList();
    lista.sort((Categoria a, Categoria b) =>
        a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }
}
