import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/cliente.dart';

/// Resultado de intentar capturar la ubicación del dispositivo.
class ResultadoUbicacion {
  const ResultadoUbicacion({this.ubicacion, this.error});

  final UbicacionGPS? ubicacion;
  final String? error;

  bool get ok => ubicacion != null;
}

/// Captura la ubicación GPS del dispositivo (spec 004, RF-04).
///
/// En **Web** funciona con la geolocalización del navegador; la geocodificación
/// inversa (dirección aproximada) solo está disponible en móvil, por eso se
/// intenta y, si no está disponible, se guardan solo latitud y longitud.
class UbicacionService {
  const UbicacionService();

  /// Pide permiso (si hace falta) y devuelve las coordenadas actuales.
  Future<ResultadoUbicacion> capturar() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const ResultadoUbicacion(
          error: 'El servicio de ubicación está desactivado.',
        );
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return const ResultadoUbicacion(
          error: 'Permiso de ubicación denegado.',
        );
      }

      final pos = await Geolocator.getCurrentPosition();
      return ResultadoUbicacion(
        ubicacion: UbicacionGPS(
          latitud: pos.latitude,
          longitud: pos.longitude,
          direccionAproximada:
              await _direccionAproximada(pos.latitude, pos.longitude),
          fecha: DateTime.now(),
        ),
      );
    } catch (e) {
      return ResultadoUbicacion(error: 'No se pudo obtener la ubicación: $e');
    }
  }

  /// Dirección aproximada por geocodificación inversa (móvil). En Web devuelve
  /// cadena vacía (no hay implementación).
  Future<String> _direccionAproximada(double latitud, double longitud) async {
    try {
      final lugares =
          await Geocoding().placemarkFromCoordinates(latitud, longitud);
      if (lugares.isEmpty) return '';
      final l = lugares.first;
      return <String>[
        if ((l.thoroughfare ?? '').isNotEmpty) l.thoroughfare!,
        if ((l.locality ?? '').isNotEmpty) l.locality!,
        if ((l.administrativeArea ?? '').isNotEmpty) l.administrativeArea!,
      ].join(', ');
    } catch (_) {
      return '';
    }
  }
}
