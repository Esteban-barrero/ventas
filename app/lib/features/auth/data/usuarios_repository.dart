import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/errores.dart';
import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../domain/datos_usuario.dart';
import '../domain/perfil_cargado.dart';
import '../domain/usuario.dart';
import 'cache_sesion.dart';
import 'crear_usuario_local.dart';

/// Resultado de crear un usuario (spec 001, CA-06).
class ResultadoCrearUsuario {
  const ResultadoCrearUsuario({
    required this.uid,
    this.enlaceActivacion,
    this.desdeRespaldo = false,
  });

  final String uid;

  /// Enlace para que el usuario defina su contraseña (si se pudo generar).
  final String? enlaceActivacion;

  /// `true` si la cuenta se creó con el respaldo local (la Cloud Function
  /// `crearUsuario` no estaba disponible).
  final bool desdeRespaldo;
}

/// Acceso a la coleccion `usuarios` en Firestore. Ver spec 001.
class UsuariosRepository {
  UsuariosRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    AuditoriaRepository? auditoria,
    CacheSesion? cache,
    CreadorUsuarioLocal? creadorLocal,
  })  : _firestoreOverride = firestore,
        _functionsOverride = functions,
        _auditoria = auditoria ?? AuditoriaRepository(),
        _cache = cache ?? CacheSesion(),
        _creadorLocal = creadorLocal ?? const CreadorUsuarioLocal();

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseFunctions? _functionsOverride;
  final AuditoriaRepository _auditoria;
  final CacheSesion _cache;
  final CreadorUsuarioLocal _creadorLocal;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

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

  /// Obtiene el perfil de un usuario por su UID (una sola lectura).
  ///
  /// Se usa, por ejemplo, para mostrar el nombre y el correo del Administrador
  /// de una empresa en la pantalla de detalle (spec 002). Devuelve `null` si el
  /// usuario no existe.
  Future<Usuario?> obtener(String uid) async {
    final snap = await _usuarios.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return Usuario.fromMap(uid, snap.data()!);
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

  /// Escucha, en tiempo real, los usuarios de una empresa (spec 001, CA-06).
  ///
  /// El Administrador solo puede leer los de su propia empresa (reglas de
  /// Firestore).
  Stream<List<Usuario>> escucharDeEmpresa(String empresaId) {
    return _usuarios
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map(_aLista);
  }

  /// Escucha **todos** los usuarios (solo Super Admin, lo permiten las reglas).
  Stream<List<Usuario>> escucharTodos() => _usuarios.snapshots().map(_aLista);

  List<Usuario> _aLista(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs
        .map((doc) => Usuario.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    final ordenada = lista.toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return ordenada;
  }

  /// Crea un usuario llamando a la Cloud Function `crearUsuario`.
  ///
  /// Si la función no está desplegada o no hay conexión, usa el respaldo local
  /// ([CreadorUsuarioLocal]) + escritura directa del perfil (ADR-001/ADR-005).
  ///
  /// [empresaId] solo es necesario cuando quien crea es el Super Admin (no
  /// tiene empresa propia).
  Future<ResultadoCrearUsuario> crear(
    DatosNuevoUsuario datos, {
    bool requiereEmpresa = false,
  }) async {
    final error = datos.validar(requiereEmpresa: requiereEmpresa);
    if (error != null) {
      throw ArgumentError(error);
    }

    try {
      final callable = _functions.httpsCallable('crearUsuario');
      final respuesta = await callable.call(datos.toMap());
      final mapa = Map<String, dynamic>.from(respuesta.data as Map);
      return ResultadoCrearUsuario(
        uid: (mapa['uid'] as String?) ?? '',
        enlaceActivacion: mapa['enlaceActivacion'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      // Los errores "de negocio" de la función se muestran tal cual; el resto
      // (función no desplegada, sin conexión) cae al respaldo local.
      if (_esErrorDeNegocio(e.code)) rethrow;
    }

    return _crearLocal(datos);
  }

  Future<ResultadoCrearUsuario> _crearLocal(DatosNuevoUsuario datos) async {
    final empresaId = datos.empresaId;
    if (empresaId == null || empresaId.isEmpty) {
      throw StateError('El respaldo local necesita una empresa.');
    }

    final uid = await _creadorLocal.crearCuenta(
      email: datos.email.trim().toLowerCase(),
      nombre: datos.nombre.trim(),
    );

    final usuario = Usuario(
      uid: uid,
      nombre: datos.nombre.trim(),
      email: datos.email.trim().toLowerCase(),
      telefono: datos.telefono.trim(),
      empresaId: empresaId,
      roles: datos.roles,
      activo: datos.activo,
      fechaCreacion: DateTime.now(),
    );

    await _usuarios.doc(uid).set(usuario.toMap());
    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'usuarios',
      documentoId: uid,
      datos: usuario.toMap(),
    );

    return ResultadoCrearUsuario(uid: uid, desdeRespaldo: true);
  }

  /// Activa o desactiva un usuario, dejando constancia en la auditoría.
  ///
  /// Si se desactiva, el trigger `onUsuarioEscrito` revoca sus tokens.
  Future<void> actualizarActivo(
    String uid,
    bool activo, {
    String? autor,
  }) {
    return _actualizarCampos(uid, <String, dynamic>{'activo': activo}, autor: autor);
  }

  /// Actualiza el nombre, el teléfono y/o la foto de un usuario, con auditoría.
  Future<void> actualizarDatos(
    String uid, {
    String? nombre,
    String? telefono,
    String? foto,
    String? autor,
  }) {
    final cambios = <String, dynamic>{
      if (nombre != null) 'nombre': nombre.trim(),
      if (telefono != null) 'telefono': telefono.trim(),
      if (foto != null) 'foto': foto.trim(),
    };
    if (cambios.isEmpty) return Future<void>.value();
    return _actualizarCampos(uid, cambios, autor: autor);
  }

  /// Genera un **enlace de restablecimiento de contraseña** para un usuario
  /// (spec 001).
  ///
  /// Intenta la Cloud Function `generarEnlaceActivacion` (Admin SDK), que
  /// devuelve el enlace para copiarlo (sirve aunque el correo no exista). Si no
  /// está desplegada, envía el correo de restablecimiento y devuelve `null`.
  Future<String?> restablecerContrasena({
    required String email,
    String uid = '',
  }) async {
    try {
      final callable = _functions.httpsCallable('generarEnlaceActivacion');
      final respuesta = await callable.call(<String, dynamic>{
        'email': email,
        'uid': uid,
      });
      final mapa = Map<String, dynamic>.from(respuesta.data as Map);
      final enlace = mapa['enlaceActivacion'] as String?;
      if (enlace != null && enlace.isNotEmpty) return enlace;
    } catch (_) {
      // Función no desplegada u otro fallo: se usa el correo de restablecimiento.
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    return null;
  }

  Future<void> _actualizarCampos(
    String uid,
    Map<String, dynamic> cambios, {
    String? autor,
  }) async {
    final ref = _usuarios.doc(uid);
    final snap = await ref.get();
    final antes = snap.data() ?? const <String, dynamic>{};

    // Solo se auditan los campos que se están modificando.
    final antesParcial = <String, dynamic>{
      for (final clave in cambios.keys) clave: antes[clave],
    };

    await ref.update(cambios);

    await _auditoria.registrarCambios(
      empresaId: (antes['empresaId'] as String?) ?? '',
      tabla: 'usuarios',
      documentoId: uid,
      antes: antesParcial,
      despues: cambios,
      autor: autor,
    );
  }

  /// Errores de la función que NO deben caer al respaldo local.
  static bool _esErrorDeNegocio(String codigo) {
    return const <String>{
      'permission-denied',
      'unauthenticated',
      'invalid-argument',
      'already-exists',
      'failed-precondition',
    }.contains(codigo);
  }
}
