import 'package:flutter/services.dart';

/// Formatea un campo de dinero mientras se escribe, con **miles con punto** y
/// **decimales con coma** (estilo Colombia). Limita los decimales a [decimales].
///
/// Ej: al escribir `2400000` el campo muestra `2.400.000`.
class MilesInputFormatter extends TextInputFormatter {
  const MilesInputFormatter({this.decimales = 2});

  /// Número máximo de decimales permitidos.
  final int decimales;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = newValue.text;
    final tieneComa = texto.contains(',');
    final partes = texto.split(',');
    final entero = partes.first.replaceAll(RegExp(r'[^0-9]'), '');
    var decimal = partes.length > 1
        ? partes.sublist(1).join().replaceAll(RegExp(r'[^0-9]'), '')
        : '';

    if (decimales == 0) {
      decimal = '';
    } else if (decimal.length > decimales) {
      decimal = decimal.substring(0, decimales);
    }

    final enteroFormateado = _conMiles(entero);
    final resultado = tieneComa ? '$enteroFormateado,$decimal' : enteroFormateado;
    return TextEditingValue(
      text: resultado,
      selection: TextSelection.collapsed(offset: resultado.length),
    );
  }

  /// Inserta el separador de miles (`.`) cada tres dígitos.
  static String _conMiles(String digitos) {
    if (digitos.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digitos[i]);
    }
    return buffer.toString();
  }
}
