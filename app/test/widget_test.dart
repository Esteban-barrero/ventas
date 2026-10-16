import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/home/home_page.dart';
import 'package:ventas_app/features/licencia/domain/licencia.dart';

Future<void> _dummy() async {}

Future<void> _montar(WidgetTester tester, Widget child) async {
  // Pantalla alta para que el ListView construya todos los módulos.
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: child));
}

void main() {
  testWidgets('HomePage muestra roles y modulos segun permisos',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u1',
      nombre: 'Esteban Barrero',
      email: 'esteban@ejemplo.com',
      empresaId: 'empresa-1',
      roles: <String>['administrador'],
    );

    await _montar(
      tester,
      HomePage(usuario: usuario, onCerrarSesion: _dummy),
    );

    // Rol visible.
    expect(find.text('Administrador'), findsOneWidget);

    // Modulos a los que SI tiene permiso.
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Ventas'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);

    // Un Administrador NO ve el modulo de logs (solo Developer).
    expect(find.text('Logs de errores'), findsNothing);
  });

  testWidgets('Un developer solo ve el modulo de logs',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u2',
      nombre: 'Dev',
      email: 'dev@ejemplo.com',
      roles: <String>['developer'],
    );

    await _montar(
      tester,
      HomePage(usuario: usuario, onCerrarSesion: _dummy),
    );

    expect(find.text('Logs de errores'), findsOneWidget);
    expect(find.text('Ventas'), findsNothing);
  });

  testWidgets('Un Super Admin sin empresa no ve los módulos operativos',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u8',
      nombre: 'Super Admin',
      email: 'super@ejemplo.com',
      roles: <String>['superadmin'],
    );

    await _montar(
      tester,
      HomePage(usuario: usuario, onCerrarSesion: _dummy),
    );

    // Módulos globales visibles.
    expect(find.text('Empresas'), findsOneWidget);
    expect(find.text('Usuarios'), findsOneWidget);
    expect(find.text('Logs de errores'), findsOneWidget);

    // Módulos operativos ocultos: el Super Admin no pertenece a una empresa.
    expect(find.text('Ventas'), findsNothing);
    expect(find.text('Caja'), findsNothing);
    expect(find.text('Catálogo'), findsNothing);
    expect(find.text('Mi empresa'), findsNothing);
  });

  testWidgets('HomePage muestra el aviso de licencia por vencer',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u3',
      nombre: 'Admin',
      email: 'admin@ejemplo.com',
      empresaId: 'empresa-1',
      roles: <String>['administrador'],
    );
    const aviso = EstadoLicencia(
      vigente: true,
      estado: EstadoEmpresa.activa,
      diasRestantes: 3,
    );

    await _montar(
      tester,
      HomePage(usuario: usuario, onCerrarSesion: _dummy, avisoLicencia: aviso),
    );

    expect(find.text('Tu licencia vence en 3 días.'), findsOneWidget);
  });

  testWidgets('HomePage sin aviso no muestra banner de licencia',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u4',
      nombre: 'Admin',
      email: 'admin@ejemplo.com',
      empresaId: 'empresa-1',
      roles: <String>['administrador'],
    );

    await _montar(
      tester,
      HomePage(usuario: usuario, onCerrarSesion: _dummy),
    );

    expect(find.textContaining('Tu licencia vence'), findsNothing);
  });

  testWidgets('HomePage abre un módulo cuando el usuario tiene permiso',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u5',
      nombre: 'Admin',
      email: 'admin@ejemplo.com',
      empresaId: 'empresa-1',
      roles: <String>['administrador'],
    );

    await _montar(
      tester,
      HomePage(usuario: usuario, onCerrarSesion: _dummy),
    );

    await tester.ensureVisible(find.text('Inventario'));
    await tester.tap(find.text('Inventario'));
    await tester.pumpAndSettle();

    expect(find.text('Módulo en construcción.'), findsOneWidget);
    expect(find.text('Requiere: Ver inventario'), findsOneWidget);
  });

  testWidgets('HomePage avisa cuando se muestran datos guardados sin conexión',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u6',
      nombre: 'Admin',
      email: 'admin@ejemplo.com',
      empresaId: 'empresa-1',
      roles: <String>['administrador'],
    );

    await _montar(
      tester,
      HomePage(usuario: usuario, onCerrarSesion: _dummy, datosGuardados: true),
    );

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.textContaining('información guardada'), findsOneWidget);
  });

  testWidgets('HomePage no avisa de conexión cuando los datos son frescos',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u7',
      nombre: 'Admin',
      email: 'admin@ejemplo.com',
      empresaId: 'empresa-1',
      roles: <String>['administrador'],
    );

    await _montar(
      tester,
      HomePage(usuario: usuario, onCerrarSesion: _dummy),
    );

    expect(find.text('Sin conexión'), findsNothing);
  });
}
