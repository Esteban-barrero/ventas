import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/core/validacion/correo.dart';

void main() {
  group('esCorreoValido', () {
    test('acepta correos con formato razonable', () {
      expect(esCorreoValido('maria@correo.com'), isTrue);
      expect(esCorreoValido('a.b+c@dominio.co'), isTrue);
      expect(esCorreoValido('  esteban@ejemplo.com  '), isTrue);
    });

    test('rechaza vacíos, sin arroba o sin dominio', () {
      expect(esCorreoValido(''), isFalse);
      expect(esCorreoValido('correo'), isFalse);
      expect(esCorreoValido('correo@'), isFalse);
      expect(esCorreoValido('correo@dominio'), isFalse);
      expect(esCorreoValido('co rreo@dominio.com'), isFalse);
    });
  });
}
