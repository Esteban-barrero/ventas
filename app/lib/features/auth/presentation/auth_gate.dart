import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../home/home_page.dart';
import '../../licencia/data/licencias_repository.dart';
import '../../licencia/domain/licencia.dart';
import '../../licencia/presentation/licencia_bloqueada_screen.dart';
import '../data/auth_repository.dart';
import '../data/usuarios_repository.dart';
import '../domain/usuario.dart';
import 'login_screen.dart';

/// Decide qué mostrar según el estado de sesión (spec 001).
///
/// - Sin usuario -> [LoginScreen]
/// - Con usuario -> carga el perfil (`usuarios/{uid}`) y valida la licencia de
///   su empresa. Si la licencia está vencida o la empresa suspendida, bloquea
///   el ingreso ([LicenciaBloqueadaScreen]).
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.authRepository,
    this.usuariosRepository,
    this.licenciasRepository,
  });

  /// Permiten inyectar repositorios distintos en las pruebas.
  final AuthRepository? authRepository;
  final UsuariosRepository? usuariosRepository;
  final LicenciasRepository? licenciasRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthRepository _auth =
      widget.authRepository ?? AuthRepository();
  late final UsuariosRepository _usuarios =
      widget.usuariosRepository ?? UsuariosRepository();
  late final LicenciasRepository _licencias =
      widget.licenciasRepository ?? LicenciasRepository();

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

        return _SesionLoader(
          key: ValueKey<String>(user.uid),
          user: user,
          usuarios: _usuarios,
          licencias: _licencias,
          onCerrarSesion: _auth.cerrarSesion,
        );
      },
    );
  }
}

/// Carga el perfil y la licencia antes de mostrar el inicio.
class _SesionLoader extends StatefulWidget {
  const _SesionLoader({
    super.key,
    required this.user,
    required this.usuarios,
    required this.licencias,
    required this.onCerrarSesion,
  });

  final User user;
  final UsuariosRepository usuarios;
  final LicenciasRepository licencias;
  final Future<void> Function() onCerrarSesion;

  @override
  State<_SesionLoader> createState() => _SesionLoaderState();
}

class _SesionLoaderState extends State<_SesionLoader> {
  Usuario? _usuario;
  ResultadoLicencia? _licencia;
  Object? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final usuario = await widget.usuarios.obtenerOCrear(widget.user);

      // El Super Admin no pertenece a ninguna empresa (RN-04): sin licencia.
      ResultadoLicencia? licencia;
      final empresaId = usuario.empresaId;
      if (empresaId != null &&
          empresaId.isNotEmpty &&
          !usuario.esSuperAdmin) {
        licencia = await widget.licencias.validar(empresaId);
      }

      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _licencia = licencia;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const _Cargando();

    if (_error != null) {
      return _ErrorPerfil(
        error: _error!,
        onCerrarSesion: widget.onCerrarSesion,
        onReintentar: _cargar,
      );
    }

    final usuario = _usuario!;

    switch (_licencia) {
      case LicenciaBloqueada(:final estado):
        return LicenciaBloqueadaScreen(
          estado: estado,
          onCerrarSesion: widget.onCerrarSesion,
          onReintentar: _cargar,
        );
      case LicenciaNoDisponible(:final detalle):
        return LicenciaNoDisponibleScreen(
          detalle: detalle,
          onCerrarSesion: widget.onCerrarSesion,
          onReintentar: _cargar,
        );
      case LicenciaVigente(:final estado):
        return HomePage(
          usuario: usuario,
          onCerrarSesion: widget.onCerrarSesion,
          avisoLicencia: estado.debeAvisar ? estado : null,
        );
      case null:
        return HomePage(
          usuario: usuario,
          onCerrarSesion: widget.onCerrarSesion,
        );
    }
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
  const _ErrorPerfil({
    required this.error,
    required this.onCerrarSesion,
    this.onReintentar,
  });

  final Object error;
  final Future<void> Function() onCerrarSesion;
  final Future<void> Function()? onReintentar;

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (onReintentar != null)
                    OutlinedButton.icon(
                      onPressed: () async => onReintentar!(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  if (onReintentar != null) const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async => onCerrarSesion(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
