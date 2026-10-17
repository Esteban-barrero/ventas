import 'dart:typed_data';

/// Descarga un archivo de texto (spec 015).
///
/// En plataformas **no web** no hay descarga directa: devuelve `false` para que
/// la pantalla ofrezca copiar el contenido.
Future<bool> descargarTexto(
  String nombre,
  String contenido, {
  String mime = 'text/plain',
}) async =>
    false;

/// Descarga un archivo binario. En **no web** devuelve `false`.
Future<bool> descargarBytes(
  String nombre,
  Uint8List bytes, {
  String mime = 'application/octet-stream',
}) async =>
    false;
