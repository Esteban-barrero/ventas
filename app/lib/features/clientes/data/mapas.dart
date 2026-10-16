import 'package:url_launcher/url_launcher.dart';

/// Abre ubicaciones en apps de mapas (spec 004, RF-05).
///
/// Se usa `url_launcher` (sin SDK de mapas embebido, ADR-003).
class Mapas {
  const Mapas();

  /// Abre Google Maps centrado en las coordenadas.
  Future<bool> googleMaps(double latitud, double longitud) => _abrir(
        'https://www.google.com/maps/search/?api=1&query=$latitud,$longitud',
      );

  /// Abre Waze navegando a las coordenadas.
  Future<bool> waze(double latitud, double longitud) => _abrir(
        'https://waze.com/ul?ll=$latitud,$longitud&navigate=yes',
      );

  Future<bool> _abrir(String url) async {
    try {
      return await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
