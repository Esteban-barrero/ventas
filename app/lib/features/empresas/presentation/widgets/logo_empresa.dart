import 'package:flutter/material.dart';

import '../../domain/empresa.dart';

/// Logo de una empresa: muestra la imagen de Storage o, si no hay, las
/// iniciales del nombre en un círculo con el color primario.
class LogoEmpresa extends StatelessWidget {
  const LogoEmpresa({super.key, required this.empresa, this.radio = 22});

  final Empresa empresa;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (empresa.tieneLogo) {
      return CircleAvatar(
        radius: radio,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(empresa.logo),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: radio,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        _iniciales(empresa.nombre),
        style: theme.textTheme.titleMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static String _iniciales(String texto) {
    final partes =
        texto.trim().split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
