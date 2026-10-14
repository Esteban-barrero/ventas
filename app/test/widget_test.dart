import 'package:flutter/material.dart';
import 'package:ventas_app/features/home/home_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomePage muestra modulo Catalogo y Firebase conectado',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(email: 'test@ejemplo.com', onCerrarSesion: _dummy),
      ),
    );

    // Estado de la conexion con Firebase.
    expect(find.text('Firebase conectado'), findsOneWidget);

    // Algunos modulos esperados.
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Ventas'), findsOneWidget);
    expect(find.text('Inventario'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);
  });
}

Future<void> _dummy() async {}
