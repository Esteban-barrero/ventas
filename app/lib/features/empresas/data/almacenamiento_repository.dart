import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Error de validación de un archivo subido (por ejemplo, el logo).
class ArchivoInvalidoException implements Exception {
  const ArchivoInvalidoException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Sube archivos a Firebase Storage. Ver spec 002, RF-06.
///
/// Los logos viven en `empresas/{empresaId}/logo.{ext}` y las fotos de perfil
/// en `usuarios/{uid}/foto.{ext}` (spec 001).
class AlmacenamientoRepository {
  AlmacenamientoRepository({FirebaseStorage? storage})
      : _storageOverride = storage;

  final FirebaseStorage? _storageOverride;

  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  /// Tamaño máximo permitido para el logo (RN-07): 500 KB.
  static const int maxLogoBytes = 500 * 1024;

  /// Extensiones permitidas.
  static const List<String> extensionesPermitidas = <String>['png', 'jpg', 'jpeg', 'webp'];

  /// Valida el tamaño y la extensión del logo antes de subirlo.
  static void validarLogo(Uint8List bytes, {required String extension}) {
    final ext = extension.toLowerCase();
    if (!extensionesPermitidas.contains(ext)) {
      throw const ArchivoInvalidoException(
        'Formato no permitido. Usa PNG, JPG o WebP.',
      );
    }
    if (bytes.lengthInBytes > maxLogoBytes) {
      throw ArchivoInvalidoException(
        'El logo pesa ${(bytes.lengthInBytes / 1024).round()} KB y el máximo '
        'es 500 KB.',
      );
    }
  }

  /// Sube el logo y devuelve su URL de descarga.
  Future<String> subirLogo(
    String empresaId,
    Uint8List bytes, {
    String extension = 'png',
  }) async {
    validarLogo(bytes, extension: extension);

    // Refresca el ID token para que las reglas de Storage vean los claims
    // actuales (`superAdmin`, `empresaId`, `roles`), que emite la Cloud Function
    // `onUsuarioEscrito`. Sin esto, un token anterior a la asignación de claims
    // no autorizaría la escritura.
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      // Si no se puede refrescar (p. ej. sin conexión), se intenta igualmente.
    }

    final ref = _storage.ref('empresas/$empresaId/logo.$extension');
    final tarea = await ref.putData(
      bytes,
      SettableMetadata(contentType: _tipoContenido(extension)),
    );
    return tarea.ref.getDownloadURL();
  }

  /// Tamaño máximo de la foto de perfil del usuario (1 MB).
  static const int maxFotoBytes = 1024 * 1024;

  /// Valida la foto de perfil antes de subirla.
  static void validarFoto(Uint8List bytes, {required String extension}) {
    final ext = extension.toLowerCase();
    if (!extensionesPermitidas.contains(ext)) {
      throw const ArchivoInvalidoException(
        'Formato no permitido. Usa PNG, JPG o WebP.',
      );
    }
    if (bytes.lengthInBytes > maxFotoBytes) {
      throw ArchivoInvalidoException(
        'La foto pesa ${(bytes.lengthInBytes / 1024).round()} KB y el máximo '
        'es 1024 KB.',
      );
    }
  }

  /// Sube la **foto de perfil** de un usuario y devuelve su URL de descarga.
  ///
  /// Vive en `usuarios/{uid}/foto.{ext}` (spec 001).
  Future<String> subirFotoUsuario(
    String uid,
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    validarFoto(bytes, extension: extension);
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      // Si no se puede refrescar (p. ej. sin conexión), se intenta igualmente.
    }
    final ref = _storage.ref('usuarios/$uid/foto.$extension');
    final tarea = await ref.putData(
      bytes,
      SettableMetadata(contentType: _tipoContenido(extension)),
    );
    return tarea.ref.getDownloadURL();
  }

  /// Descarga los bytes del logo (para previsualizar/validar dimensiones).
  Future<Uint8List?> descargarLogo(String empresaId, {String extension = 'png'}) async {
    try {
      final ref = _storage.ref('empresas/$empresaId/logo.$extension');
      return await ref.getData();
    } on FirebaseException {
      return null;
    }
  }

  /// Borra el logo (al eliminar una empresa o reemplazarlo).
  ///
  /// Prueba todas las extensiones permitidas: el archivo puede ser `.png`,
  /// `.jpg`, `.jpeg` o `.webp`. Si alguno no existe, no es un error.
  Future<void> borrarLogo(String empresaId) async {
    for (final ext in extensionesPermitidas) {
      try {
        await _storage.ref('empresas/$empresaId/logo.$ext').delete();
      } on FirebaseException {
        // Si no existe, no es un error.
      }
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
