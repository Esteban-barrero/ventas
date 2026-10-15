import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/empresas/presentation/empresa_form_screen.dart';
import 'package:ventas_app/features/empresas/presentation/empresas_list_screen.dart';

/// Monta el widget en una pantalla muy alta para que el `ListView` construya
/// todos sus hijos y `find.text` los encuentre.
Future<void> _montar(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1000, 9000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pump();
}

void main() {
  testWidgets('el formulario muestra los campos principales', (tester) async {
    await _montar(tester, const EmpresaFormScreen());

    expect(find.text('Nueva empresa'), findsOneWidget);
    expect(find.text('Nombre / razón social *'), findsOneWidget);
    expect(find.text('NIT / RIF *'), findsOneWidget);
    expect(find.text('Correo del administrador *'), findsOneWidget);
    expect(find.text('Crear empresa'), findsOneWidget);
  });

  testWidgets('valida los campos obligatorios antes de crear', (tester) async {
    await _montar(tester, const EmpresaFormScreen());

    await tester.tap(find.text('Crear empresa'));
    await tester.pump();

    // Los tres campos obligatorios (nombre, NIT y correo del administrador)
    // muestran su mensaje de validación.
    expect(find.text('Campo obligatorio.'), findsNWidgets(3));
  });

  testWidgets('el listado de empresas muestra su título', (tester) async {
    await _montar(tester, const EmpresasListScreen());

    expect(find.text('Empresas'), findsOneWidget);
    expect(find.text('Nueva empresa'), findsOneWidget);
  });
}
