import 'package:firebase_core/firebase_core.dart';

/// `true` si la excepcion corresponde a un problema de conectividad.
///
/// Se usa para decidir cuando recurrir a la cache local (spec 001, T014).
/// Un error de permisos NO cuenta como error de red: en ese caso nunca se debe
/// caer en la cache.
bool esErrorDeRed(FirebaseException excepcion) {
  switch (excepcion.code) {
    case 'unavailable':
    case 'deadline-exceeded':
    case 'network-request-failed':
      return true;
    default:
      return false;
  }
}
