import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda datos de ingreso para prellenar el login (spec 001).
///
/// Solo se guarda el **correo** (nunca la contraseña). La sesión de Firebase
/// Authentication persiste por su cuenta.
class PreferenciasLogin {
  const PreferenciasLogin();

  static const String _claveCorreo = 'login.correo';
  static const String _claveRecordar = 'login.recordar';

  /// Correo guardado (o cadena vacía si no hay).
  Future<String> correoGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveCorreo) ?? '';
  }

  /// `true` si el usuario pidió recordar sus datos (por defecto sí).
  Future<bool> recordar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_claveRecordar) ?? true;
  }

  /// Guarda el correo si [recordar]; si no, lo borra.
  Future<void> guardar({required String correo, required bool recordar}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveRecordar, recordar);
    if (recordar && correo.trim().isNotEmpty) {
      await prefs.setString(_claveCorreo, correo.trim());
    } else {
      await prefs.remove(_claveCorreo);
    }
  }
}
