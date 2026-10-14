import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/home/home_page.dart';

void main() {
  testWidgets('HomePage muestra roles y modulos segun permisos',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u1',
      nombre: 'Esteban Barrero',
      email: 'esteban@ejemplo.com',
      roles: <String>['administrador'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(usuario: usuario, onCerrarSesion: _dummy),
      ),
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

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(usuario: usuario, onCerrarSesion: _dummy),
      ),
    );

    expect(find.text('Logs de errores'), findsOneWidget);
    expect(find.text('Ventas'), findsNothing);
  });
}

Future<void> _dummy() async {}
