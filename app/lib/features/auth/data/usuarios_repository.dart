import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/usuario.dart';

/// Acceso a la coleccion `usuarios` en Firestore. Ver spec 001.
class UsuariosRepository {
  UsuariosRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _db.collection('usuarios');

  /// Obtiene el perfil del usuario autenticado.
  ///
  /// Si aun no existe (por ejemplo, cuentas creadas antes de tener perfiles),
  /// lo crea con un rol inicial. Este es un arranque temporal hasta que exista
  /// el flujo de creacion de empresas y usuarios (spec 002).
  Future<Usuario> obtenerOCrear(User user) async {
    final ref = _usuarios.doc(user.uid);
    final snap = await ref.get();

    if (snap.exists && snap.data() != null) {
      return Usuario.fromMap(user.uid, snap.data()!);
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
    return nuevo;
  }

  /// Escucha los cambios del perfil en tiempo real.
  Stream<Usuario?> escuchar(String uid) {
    return _usuarios.doc(uid).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? Usuario.fromMap(uid, doc.data()!)
              : null,
        );
  }

  /// Guarda (crea o reemplaza) el perfil.
  Future<void> guardar(Usuario usuario) =>
      _usuarios.doc(usuario.uid).set(usuario.toMap());

  /// Cambia los roles de un usuario.
  Future<void> actualizarRoles(String uid, List<String> roles) =>
      _usuarios.doc(uid).update(<String, dynamic>{'roles': roles});
}
