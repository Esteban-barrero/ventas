/// Validación de correos electrónicos (convención del proyecto).
library;

/// `true` si [correo] tiene un formato de correo razonable (`algo@dominio.ext`).
///
/// Se usa en formularios y en el dominio en lugar de comprobar solo que el
/// texto contenga `@`. No es una validación RFC completa ni verifica que el
/// buzón exista. Un texto vacío devuelve `false`.
bool esCorreoValido(String correo) {
  final c = correo.trim();
  if (c.isEmpty) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(c);
}
