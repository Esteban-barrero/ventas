import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/errores.dart';
import '../../auditoria/data/auditoria_repository.dart';
import '../domain/perfil_cargado.dart';
import '../domain/usuario.dart';
import 'cache_sesion.dart';

/// Acceso a la coleccion `usuarios` en Firestore. Ver spec 001.
class UsuariosRepository {
  UsuariosRepository({
    FirebaseFirestore? firestore,
    AuditoriaRepository? auditoria,
    CacheSesion? cache,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auditoria = auditoria ?? AuditoriaRepository(),
        _cache = cache ?? CacheSesion();

  final FirebaseFirestore _db;
  final AuditoriaRepository _auditoria;
  final CacheSesion _cache;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _db.collection('usuarios');

  /// Obtiene el perfil del usuario autenticado.
  ///
  /// Si aun no existe (por ejemplo, cuentas creadas antes de tener perfiles),
  /// lo crea con un rol inicial. Este es un arranque temporal hasta que exista
  /// el flujo de creacion de empresas y usuarios (spec 002).
  ///
  /// Si no hay conexion, devuelve el perfil guardado en el dispositivo
  /// (spec 001, T014).
  Future<PerfilCargado> obtenerOCrear(User user) async {
    final ref = _usuarios.doc(user.uid);

    try {
      final snap = await ref.get();

      if (snap.exists && snap.data() != null) {
        final usuario = Usuario.fromMap(user.uid, snap.data()!);
        await _cache.guardarPerfil(usuario);
        return PerfilCargado(usuario: usuario);
      }

      final nombre = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!
          : (user.email?.split('@').first ?? 'Usuario');

      final nuevo = Usuario(
        uid: user.uid,
        nombre: nombre,
        email: user.email ?? '',
        // TODO(spec-002): al crear empresas, el rol dependera de quien crea la
        // cuenta. Por ahora el primer usuario queda como Administrador.
        roles: const <String>['administrador'],
        activo: true,
        fechaCreacion: DateTime.now(),
      );

      await ref.set(nuevo.toMap());
      await _cache.guardarPerfil(nuevo);
      return PerfilCargado(usuario: nuevo);
    } on FirebaseException catch (e) {
      if (esErrorDeRed(e)) {
        final guardado = await _cache.leerPerfil(user.uid);
        if (guardado != null) {
          return PerfilCargado(usuario: guardado, desdeCache: true);
        }
      }
      rethrow;
    }
  }

  /// Escucha los cambios del perfil en tiempo real.
  Stream<Usuario?> escuchar(String uid) {
    return _usuarios.doc(uid).snapshots().asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) return null;
      final usuario = Usuario.fromMap(uid, doc.data()!);
      await _cache.guardarPerfil(usuario);
      return usuario;
    });
  }

  /// Guarda (crea o reemplaza) el perfil.
  Future<void> guardar(Usuario usuario) async {
    await _usuarios.doc(usuario.uid).set(usuario.toMap());
    await _cache.guardarPerfil(usuario);
  }

  /// Cambia los roles de un usuario y deja constancia en la auditoria.
  ///
  /// [autor] es el UID de quien hace el cambio (por defecto, el usuario
  /// autenticado). Ver spec 001, RF-11 / CA-07.
  Future<void> actualizarRoles(
    String uid,
    List<String> roles, {
    String? autor,
  }) async {
    final ref = _usuarios.doc(uid);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};

    final despues = <String, dynamic>{'roles': roles};

    // Solo se auditan los campos que se estan modificando.
    final antesParcial = <String, dynamic>{
      for (final clave in despues.keys) clave: antes[clave],
    };

    await ref.update(despues);

    await _auditoria.registrarCambios(
      empresaId: (antes['empresaId'] as String?) ?? '',
      tabla: 'usuarios',
      documentoId: uid,
      antes: antesParcial,
      despues: despues,
      autor: autor,
    );
  }
}
