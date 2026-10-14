import 'package:flutter/material.dart';

import '../data/auth_repository.dart';

/// Pantalla de inicio de sesion / registro (spec 001).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.repository});

  /// Permite inyectar un repositorio distinto en las pruebas.
  final AuthRepository? repository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthRepository _auth = widget.repository ?? AuthRepository();

  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _esRegistro = false;
  bool _cargando = false;
  bool _ocultaContrasena = true;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      if (_esRegistro) {
        await _auth.registrar(_correo.text, _contrasena.text);
      } else {
        await _auth.iniciarSesion(_correo.text, _contrasena.text);
      }
      // Al autenticarse, AuthGate cambia de pantalla automaticamente.
    } catch (e) {
      setState(() => _error = AuthRepository.mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarConGoogle() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await _auth.iniciarSesionConGoogle();
    } catch (e) {
      if (mounted) {
        setState(() => _error = AuthRepository.mensajeDeError(e));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperarContrasena() async {
    final enviado = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoRecuperar(
        correoInicial: _correo.text.trim(),
        enviar: _auth.enviarCorreoRecuperacion,
      ),
    );

    if (enviado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Te enviamos un correo para restablecer tu contraseña. '
            'Revisa tu bandeja (y la carpeta de spam).',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: scheme.primary,
                    child: Text(
                      'AV',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aplicativo de Ventas',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _esRegistro
                        ? 'Crear una cuenta'
                        : 'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Escribe tu correo';
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Correo no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contrasena,
                    obscureText: _ocultaContrasena,
                    autofillHints: const <String>[AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_ocultaContrasena
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _ocultaContrasena = !_ocultaContrasena),
                      ),
                    ),
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Escribe tu contraseña';
                      if (_esRegistro && (v ?? '').length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _enviar(),
                  ),
                  if (!_esRegistro)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _cargando ? null : _recuperarContrasena,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.error_outline, color: scheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: scheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _cargando ? null : _enviar,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_esRegistro ? 'Crear cuenta' : 'Iniciar sesión'),
                  ),
                  const SizedBox(height: 20),
                  const _Separador(),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _cargando ? null : _iniciarConGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const _IconoGoogle(),
                    label: const Text('Continuar con Google'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cargando
                        ? null
                        : () => setState(() {
                              _esRegistro = !_esRegistro;
                              _error = null;
                            }),
                    child: Text(
                      _esRegistro
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Regístrate',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linea divisoria con la palabra "o" en el centro.
class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('o', style: theme.textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// "G" de Google dibujada con texto (sin depender de assets/imágenes).
class _IconoGoogle extends StatelessWidget {
  const _IconoGoogle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1A73E8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          height: 1,
        ),
      ),
    );
  }
}

/// Dialogo para enviar el correo de recuperacion de contrasena (RF-02).
class _DialogoRecuperar extends StatefulWidget {
  const _DialogoRecuperar({required this.correoInicial, required this.enviar});

  final String correoInicial;
  final Future<void> Function(String correo) enviar;

  @override
  State<_DialogoRecuperar> createState() => _DialogoRecuperarState();
}

class _DialogoRecuperarState extends State<_DialogoRecuperar> {
  late final TextEditingController _correo =
      TextEditingController(text: widget.correoInicial);
  final _formKey = GlobalKey<FormState>();

  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await widget.enviar(_correo.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = AuthRepository.mensajeDeError(e));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: const Icon(Icons.lock_reset_outlined),
      title: const Text('Recuperar contraseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Escribe tu correo y te enviaremos un enlace para crear una '
              'contraseña nueva.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Escribe tu correo';
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Correo no válido';
                }
                return null;
              },
              onFieldSubmitted: (_) => _enviar(),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _cargando ? null : _enviar,
          child: _cargando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
