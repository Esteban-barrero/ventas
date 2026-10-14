import 'package:flutter/material.dart';

/// Colores de la paleta por defecto del aplicativo (Azul + Naranja).
/// Ver spec 014-parametros-tema.
const Color kColorPrimario = Color(0xFF1A73E8);
const Color kColorSecundario = Color(0xFFFF6B35);

/// Construye el tema de la app a partir de la paleta activa.
///
/// En la version final la paleta vendra de Firestore (spec 014) y se aplicara
/// en tiempo real; aqui usamos la paleta base para la prueba inicial.
ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kColorPrimario,
    brightness: brightness,
  ).copyWith(secondary: kColorSecundario);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      centerTitle: true,
    ),
  );
}
