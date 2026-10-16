import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/core/formato/entrada_miles.dart';
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

  group('numeroParaEditar y parsearNumero', () {
    test('numeroParaEditar usa miles con punto y decimales con coma', () {
      expect(numeroParaEditar(50000), '50.000');
      expect(numeroParaEditar(20677.5), '20.677,50');
      expect(numeroParaEditar(1500.25), '1.500,25');
    });

    test('parsearNumero acepta el formato colombiano', () {
      expect(parsearNumero('20.677,50'), 20677.5);
      expect(parsearNumero('20677,5'), 20677.5);
      expect(parsearNumero('2.400.000'), 2400000);
      expect(parsearNumero('50.000'), 50000);
      expect(parsearNumero('50000'), 50000);
      expect(parsearNumero('20677.50'), 20677.5);
      expect(parsearNumero('abc'), isNull);
      expect(parsearNumero(''), isNull);
    });

    test('ida y vuelta: numeroParaEditar -> parsearNumero', () {
      expect(parsearNumero(numeroParaEditar(20677.5)), 20677.5);
      expect(parsearNumero(numeroParaEditar(1234)), 1234);
      expect(parsearNumero(numeroParaEditar(2400000)), 2400000);
    });
  });

  group('MilesInputFormatter', () {
    const f = MilesInputFormatter();
    TextEditingValue fmt(String t) => f.formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: t),
        );

    test('pone separador de miles y conserva la coma decimal', () {
      expect(fmt('2400000').text, '2.400.000');
      expect(fmt('20677,5').text, '20.677,5');
      expect(fmt('20677,50').text, '20.677,50');
      expect(fmt('12a3').text, '123');
      expect(fmt('').text, '');
    });
  });
}
