import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/data/usuarios_repository.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/auth/presentation/usuario_form_screen.dart';
import 'package:ventas_app/features/auth/presentation/usuarios_list_screen.dart';

/// Repositorio falso: sirve listas de usuarios en memoria sin tocar Firebase.
class _UsuariosFake extends UsuariosRepository {
  _UsuariosFake(this.usuarios);

  final List<Usuario> usuarios;

  @override
  Stream<List<Usuario>> escucharDeEmpresa(String empresaId) =>
      Stream<List<Usuario>>.value(
        usuarios
            .where((u) => u.empresaId == empresaId)
            .toList(growable: false),
      );

  @override
  Stream<List<Usuario>> escucharTodos() =>
      Stream<List<Usuario>>.value(usuarios);
}

const _admin = Usuario(
  uid: 'admin',
  nombre: 'Admin',
  email: 'admin@ejemplo.com',
  empresaId: 'emp1',
  roles: <String>['administrador'],
);

const _super = Usuario(
  uid: 'super',
  nombre: 'Super',
  email: 'super@ejemplo.com',
  roles: <String>['superadmin'],
);

/// Pantalla muy alta para que los `ListView` construyan todos sus hijos.
Future<void> _montar(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1000, 9000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
}

void main() {
  testWidgets('la lista muestra los usuarios de la propia empresa',
      (tester) async {
    final repo = _UsuariosFake(const <Usuario>[
      Usuario(
        uid: 'u1',
        nombre: 'Ana',
        email: 'ana@ejemplo.com',
        empresaId: 'emp1',
        roles: <String>['vendedor'],
      ),
      Usuario(
        uid: 'u2',
        nombre: 'Beto',
        email: 'beto@ejemplo.com',
        empresaId: 'emp1',
        roles: <String>['administrador', 'developer'],
      ),
      Usuario(
        uid: 'u3',
        nombre: 'Otra',
        email: 'otra@otra.com',
        empresaId: 'emp2',
        roles: <String>['gerente'],
      ),
    ]);

    await _montar(
      tester,
      UsuariosListScreen(usuario: _admin, repository: repo),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Beto'), findsOneWidget);
    // No se listan usuarios de otras empresas.
    expect(find.text('Otra'), findsNothing);
    expect(find.text('Vendedor'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('la lista filtra por nombre o correo', (tester) async {
    final repo = _UsuariosFake(const <Usuario>[
      Usuario(
        uid: 'u1',
        nombre: 'Ana',
        email: 'ana@ejemplo.com',
        empresaId: 'emp1',
        roles: <String>['vendedor'],
      ),
      Usuario(
        uid: 'u2',
        nombre: 'Beto',
        email: 'beto@ejemplo.com',
        empresaId: 'emp1',
        roles: <String>['vendedor'],
      ),
    ]);

    await _montar(
      tester,
      UsuariosListScreen(usuario: _admin, repository: repo),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'beto');
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsNothing);
    expect(find.text('Beto'), findsOneWidget);
  });

  testWidgets('el Super Admin ve la empresa de cada usuario', (tester) async {
    final repo = _UsuariosFake(const <Usuario>[
      Usuario(
        uid: 'u1',
        nombre: 'Ana',
        email: 'ana@ejemplo.com',
        empresaId: 'emp1',
        roles: <String>['vendedor'],
      ),
    ]);

    await _montar(
      tester,
      UsuariosListScreen(usuario: _super, repository: repo),
    );
    await tester.pumpAndSettle();

    expect(find.text('Empresa: emp1'), findsOneWidget);
  });

  testWidgets('el formulario de nuevo usuario muestra campos y roles',
      (tester) async {
    await _montar(tester, const UsuarioFormScreen(usuarioActual: _admin));

    expect(find.text('Nuevo usuario'), findsOneWidget);
    expect(find.text('Nombre *'), findsOneWidget);
    expect(find.text('Correo (acceso) *'), findsOneWidget);
    expect(find.text('Vendedor'), findsOneWidget);
    expect(find.text('Crear usuario'), findsOneWidget);
    // El rol Super Admin no se ofrece desde la empresa.
    expect(find.text('Super Admin'), findsNothing);
  });

  testWidgets('el formulario exige un rol antes de crear', (tester) async {
    await _montar(tester, const UsuarioFormScreen(usuarioActual: _admin));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@ejemplo.com');
    await tester.tap(find.text('Crear usuario'));
    await tester.pumpAndSettle();

    expect(find.text('Asigna al menos un rol.'), findsOneWidget);
  });

  testWidgets('al editar, el correo de acceso queda deshabilitado',
      (tester) async {
    await _montar(
      tester,
      const UsuarioFormScreen(
        usuarioActual: _admin,
        usuario: Usuario(
          uid: 'u1',
          nombre: 'Ana',
          email: 'ana@ejemplo.com',
          empresaId: 'emp1',
          roles: <String>['vendedor'],
        ),
      ),
    );

    expect(find.text('Editar usuario'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsOneWidget);

    final campos =
        tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(campos[0].enabled, isTrue); // nombre
    expect(campos[1].enabled, isFalse); // correo de acceso
  });
}
