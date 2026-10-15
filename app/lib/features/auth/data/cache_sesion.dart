import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/usuario.dart';

/// Caché local de sesión para uso sin conexión (spec 001, T014).
///
/// Guarda en el dispositivo (vía `shared_preferences`):
/// - el perfil del usuario (con sus roles y `empresaId`, que definen sus
///   permisos), y
/// - el documento de la empresa (del que se recalcula la licencia).
///
/// Se usa como respaldo cuando Firestore no responde (sin red). Al cerrar
/// sesión se limpia para no dejar datos de una cuenta anterior.
class CacheSesion {
  CacheSesion({Future<SharedPreferences> Function()? preferencias})
      : _preferencias = preferencias ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferencias;

  static const String _clavePerfil = 'cache.perfil';
  static const String _prefijoEmpresa = 'cache.empresa.';

  /// Guarda el perfil del usuario autenticado.
  Future<void> guardarPerfil(Usuario usuario) async {
    final prefs = await _preferencias();
    await prefs.setString(_clavePerfil, jsonEncode(usuario.toMap()));
  }

  /// Devuelve el perfil guardado, siempre que corresponda a [uid].
  Future<Usuario?> leerPerfil(String uid) async {
    final prefs = await _preferencias();
    final mapa = _leerMapa(prefs, _clavePerfil);
    if (mapa == null || mapa['uid'] != uid) return null;
    return Usuario.fromMap(uid, mapa);
  }

  /// Guarda el documento `empresas/{empresaId}` para poder recalcular la
  /// licencia sin conexión.
  Future<void> guardarEmpresa(
    String empresaId,
    Map<String, dynamic> datos,
  ) async {
    final prefs = await _preferencias();
    final json = jsonEncode(_aJsonSeguro(datos));
    await prefs.setString('$_prefijoEmpresa$empresaId', json);
  }

  /// Devuelve el documento de empresa guardado, o `null`.
  Future<Map<String, dynamic>?> leerEmpresa(String empresaId) async {
    final prefs = await _preferencias();
    return _leerMapa(prefs, '$_prefijoEmpresa$empresaId');
  }

  /// Borra todo lo guardado (al cerrar sesión).
  Future<void> limpiar() async {
    final prefs = await _preferencias();
    final claves = prefs
        .getKeys()
        .where((k) => k == _clavePerfil || k.startsWith(_prefijoEmpresa))
        .toList(growable: false);
    for (final clave in claves) {
      await prefs.remove(clave);
    }
  }

  Map<String, dynamic>? _leerMapa(SharedPreferences prefs, String clave) {
    final crudo = prefs.getString(clave);
    if (crudo == null) return null;
    try {
      final decodificado = jsonDecode(crudo);
      if (decodificado is Map) {
        return decodificado.cast<String, dynamic>();
      }
    } catch (_) {
      // Dato corrupto: se ignora y se trata como si no hubiera caché.
    }
    return null;
  }

  /// Convierte valores de Firestore ([Timestamp], [DateTime], etc.) a algo que
  /// `jsonEncode` pueda escribir.
  static dynamic _aJsonSeguro(dynamic valor) {
    if (valor == null ||
        valor is num ||
        valor is bool ||
        valor is String) {
      return valor;
    }
    if (valor is DateTime) return valor.toUtc().toIso8601String();
    if (valor is List) return valor.map(_aJsonSeguro).toList();
    if (valor is Map) {
      return <String, dynamic>{
        for (final entrada in valor.entries)
          entrada.key.toString(): _aJsonSeguro(entrada.value),
      };
    }
    // Marca de tiempo de Firestore u otro objeto con `toDate()`.
    try {
      final dynamic fecha = (valor as dynamic).toDate();
      if (fecha is DateTime) return fecha.toUtc().toIso8601String();
    } catch (_) {
      // No es una fecha; se guarda su representación en texto.
    }
    return valor.toString();
  }
}
