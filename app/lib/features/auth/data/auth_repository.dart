import 'package:firebase_auth/firebase_auth.dart';

/// Acceso a Firebase Authentication (spec 001).
///
/// Envuelve [FirebaseAuth] para no acoplar la interfaz directamente al SDK.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Usuario actualmente autenticado (o null).
  User? get usuarioActual => _auth.currentUser;

  /// Emite cambios de sesion (login/logout).
  Stream<User?> cambiosDeSesion() => _auth.authStateChanges();

  /// Inicia sesion con correo y contrasena.
  Future<UserCredential> iniciarSesion(String correo, String contrasena) {
    return _auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    );
  }

  /// Registra un usuario nuevo con correo y contrasena.
  Future<UserCredential> registrar(String correo, String contrasena) {
    return _auth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    );
  }

  /// Cierra la sesion actual.
  Future<void> cerrarSesion() => _auth.signOut();

  /// Traduce los codigos de error de Firebase a mensajes en espanol.
  static String mensajeDeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo no es válido.';
        case 'user-disabled':
          return 'Esta cuenta está deshabilitada.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Correo o contraseña incorrectos.';
        case 'email-already-in-use':
          return 'Ese correo ya está registrado.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        case 'operation-not-allowed':
          return 'El método de acceso no está habilitado.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu internet.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera un momento.';
        default:
          return 'Ocurrió un error: ${error.message ?? error.code}';
      }
    }
    return 'Ocurrió un error inesperado.';
  }
}
