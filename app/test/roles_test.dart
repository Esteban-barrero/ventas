import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/permisos.dart';
import 'package:ventas_app/features/auth/domain/roles.dart';

void main() {
  group('RBAC', () {
    test('la union de roles une los permisos', () {
      final permisos = permisosDeRoles(<Rol>[Rol.administrador, Rol.developer]);

      expect(permisos.contains(Permiso.ventasVer), isTrue);
      expect(permisos.contains(Permiso.logsVer), isTrue);
    });

    test('el vendedor no ve reportes ni opera caja', () {
      final permisos = permisosDeRoles(<Rol>[Rol.vendedor]);

      expect(permisos.contains(Permiso.ventasCrear), isTrue);
      expect(permisos.contains(Permiso.reportesVer), isFalse);
      expect(permisos.contains(Permiso.cajaOperar), isFalse);
    });

    test('solo el developer ve los logs de errores', () {
      expect(permisosDeRoles(<Rol>[Rol.developer]), <Permiso>{Permiso.logsVer});
      expect(
        permisosDeRoles(<Rol>[Rol.administrador]).contains(Permiso.logsVer),
        isFalse,
      );
      expect(
        permisosDeRoles(<Rol>[Rol.superAdmin]).contains(Permiso.logsVer),
        isTrue,
      );
    });

    test('el Administrador tiene acceso total dentro de su empresa', () {
      final permisos = permisosDeRoles(<Rol>[Rol.administrador]);

      expect(permisos.contains(Permiso.ventasCrear), isTrue);
      expect(permisos.contains(Permiso.usuariosGestionar), isTrue);
      expect(permisos.contains(Permiso.parametrosEditar), isTrue);
      // Pero no gestiona empresas (eso es del Super Admin).
      expect(permisos.contains(Permiso.empresasGestionar), isFalse);
    });

    test('Roles.desdeId ignora ids desconocidos', () {
      expect(Rol.desdeId('administrador'), Rol.administrador);
      expect(Rol.desdeId('no-existe'), isNull);
    });
  });
}
