import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auditoria/domain/auditoria.dart';

void main() {
  group('calcularCambios', () {
    test('detecta el cambio de roles', () {
      final cambios = calcularCambios(
        <String, dynamic>{
          'roles': <String>['vendedor'],
        },
        <String, dynamic>{
          'roles': <String>['vendedor', 'cajero'],
        },
      );

      expect(cambios, hasLength(1));
      expect(cambios.single.campo, 'roles');
      expect(cambios.single.valorViejo, <String>['vendedor']);
      expect(cambios.single.valorNuevo, <String>['vendedor', 'cajero']);
    });

    test('no reporta nada si los valores son iguales', () {
      final cambios = calcularCambios(
        <String, dynamic>{
          'roles': <String>['administrador'],
          'activo': true,
        },
        <String, dynamic>{
          'roles': <String>['administrador'],
          'activo': true,
        },
      );

      expect(cambios, isEmpty);
    });

    test('no reporta si dos listas distintas tienen el mismo contenido', () {
      final cambios = calcularCambios(
        <String, dynamic>{
          'roles': <String>['a', 'b'],
        },
        <String, dynamic>{
          'roles': <String>['a', 'b'],
        },
      );

      expect(cambios, isEmpty);
    });

    test('detecta un campo agregado (valor viejo nulo)', () {
      final cambios = calcularCambios(
        const <String, dynamic>{},
        <String, dynamic>{'empresaId': 'demo'},
      );

      expect(cambios, hasLength(1));
      expect(cambios.single.campo, 'empresaId');
      expect(cambios.single.valorViejo, isNull);
      expect(cambios.single.valorNuevo, 'demo');
    });

    test('detecta un campo eliminado (valor nuevo nulo)', () {
      final cambios = calcularCambios(
        <String, dynamic>{'telefono': '3001234567'},
        <String, dynamic>{},
      );

      expect(cambios, hasLength(1));
      expect(cambios.single.campo, 'telefono');
      expect(cambios.single.valorViejo, '3001234567');
      expect(cambios.single.valorNuevo, isNull);
    });

    test('compara mapas anidados', () {
      final cambios = calcularCambios(
        <String, dynamic>{
          'licencia': <String, dynamic>{'tipo': 'mensual', 'dias': 5},
        },
        <String, dynamic>{
          'licencia': <String, dynamic>{'tipo': 'anual', 'dias': 5},
        },
      );

      expect(cambios, hasLength(1));
      expect(cambios.single.campo, 'licencia');
    });

    test('detecta varios cambios a la vez', () {
      final cambios = calcularCambios(
        <String, dynamic>{'roles': <String>['vendedor'], 'activo': true},
        <String, dynamic>{'roles': <String>['cajero'], 'activo': false},
      );

      expect(cambios.map((c) => c.campo).toSet(), {'roles', 'activo'});
    });
  });

  group('OperacionAuditoria', () {
    test('expone los codigos persistidos', () {
      expect(OperacionAuditoria.insert.id, 'INSERT');
      expect(OperacionAuditoria.update.id, 'UPDATE');
      expect(OperacionAuditoria.delete.id, 'DELETE');
    });
  });
}
