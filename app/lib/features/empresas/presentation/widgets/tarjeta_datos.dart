import 'package:flutter/material.dart';

/// Una fila etiqueta/valor dentro de [TarjetaDatos].
class FilaDato {
  const FilaDato(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;
}

/// Tarjeta con un título, un ícono y una lista de filas etiqueta/valor.
///
/// Se usa en el detalle de empresa (Super Admin) y en la vista de la propia
/// empresa (Administrador).
class TarjetaDatos extends StatelessWidget {
  const TarjetaDatos({
    super.key,
    required this.titulo,
    required this.icono,
    required this.filas,
    this.acciones = const <Widget>[],
  });

  final String titulo;
  final IconData icono;
  final List<FilaDato> filas;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icono, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final fila in filas) ...<Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 150,
                    child: Text(
                      fila.etiqueta,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(fila.valor, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (acciones.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              ...acciones,
            ],
          ],
        ),
      ),
    );
  }
}
