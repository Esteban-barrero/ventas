import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../home/home_page.dart';
import '../data/auth_repository.dart';
import '../data/usuarios_repository.dart';
import '../domain/usuario.dart';
import 'login_screen.dart';

/// Decide qué mostrar según el estado de sesión (spec 001).
///
/// - Sin usuario -> [LoginScreen]
/// - Con usuario -> carga el perfil (`usuarios/{uid}`) y muestra [HomePage]
///
/// Si el perfil no existe todavía, se crea automáticamente (bootstrap).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authRepository, this.usuariosRepository});

  /// Permiten inyectar repositorios distintos en las pruebas.
  final AuthRepository? authRepository;
  final UsuariosRepository? usuariosRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthRepository _auth =
      widget.authRepository ?? AuthRepository();
  late final UsuariosRepository _usuarios =
      widget.usuariosRepository ?? UsuariosRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.cambiosDeSesion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Cargando();
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(repository: _auth);
        }

        return _PerfilLoader(
          key: ValueKey<String>(user.uid),
          user: user,
          usuarios: _usuarios,
          onCerrarSesion: _auth.cerrarSesion,
        );
      },
    );
  }
}

class _PerfilLoader extends StatefulWidget {
  const _PerfilLoader({
    super.key,
    required this.user,
    required this.usuarios,
    required this.onCerrarSesion,
  });

  final User user;
  final UsuariosRepository usuarios;
  final Future<void> Function() onCerrarSesion;

  @override
  State<_PerfilLoader> createState() => _PerfilLoaderState();
}

class _PerfilLoaderState extends State<_PerfilLoader> {
  late Future<Usuario> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.usuarios.obtenerOCrear(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Usuario>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Cargando();
        }
        if (snapshot.hasError) {
          return _ErrorPerfil(
            error: snapshot.error!,
            onCerrarSesion: widget.onCerrarSesion,
          );
        }
        return HomePage(
          usuario: snapshot.data!,
          onCerrarSesion: widget.onCerrarSesion,
        );
      },
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorPerfil extends StatelessWidget {
  const _ErrorPerfil({required this.error, required this.onCerrarSesion});

  final Object error;
  final Future<void> Function() onCerrarSesion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.error_outline, size: 48, color: scheme.error),
              const SizedBox(height: 16),
              const Text(
                'No se pudo cargar tu perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async => onCerrarSesion(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
