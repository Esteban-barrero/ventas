import 'package:flutter_test/flutter_test.dart';

import 'package:ventas_app/main.dart';

void main() {
  testWidgets('La pantalla de inicio muestra el titulo y los modulos',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VentasApp());

    // Titulo en la AppBar y en el encabezado.
    expect(find.text('Aplicativo de Ventas'), findsWidgets);

    // Algunos modulos esperados.
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('Ventas'), findsOneWidget);
    expect(find.text('Inventario'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);
  });
}
