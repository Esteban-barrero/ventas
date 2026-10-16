import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/core/formato/fechas.dart';

void main() {
  group('formatearValor (miles con punto, decimales con coma)', () {
    test('enteros: separa miles y no muestra ,00', () {
      expect(formatearValor(3427035), '3.427.035');
      expect(formatearValor(1000), '1.000');
      expect(formatearValor(0), '0');
    });

    test('con decimales: usa coma y dos dígitos', () {
      expect(formatearValor(3427035.5), '3.427.035,50');
      expect(formatearValor(427.5), '427,50');
      expect(formatearValor(1500.25), '1.500,25');
    });

    test('negativos y redondeo a 2 decimales', () {
      expect(formatearValor(-2500), '-2.500');
      expect(formatearValor(10.999), '11');
    });
  });
}
