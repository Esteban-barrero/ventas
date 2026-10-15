import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';

/// Crea la cuenta de Firebase Auth de un usuario **desde el cliente**.
///
/// Se usa como respaldo de la Cloud Function `crearUsuario` (ADR-001) cuando
/// esta no está desplegada o no hay conexión. Igual que en la creación de
/// empresas, se usa una instancia **secundaria** de Firebase para no cerrar la
/// sesión del Administrador que está creando al usuario.
class CreadorUsuarioLocal {
  const CreadorUsuarioLocal();

  /// Crea la cuenta y devuelve su `uid`.
  ///
  /// La cuenta se crea con una contraseña temporal aleatoria y se envía un
  /// correo para restablecerla, de modo que el Administrador nunca conoce la
  /// contraseña definitiva.
  Future<String> crearCuenta({
    required String email,
    required String nombre,
  }) async {
    FirebaseApp? appSecundaria;
    try {
      appSecundaria = await Firebase.initializeApp(
        name: 'creador-usuario-${DateTime.now().microsecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final auth = FirebaseAuth.instanceFor(app: appSecundaria);
      final credencial = await auth.createUserWithEmailAndPassword(
        email: email,
        password: _passwordTemporal(),
      );

      final user = credencial.user;
      if (user == null) {
        throw StateError('No se pudo crear la cuenta del usuario.');
      }

      try {
        await user.updateDisplayName(nombre);
      } catch (_) {
        // El nombre visible es opcional.
      }

      try {
        await auth.sendPasswordResetEmail(email: email);
      } catch (_) {
        // Si falla el correo, el Administrador puede reenviarlo luego.
      }

      return user.uid;
    } finally {
      if (appSecundaria != null) {
        try {
          await appSecundaria.delete();
        } catch (_) {
          // La instancia secundaria se limpia en el siguiente arranque.
        }
      }
    }
  }

  static String _passwordTemporal() {
    const caracteres = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    return List<String>.generate(
      16,
      (_) => caracteres[random.nextInt(caracteres.length)],
    ).join();
  }
}
