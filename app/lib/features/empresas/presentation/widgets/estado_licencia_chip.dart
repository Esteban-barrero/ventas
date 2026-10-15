import 'package:flutter/material.dart';

import '../../domain/licencia.dart';

/// Chip con el estado de la licencia de una empresa (tablero, spec 002).
class EstadoLicenciaChip extends StatelessWidget {
  const EstadoLicenciaChip({super.key, required this.estado, this.compacto = false});

  final EstadoLicenciaNegocio estado;

  /// Si es `true`, solo muestra el ícono y el texto en tamaño pequeño.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color color, IconData icono) = switch (estado) {
      EstadoLicenciaNegocio.activa =>
        (const Color(0xFF2E7D32), Icons.check_circle_outline),
      EstadoLicenciaNegocio.porVencer =>
        (const Color(0xFFE65100), Icons.schedule),
      EstadoLicenciaNegocio.vencida =>
        (scheme.error, Icons.error_outline),
      EstadoLicenciaNegocio.suspendida =>
        (const Color(0xFF455A64), Icons.pause_circle_outline),
      EstadoLicenciaNegocio.prueba =>
        (const Color(0xFF6A1B9A), Icons.science_outlined),
    };

    return Chip(
      visualDensity: compacto ? VisualDensity.compact : null,
      avatar: Icon(icono, size: 18, color: color),
      label: Text(estado.nombre, style: TextStyle(color: color)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}
