// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Descarga un archivo de texto desde el navegador (spec 015).
Future<bool> descargarTexto(
  String nombre,
  String contenido, {
  String mime = 'text/plain',
}) async =>
    _descargar(nombre, html.Blob(<Object>[contenido], mime));

/// Descarga un archivo binario (PDF, etc.) desde el navegador (spec 015).
Future<bool> descargarBytes(
  String nombre,
  Uint8List bytes, {
  String mime = 'application/octet-stream',
}) async =>
    _descargar(nombre, html.Blob(<Object>[bytes], mime));

bool _descargar(String nombre, html.Blob blob) {
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', nombre)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
