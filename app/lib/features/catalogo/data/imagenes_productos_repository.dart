import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// La imagen no cumple el formato o el tamaño permitido (spec 003, RF-03).
class ImagenInvalidaException implements Exception {
  const ImagenInvalidaException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Sube y borra las imágenes de un producto en Firebase Storage (spec 003).
///
/// Ruta: `empresas/{empresaId}/productos/{productoId}/{nombre}.{ext}`.
class ImagenesProductosRepository {
  ImagenesProductosRepository({FirebaseStorage? storage})
      : _storageOverride = storage;

  final FirebaseStorage? _storageOverride;

  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  /// Tamaño máximo permitido (5 MB, igual que las reglas de Storage).
  static const int maxBytes = 5 * 1024 * 1024;

  /// Extensiones permitidas.
  static const List<String> extensionesPermitidas = <String>[
    'png',
    'jpg',
    'jpeg',
    'webp',
  ];

  /// Valida el formato y el tamaño antes de subir.
  static void validar(Uint8List bytes, {required String extension}) {
    final ext = extension.toLowerCase();
    if (!extensionesPermitidas.contains(ext)) {
      throw const ImagenInvalidaException(
        'Formato no permitido. Usa PNG, JPG o WebP.',
      );
    }
    if (bytes.lengthInBytes > maxBytes) {
      final mb = bytes.lengthInBytes / (1024 * 1024);
      throw ImagenInvalidaException(
        'La imagen pesa ${mb.toStringAsFixed(1)} MB y el máximo es 5 MB.',
      );
    }
  }

  /// Sube una imagen y devuelve su URL de descarga.
  ///
  /// Refresca el ID token para que las reglas de Storage vean los *custom
  /// claims* vigentes (mismo criterio que el logo de la empresa).
  Future<String> subir(
    String empresaId,
    String productoId,
    Uint8List bytes, {
    String nombre = 'foto',
    String extension = 'png',
  }) async {
    validar(bytes, extension: extension);

    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      // Si no se puede refrescar, se intenta igualmente.
    }

    final ref = _storage.ref(
      'empresas/$empresaId/productos/$productoId/$nombre.$extension',
    );
    final tarea = await ref.putData(
      bytes,
      SettableMetadata(contentType: _tipoContenido(extension)),
    );
    return tarea.ref.getDownloadURL();
  }

  /// Borra una imagen a partir de su URL de descarga.
  Future<void> borrarPorUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException {
      // Si no existe, no es un error.
    }
  }

  static String _tipoContenido(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }
}
