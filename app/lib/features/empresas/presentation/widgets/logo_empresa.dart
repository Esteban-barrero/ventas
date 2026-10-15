import 'package:flutter/material.dart';

import '../../domain/empresa.dart';

/// Logo de una empresa (spec 002, RF-06).
///
/// Muestra la imagen guardada en Storage (`empresas/{id}.logo`) o, si la
/// empresa no tiene logo **o la imagen no se puede cargar**, las iniciales del
/// nombre sobre un círculo con el color primario.
///
/// La imagen puede fallar, por ejemplo, sin conexión o si el bucket de Storage
/// no tiene configurada la CORS (necesaria para que Flutter Web descargue la
/// imagen; ver `cors.json`). En ese caso se cae a las iniciales para no dejar un
/// círculo vacío.
///
/// Es un [StatefulWidget] porque necesita recordar que la imagen falló y
/// reintentar la carga cuando cambia la URL del logo.
class LogoEmpresa extends StatefulWidget {
  const LogoEmpresa({super.key, required this.empresa, this.radio = 22});

  final Empresa empresa;
  final double radio;

  @override
  State<LogoEmpresa> createState() => _LogoEmpresaState();
}

class _LogoEmpresaState extends State<LogoEmpresa> {
  /// `true` cuando la imagen del logo no se pudo descargar.
  bool _falloLaImagen = false;

  @override
  void didUpdateWidget(LogoEmpresa anterior) {
    super.didUpdateWidget(anterior);
    // Si cambia la URL del logo (por ejemplo, tras subir uno nuevo), se
    // reintenta la carga. No se usa `setState` porque el widget se vuelve a
    // construir de inmediato tras esta llamada.
    if (anterior.empresa.logo != widget.empresa.logo) {
      _falloLaImagen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.empresa.tieneLogo || _falloLaImagen) {
      return _avatarIniciales(context);
    }

    return CircleAvatar(
      radius: widget.radio,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      backgroundImage: NetworkImage(widget.empresa.logo),
      // Si la descarga falla, se muestran las iniciales en lugar de un círculo
      // vacío (evita la confusión de un logo "gris").
      onBackgroundImageError: (_, _) {
        if (!mounted) return;
        setState(() => _falloLaImagen = true);
      },
    );
  }

  /// Círculo con las iniciales del nombre de la empresa.
  Widget _avatarIniciales(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return CircleAvatar(
      radius: widget.radio,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        _iniciales(widget.empresa.nombre),
        style: theme.textTheme.titleMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Primeras dos iniciales del nombre (por ejemplo, "Empresa Demo" -> "ED").
  static String _iniciales(String texto) {
    final partes =
        texto.trim().split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
