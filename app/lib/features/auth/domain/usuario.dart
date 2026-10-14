import 'permisos.dart';
import 'roles.dart';

/// Perfil de usuario del aplicativo (coleccion `usuarios/{uid}`). Ver spec 001.
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    this.telefono = '',
    this.empresaId,
    this.roles = const <String>[],
    this.activo = true,
    this.fechaCreacion,
  });

  /// UID de Firebase Auth.
  final String uid;
  final String nombre;
  final String email;
  final String telefono;

  /// Empresa a la que pertenece (`null` para Super Admin).
  final String? empresaId;

  /// Ids de los roles asignados (ej: `['administrador', 'developer']`).
  final List<String> roles;

  final bool activo;
  final DateTime? fechaCreacion;

  /// Roles validos (ignora ids desconocidos).
  List<Rol> get rolesTipados =>
      roles.map(Rol.desdeId).whereType<Rol>().toList(growable: false);

  /// Permisos efectivos (union de los roles).
  Set<Permiso> get permisos => permisosDeRoles(rolesTipados);

  /// Indica si el usuario tiene un permiso.
  bool puede(Permiso permiso) => permisos.contains(permiso);

  Map<String, dynamic> toMap() => <String, dynamic>{
        'uid': uid,
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'empresaId': empresaId,
        'roles': roles,
        'activo': activo,
        'fechaCreacion':
            (fechaCreacion ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory Usuario.fromMap(String uid, Map<String, dynamic> data) {
    return Usuario(
      uid: uid,
      nombre: (data['nombre'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      telefono: (data['telefono'] as String?) ?? '',
      empresaId: data['empresaId'] as String?,
      roles: (data['roles'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
      activo: (data['activo'] as bool?) ?? true,
      fechaCreacion: _aFecha(data['fechaCreacion']),
    );
  }

  Usuario copyWith({
    String? nombre,
    String? telefono,
    String? empresaId,
    List<String>? roles,
    bool? activo,
  }) {
    return Usuario(
      uid: uid,
      nombre: nombre ?? this.nombre,
      email: email,
      telefono: telefono ?? this.telefono,
      empresaId: empresaId ?? this.empresaId,
      roles: roles ?? this.roles,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion,
    );
  }

  static DateTime? _aFecha(dynamic valor) {
    if (valor == null) return null;
    if (valor is DateTime) return valor;
    if (valor is String) return DateTime.tryParse(valor);
    try {
      final dynamic fecha = (valor as dynamic).toDate();
      if (fecha is DateTime) return fecha;
    } catch (_) {
      // Tipo desconocido; se ignora.
    }
    return null;
  }
}
