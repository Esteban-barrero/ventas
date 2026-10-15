/// Formato de fechas y valores para la interfaz (es-CO).
library;

/// Formatea una fecha como `dd/MM/yyyy` (o `—` si es nula).
String formatearFecha(DateTime? fecha) {
  if (fecha == null) return '—';
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

/// Formatea un valor numérico con separadores de miles (ej: `1.234.567`).
String formatearValor(num valor) {
  final entero = valor.round().abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buffer.write('.');
    buffer.write(entero[i]);
  }

  final signo = valor < 0 ? '-' : '';
  return '$signo${buffer.toString()}';
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
