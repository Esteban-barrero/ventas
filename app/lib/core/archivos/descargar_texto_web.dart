// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Descarga un archivo de texto desde el navegador (spec 015).
Future<bool> descargarTexto(
  String nombre,
  String contenido, {
  String mime = 'text/plain',
}) async {
  final blob = html.Blob(<Object>[contenido], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', nombre)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
