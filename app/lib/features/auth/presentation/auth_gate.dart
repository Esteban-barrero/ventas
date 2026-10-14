import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../home/home_page.dart';
import '../data/auth_repository.dart';
import 'login_screen.dart';

/// Decide qué mostrar según el estado de sesión (spec 001).
///
/// - Sin usuario -> [LoginScreen]
/// - Con usuario -> [HomePage]
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.repository});

  /// Permite inyectar un repositorio distinto en las pruebas.
  final AuthRepository? repository;

  @override
  Widget build(BuildContext context) {
    final auth = repository ?? AuthRepository();

    return StreamBuilder<User?>(
      stream: auth.cambiosDeSesion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final usuario = snapshot.data;
        if (usuario == null) {
          return LoginScreen(repository: auth);
        }

        return HomePage(
          email: usuario.email ?? '',
          onCerrarSesion: auth.cerrarSesion,
        );
      },
    );
  }
}
