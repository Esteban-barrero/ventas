import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auditoria/data/auditoria_repository.dart';
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

  group('RegistroAuditoria y filtros (spec 012)', () {
    RegistroAuditoria reg({
      String operacion = 'UPDATE',
      String tabla = 'productos',
      DateTime? fecha,
      String usuario = 'u1',
      String campo = 'precio',
    }) =>
        RegistroAuditoria(
          id: 'a${fecha?.day ?? 0}',
          empresaId: 'e1',
          usuario: usuario,
          fecha: fecha ?? DateTime(2026, 10, 15),
          operacion: operacion,
          tabla: tabla,
          documentoId: 'doc',
          campo: campo,
          valorViejo: 100,
          valorNuevo: 120,
        );

    test('serializa y describe el cambio', () {
      final r = reg();
      final copia = RegistroAuditoria.fromMap('a1', r.toMap());
      expect(copia.tabla, 'productos');
      expect(copia.campo, 'precio');
      expect(copia.descripcion, 'precio: 100 → 120');
    });

    test('filtra por operacion, tabla, texto y fechas', () {
      final lista = <RegistroAuditoria>[
        reg(operacion: 'INSERT', tabla: 'ventas', fecha: DateTime(2026, 10, 10)),
        reg(operacion: 'UPDATE', tabla: 'productos', fecha: DateTime(2026, 10, 15)),
        reg(operacion: 'DELETE', tabla: 'clientes', fecha: DateTime(2026, 9, 1)),
      ];
      expect(
          AuditoriaRepository.filtrar(lista, operacion: 'UPDATE').length, 1);
      expect(AuditoriaRepository.filtrar(lista, tabla: 'ventas').length, 1);
      expect(AuditoriaRepository.filtrar(lista, busqueda: 'clientes').length, 1);
      expect(
          AuditoriaRepository.filtrar(lista, desde: DateTime(2026, 10, 1)).length,
          2);
      expect(
          AuditoriaRepository.filtrar(lista, hasta: DateTime(2026, 9, 30)).length,
          1);
    });
  });
}
