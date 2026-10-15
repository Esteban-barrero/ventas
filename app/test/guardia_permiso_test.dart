import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/core/navegacion/guardia_permiso.dart';
import 'package:ventas_app/features/auth/domain/permisos.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/home/modulo_screen.dart';

const Usuario _vendedor = Usuario(
  uid: 'u1',
  nombre: 'Vendedor',
  email: 'vendedor@ejemplo.com',
  roles: <String>['vendedor'],
);

const Usuario _developer = Usuario(
  uid: 'u2',
  nombre: 'Dev',
  email: 'dev@ejemplo.com',
  roles: <String>['developer'],
);

Future<void> _montar(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: child));
}

void main() {
  testWidgets('RutaProtegida deja pasar cuando hay permiso', (tester) async {
    await _montar(
      tester,
      const RutaProtegida(
        usuario: _vendedor,
        permiso: Permiso.ventasVer,
        child: Scaffold(body: Text('PANEL DE VENTAS')),
      ),
    );

    expect(find.text('PANEL DE VENTAS'), findsOneWidget);
    expect(find.text('No tienes acceso a este módulo'), findsNothing);
  });

  testWidgets('RutaProtegida muestra acceso denegado sin permiso',
      (tester) async {
    await _montar(
      tester,
      const RutaProtegida(
        usuario: _developer,
        permiso: Permiso.ventasVer,
        child: Scaffold(body: Text('PANEL DE VENTAS')),
      ),
    );

    // El Developer no accede a datos del negocio (RN-07).
    expect(find.text('PANEL DE VENTAS'), findsNothing);
    expect(find.text('No tienes acceso a este módulo'), findsOneWidget);
    expect(find.textContaining('Ver ventas'), findsOneWidget);
  });

  testWidgets('irAProtegido navega al módulo cuando hay permiso',
      (tester) async {
    await _montar(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => irAProtegido(
              context,
              usuario: _vendedor,
              permiso: Permiso.ventasVer,
              constructor: (_) => const ModuloScreen(
                nombre: 'Ventas',
                icono: Icons.point_of_sale_outlined,
                permiso: Permiso.ventasVer,
              ),
            ),
            child: const Text('ABRIR'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();

    expect(find.text('Módulo en construcción.'), findsOneWidget);
    expect(find.text('Requiere: Ver ventas'), findsOneWidget);
  });

  testWidgets('irAProtegido no navega y avisa cuando falta el permiso',
      (tester) async {
    await _montar(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => irAProtegido(
              context,
              usuario: _developer,
              permiso: Permiso.ventasVer,
              constructor: (_) => const Scaffold(body: Text('PANEL DE VENTAS')),
            ),
            child: const Text('ABRIR'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ABRIR'));
    await tester.pump(); // muestra el SnackBar
    await tester.pump(const Duration(milliseconds: 300)); // lo anima

    expect(find.text('PANEL DE VENTAS'), findsNothing);
    expect(find.text('No tienes acceso a "Ver ventas".'), findsOneWidget);
  });
}
