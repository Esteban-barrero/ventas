import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/licencia.dart';

/// Aviso de vencimiento proximo de la licencia (spec 001, RN-06).
///
/// Se muestra en el inicio cuando faltan `diasAvisoVencimiento` dias o menos
/// (por defecto 5). Permanece visible [duracion] (40 s por defecto) y luego se
/// desvanece y se quita solo, dejando que el contenido de abajo se reacomode.
/// Tambien se puede ocultar manualmente con la "x".
class AvisoLicencia extends StatefulWidget {
  const AvisoLicencia({
    super.key,
    required this.estado,
    this.duracion = const Duration(seconds: 40),
  });

  final EstadoLicencia estado;

  /// Tiempo que el aviso permanece visible antes de ocultarse solo.
  final Duration duracion;

  @override
  State<AvisoLicencia> createState() => _AvisoLicenciaState();
}

class _AvisoLicenciaState extends State<AvisoLicencia> {
  static const Duration _animacion = Duration(milliseconds: 400);

  Timer? _temporizador;
  Timer? _temporizadorSalida;
  bool _visible = true;
  double _opacidad = 1;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(widget.duracion, _ocultar);
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _temporizadorSalida?.cancel();
    super.dispose();
  }

  /// Desvanece el aviso y luego lo quita para que el resto se reacomode.
  void _ocultar() {
    if (!mounted || !_visible) return;
    _temporizador?.cancel();
    setState(() => _opacidad = 0);
    _temporizadorSalida = Timer(_animacion, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _animacion,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: _visible
          ? AnimatedOpacity(
              opacity: _opacidad,
              duration: _animacion,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _tarjeta(context),
              ),
            )
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  Widget _tarjeta(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dias = widget.estado.diasRestantes;

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
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
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
            IconButton(
              tooltip: 'Ocultar aviso',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, color: scheme.onSecondaryContainer),
              onPressed: _ocultar,
            ),
          ],
        ),
      ),
    );
  }
}
