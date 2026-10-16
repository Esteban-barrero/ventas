import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ventas_app/features/auth/presentation/login_screen.dart';

void main() {
  setUp(() {
    // Preferencias en memoria para el "recordar datos" (spec 001).
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  // Se construye sin repositorio: AuthRepository resuelve Firebase de forma
  // perezosa, por lo que no hace falta inicializar Firebase para estas pruebas.
  Future<void> montar(WidgetTester tester) async {
    // Pantalla alta para que todo el formulario quede visible en la prueba.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
  }

  testWidgets('muestra correo, contraseña, Google y recuperar contraseña',
      (WidgetTester tester) async {
    await montar(tester);

    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    expect(find.text('¿No tienes cuenta? Regístrate'), findsOneWidget);
    expect(find.text('Recordar mis datos'), findsOneWidget);
  });

  testWidgets('al cambiar a registro oculta recuperar contraseña',
      (WidgetTester tester) async {
    await montar(tester);

    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsNothing);
    // El botón de Google sigue disponible.
    expect(find.text('Continuar con Google'), findsOneWidget);
  });

  testWidgets('el dialogo de recuperación valida el correo vacío',
      (WidgetTester tester) async {
    await montar(tester);

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsOneWidget);

    // Intentar enviar sin correo -> error de validación (no llama a Firebase).
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu correo'), findsWidgets);

    // Se puede cancelar.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Recuperar contraseña'), findsNothing);
  });

  testWidgets('el dialogo de recuperación rechaza un correo no válido',
      (WidgetTester tester) async {
    await montar(tester);

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    final campoDialogo = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(campoDialogo, 'correo-invalido');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo no válido'), findsWidgets);
  });
}
