import 'package:flutter/material.dart';

import '../../domain/producto.dart';

/// Imagen de un producto: la foto principal o un marcador si falta o no carga.
///
/// Si la descarga falla (sin conexión, CORS del bucket, etc.) muestra un
/// marcador en lugar de dejar el espacio vacío (mismo criterio que el logo de
/// la empresa, spec 002).
class ImagenProducto extends StatelessWidget {
  const ImagenProducto({
    super.key,
    required this.producto,
    this.ajuste = BoxFit.cover,
  });

  final Producto producto;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!producto.tieneFoto) return _marcador(scheme);

    return Image.network(
      producto.fotoPrincipal,
      fit: ajuste,
      errorBuilder: (_, _, _) => _marcador(scheme),
      loadingBuilder: (context, child, progreso) =>
          progreso == null ? child : _cargando(scheme),
    );
  }

  Widget _marcador(ColorScheme scheme) => Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.image_not_supported_outlined, color: scheme.outline),
      );

  Widget _cargando(ColorScheme scheme) => Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
}
