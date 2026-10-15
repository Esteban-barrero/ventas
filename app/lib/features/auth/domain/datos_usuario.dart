/// Datos para crear un usuario desde la gestión de usuarios (spec 001, CA-06).
///
/// No incluye el `uid`: lo asigna Firebase Authentication al crear la cuenta.
class DatosNuevoUsuario {
  const DatosNuevoUsuario({
    required this.nombre,
    required this.email,
    this.telefono = '',
    this.roles = const <String>[],
    this.activo = true,
    this.empresaId,
  });

  final String nombre;
  final String email;
  final String telefono;

  /// Ids de los roles a asignar (ver [Rol]).
  final List<String> roles;

  final bool activo;

  /// Empresa destino. Solo la usa el Super Admin (que no tiene empresa propia);
  /// el Administrador crea siempre dentro de la suya.
  final String? empresaId;

  /// Devuelve el primer problema de validación, o `null` si todo está bien.
  String? validar({bool requiereEmpresa = false}) {
    if (nombre.trim().isEmpty) return 'El nombre es obligatorio.';
    if (email.trim().isEmpty) return 'El correo es obligatorio.';
    if (!_correoValido(email.trim())) return 'El correo no es válido.';
    if (roles.isEmpty) return 'Asigna al menos un rol.';
    if (requiereEmpresa && (empresaId == null || empresaId!.isEmpty)) {
      return 'Selecciona la empresa.';
    }
    return null;
  }

  /// Mapa listo para la Cloud Function `crearUsuario`.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'nombre': nombre.trim(),
        'email': email.trim().toLowerCase(),
        'telefono': telefono.trim(),
        'roles': roles,
        'activo': activo,
        if (empresaId != null && empresaId!.isNotEmpty) 'empresaId': empresaId,
      };

  /// Validación sencilla: texto@texto.dominio.
  static bool _correoValido(String correo) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo);
  }
}
