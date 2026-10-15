import 'package:flutter/material.dart';

import '../domain/licencia.dart';

/// Aviso de vencimiento proximo de la licencia (spec 001, RN-06).
///
/// Se muestra en el inicio cuando faltan `diasAvisoVencimiento` dias o menos
/// (por defecto 5).
class AvisoLicencia extends StatelessWidget {
  const AvisoLicencia({super.key, required this.estado});

  final EstadoLicencia estado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dias = estado.diasRestantes;

    final String mensaje;
    if (dias == null) {
      mensaje = 'Tu licencia está por vencer.';
    } else if (dias <= 0) {
      mensaje = 'Tu licencia vence hoy.';
    } else if (dias == 1) {
      mensaje = 'Tu licencia vence mañana.';
    } else {
      mensaje = 'Tu licencia vence en $dias días.';
    }

    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.warning_amber_rounded,
                color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    mensaje,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Renueva para no perder el acceso. '
                    'Contacta al proveedor para más información.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
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
