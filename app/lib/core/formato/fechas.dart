/// Formato de fechas y valores para la interfaz (es-CO).
library;

/// Formatea una fecha como `dd/MM/yyyy` (o `—` si es nula).
String formatearFecha(DateTime? fecha) {
  if (fecha == null) return '—';
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

/// Formatea un valor numérico con separador de **miles** (`.`) y **decimales**
/// con **coma** (`,`) — estilo **Colombia**.
///
/// Los decimales se muestran **solo si el valor los tiene** (2 decimales); si
/// son `,00` se omiten. Ej: `3427035` → `3.427.035`; `3427035.5` → `3.427.035,50`.
String formatearValor(num valor) {
  final negativo = valor < 0;
  final redondeado = (valor.abs() * 100).round();
  final entero = redondeado ~/ 100;
  final centavos = redondeado % 100;

  final signo = negativo ? '-' : '';
  final enteroTexto = _separarMiles(entero);
  if (centavos == 0) return '$signo$enteroTexto';
  return '$signo$enteroTexto,${centavos.toString().padLeft(2, '0')}';
}

/// Devuelve un número listo para un campo de texto **sin perder decimales**:
/// sin decimales si es entero y con 2 decimales (punto) si no.
///
/// Ej: `50000` → `50000`; `20677.5` → `20677.50`. Evita que un `.round()`
/// altere el valor real (por ejemplo, al proponer el monto de una rendición).
String numeroParaEditar(num valor) {
  if (valor == valor.roundToDouble()) return valor.round().toString();
  return valor.toStringAsFixed(2);
}

/// Interpreta un número escrito por el usuario aceptando **coma** o **punto**
/// como separador decimal (y quitando los puntos de miles si hay coma).
///
/// Ej: `20677.50` → `20677.5`; `20.677,50` → `20677.5`; `20677,5` → `20677.5`.
/// Devuelve `null` si el texto no es un número válido.
double? parsearNumero(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    return double.tryParse(t.replaceAll('.', '').replaceAll(',', '.'));
  }
  return double.tryParse(t);
}

/// Inserta el separador de miles (`.`) cada tres dígitos.
String _separarMiles(int numero) {  final texto = numero.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
    buffer.write(texto[i]);
  }
  return buffer.toString();
}

/// Describe en texto los días restantes de una licencia.
String describirDiasRestantes(int? dias) {
  if (dias == null) return 'Sin vencimiento';
  if (dias < 0) {
    final vencidos = dias.abs();
    return 'Vencida hace $vencidos día${vencidos == 1 ? '' : 's'}';
  }
  if (dias == 0) return 'Vence hoy';
  return 'Vence en $dias día${dias == 1 ? '' : 's'}';
}
