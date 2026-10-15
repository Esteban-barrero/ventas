import 'package:flutter/material.dart';

/// Paleta suave (ámbar) para mensajes de aviso o bloqueo.
///
/// Deliberadamente no usa el rojo de error: se busca un tono cordial para
/// comunicar al usuario que debe hacer algo (renovar, pedir acceso, etc.).
class AcentosSuaves {
  const AcentosSuaves({required this.icono, required this.fondo});

  final Color icono;
  final Color fondo;

  factory AcentosSuaves.de(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const AcentosSuaves(
        icono: Color(0xFFFFCC80),
        fondo: Color(0xFF4E342E),
      );
    }
    return const AcentosSuaves(
      icono: Color(0xFFE65100),
      fondo: Color(0xFFFFF3E0),
    );
  }
}

/// Estructura visual compartida de las pantallas de aviso/bloqueo.
///
/// Muestra un ícono en un círculo suave, un título, un mensaje y, si hacen
/// falta, un contenido extra (`cuerpo`) y acciones (`acciones`).
///
/// No incluye `Scaffold`: cada pantalla decide si quiere AppBar.
class MarcoAviso extends StatelessWidget {
  const MarcoAviso({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.detalleExtra,
    this.cuerpo = const <Widget>[],
    this.acciones = const <Widget>[],
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final String? detalleExtra;

  /// Contenido adicional (por ejemplo, detalles de la licencia).
  final List<Widget> cuerpo;

  /// Botones de acción. Se reparten el ancho disponible.
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final acentos = AcentosSuaves.de(theme.brightness);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: acentos.fondo,
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, size: 44, color: acentos.icono),
              ),
              const SizedBox(height: 20),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              if (detalleExtra != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  detalleExtra!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (cuerpo.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                ...cuerpo,
              ],
              if (acciones.isNotEmpty) ...<Widget>[
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    for (var i = 0; i < acciones.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: acciones[i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
