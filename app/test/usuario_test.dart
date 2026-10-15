import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/datos_usuario.dart';
import 'package:ventas_app/features/auth/domain/permisos.dart';
import 'package:ventas_app/features/auth/domain/roles.dart';

void main() {
  group('Rol.asignables', () {
    test('excluye el rol Super Admin', () {
      expect(Rol.asignables.contains(Rol.superAdmin), isFalse);
    });

    test('incluye los roles de empresa', () {
      expect(Rol.asignables.contains(Rol.administrador), isTrue);
      expect(Rol.asignables.contains(Rol.vendedor), isTrue);
      expect(Rol.asignables.contains(Rol.developer), isTrue);
    });
  });

  group('DatosNuevoUsuario.validar', () {
    test('exige el nombre', () {
      const datos = DatosNuevoUsuario(
        nombre: '   ',
        email: 'ana@ejemplo.com',
        roles: <String>['vendedor'],
      );
      expect(datos.validar(), 'El nombre es obligatorio.');
    });

    test('exige un correo válido', () {
      const datos = DatosNuevoUsuario(
        nombre: 'Ana',
        email: 'correo-malo',
        roles: <String>['vendedor'],
      );
      expect(datos.validar(), 'El correo no es válido.');
    });

    test('exige al menos un rol', () {
      const datos = DatosNuevoUsuario(nombre: 'Ana', email: 'ana@ejemplo.com');
      expect(datos.validar(), 'Asigna al menos un rol.');
    });

    test('exige empresa cuando quien crea es el Super Admin', () {
      const datos = DatosNuevoUsuario(
        nombre: 'Ana',
        email: 'ana@ejemplo.com',
        roles: <String>['vendedor'],
      );
      expect(datos.validar(requiereEmpresa: true), 'Selecciona la empresa.');
      expect(datos.validar(), isNull);
    });

    test('acepta datos completos', () {
      const datos = DatosNuevoUsuario(
        nombre: 'Ana',
        email: 'ana@ejemplo.com',
        roles: <String>['vendedor'],
        empresaId: 'emp1',
      );
      expect(datos.validar(requiereEmpresa: true), isNull);
    });
  });

  group('DatosNuevoUsuario.toMap', () {
    test('recorta espacios y normaliza el correo', () {
      const datos = DatosNuevoUsuario(
        nombre: '  Ana  ',
        email: '  Ana@Ejemplo.COM ',
        telefono: ' 300 123 ',
        roles: <String>['vendedor'],
        empresaId: 'emp1',
      );
      final mapa = datos.toMap();
      expect(mapa['nombre'], 'Ana');
      expect(mapa['email'], 'ana@ejemplo.com');
      expect(mapa['telefono'], '300 123');
      expect(mapa['roles'], <String>['vendedor']);
      expect(mapa['activo'], isTrue);
      expect(mapa['empresaId'], 'emp1');
    });

    test('omite empresaId cuando está vacío', () {
      const datos = DatosNuevoUsuario(
        nombre: 'Ana',
        email: 'ana@ejemplo.com',
        roles: <String>['vendedor'],
      );
      expect(datos.toMap().containsKey('empresaId'), isFalse);
    });
  });

  group('permisos de gestión de usuarios', () {
    test('el Administrador puede gestionar usuarios', () {
      final permisos = permisosDeRoles(<Rol>[Rol.administrador]);
      expect(permisos.contains(Permiso.usuariosGestionar), isTrue);
    });

    test('el Vendedor no puede gestionar usuarios', () {
      final permisos = permisosDeRoles(<Rol>[Rol.vendedor]);
      expect(permisos.contains(Permiso.usuariosGestionar), isFalse);
    });
  });
}
