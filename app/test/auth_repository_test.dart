import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository.mensajeDeError', () {
    test('credenciales invalidas', () {
      expect(
        AuthRepository.mensajeDeError(
          FirebaseAuthException(code: 'invalid-credential'),
        ),
        'Correo o contraseña incorrectos.',
      );
    });

    test('correo ya registrado', () {
      expect(
        AuthRepository.mensajeDeError(
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        'Ese correo ya está registrado.',
      );
    });

    test('contrasena debil', () {
      expect(
        AuthRepository.mensajeDeError(
          FirebaseAuthException(code: 'weak-password'),
        ),
        'La contraseña debe tener al menos 6 caracteres.',
      );
    });

    test('cancelar la ventana de Google', () {
      expect(
        AuthRepository.mensajeDeError(
          FirebaseAuthException(code: 'popup-closed-by-user'),
        ),
        'Cancelaste el inicio de sesión con Google.',
      );
    });

    test('Google no habilitado', () {
      expect(
        AuthRepository.mensajeDeError(
          FirebaseAuthException(code: 'operation-not-allowed'),
        ),
        'El método de acceso no está habilitado.',
      );
    });

    test('error inesperado', () {
      expect(
        AuthRepository.mensajeDeError(Exception('boom')),
        'Ocurrió un error inesperado.',
      );
    });
  });
}
