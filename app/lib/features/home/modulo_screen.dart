import 'package:flutter/material.dart';

import '../auth/domain/permisos.dart';

/// Pantalla provisional de un módulo todavía no implementado.
///
/// Sirve para comprobar que las guardas de navegación funcionan: solo se llega
/// aquí cuando el usuario tiene el permiso requerido (spec 001, T023).
class ModuloScreen extends StatelessWidget {
  const ModuloScreen({
    super.key,
    required this.nombre,
    required this.icono,
    required this.permiso,
  });

  final String nombre;
  final IconData icono;
  final Permiso permiso;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(nombre)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icono, size: 64, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                nombre,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Módulo en construcción.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Chip(
                avatar: const Icon(Icons.key_outlined, size: 18),
                label: Text('Requiere: ${permiso.etiqueta}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
