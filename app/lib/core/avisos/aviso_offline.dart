import 'package:flutter/material.dart';

/// Aviso de que se esta mostrando informacion guardada (sin conexion).
///
/// Aparece cuando el perfil o la licencia se cargaron desde la copia local del
/// dispositivo (spec 001, T014). Es informativo, no un error.
class AvisoOffline extends StatelessWidget {
  const AvisoOffline({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(Icons.cloud_off_outlined, color: scheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Sin conexión',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Estás viendo la información guardada en este dispositivo. '
                    'Se actualizará cuando vuelvas a tener internet.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
