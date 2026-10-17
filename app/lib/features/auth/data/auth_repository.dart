import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Acceso a Firebase Authentication (spec 001).
///
/// Envuelve [FirebaseAuth] para no acoplar la interfaz directamente al SDK.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _authOverride = auth;

  final FirebaseAuth? _authOverride;

  /// Se resuelve de forma perezosa para poder construir el repositorio en
  /// pruebas (o en widgets) sin inicializar Firebase.
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

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

  /// Inicia una sesión **anónima** (modo invitado de la tienda, spec 010).
  Future<UserCredential> iniciarSesionAnonima() =>
      _auth.signInAnonymously();

  /// Inicia sesion con Google (RF-01).
  ///
  /// En web abre una ventana emergente; en Android/iOS usa el flujo nativo.
  Future<UserCredential> iniciarSesionConGoogle() {
    final provider = GoogleAuthProvider()
      ..setCustomParameters(<String, String>{'prompt': 'select_account'});
    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }
    return _auth.signInWithProvider(provider);
  }

  /// Envia un correo para restablecer la contrasena (RF-02).
  Future<void> enviarCorreoRecuperacion(String correo) {
    return _auth.sendPasswordResetEmail(email: correo.trim());
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
        case 'missing-email':
          return 'Escribe tu correo para continuar.';
        case 'operation-not-allowed':
          return 'El método de acceso no está habilitado.';
        case 'network-request-failed':
          return 'Sin conexión. Revisa tu internet.';
        case 'too-many-requests':
          return 'Demasiados intentos. Espera un momento.';
        // Google Sign-In
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Cancelaste el inicio de sesión con Google.';
        case 'popup-blocked':
          return 'El navegador bloqueó la ventana emergente. '
              'Permite las ventanas emergentes e inténtalo de nuevo.';
        case 'account-exists-with-different-credential':
        case 'credential-already-in-use':
          return 'Ese correo ya está registrado con otro método de acceso. '
              'Inicia sesión con correo y contraseña.';
        case 'unauthorized-domain':
          return 'Este dominio no está autorizado para iniciar sesión con '
              'Google.';
        default:
          return 'Ocurrió un error: ${error.message ?? error.code}';
      }
    }
    return 'Ocurrió un error inesperado.';
  }
}
