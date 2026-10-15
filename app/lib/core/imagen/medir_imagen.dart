import 'dart:typed_data';
import 'dart:ui' as ui;

/// Dimensiones de una imagen decodificada.
class DimensionesImagen {
  const DimensionesImagen({required this.ancho, required this.alto});

  final int ancho;
  final int alto;

  bool get esCuadrada => ancho == alto;

  @override
  String toString() => '$ancho×$alto';
}

/// Lee el ancho y alto reales de una imagen en memoria (ADR-004).
///
/// Devuelve `null` si los bytes no son una imagen válida.
Future<DimensionesImagen?> medirImagen(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final imagen = frame.image;
    final dims = DimensionesImagen(ancho: imagen.width, alto: imagen.height);
    imagen.dispose();
    codec.dispose();
    return dims;
  } catch (_) {
    return null;
  }
}
