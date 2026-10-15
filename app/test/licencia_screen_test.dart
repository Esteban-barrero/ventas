import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/licencia/domain/licencia.dart';
import 'package:ventas_app/features/licencia/presentation/aviso_licencia.dart';
import 'package:ventas_app/features/licencia/presentation/licencia_bloqueada_screen.dart';

Future<void> _dummy() async {}

Future<void> _montar(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: child));
}

void main() {
  const String mensajeAmable =
      'Comunícate con tu proveedor para renovarla y recuperar el acceso.';

  testWidgets('LicenciaBloqueadaScreen muestra mensaje amable, días y contacto',
      (WidgetTester tester) async {
    const estado = EstadoLicencia(
      vigente: false,
      estado: EstadoEmpresa.activa,
      diasRestantes: -4,
      contactoProveedor: 'soporte@ventasapp.com / +57 300 000 0000',
      fechaFin: null,
    );

    await _montar(
      tester,
      LicenciaBloqueadaScreen(estado: estado, onCerrarSesion: _dummy),
    );

    expect(find.text('Tu licencia se ha agotado'), findsOneWidget);
    expect(find.text(mensajeAmable), findsOneWidget);
    expect(find.text('soporte@ventasapp.com / +57 300 000 0000'), findsOneWidget);
    expect(find.text('Vencida hace'), findsOneWidget);
    expect(find.text('4 día(s)'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('LicenciaBloqueadaScreen no menciona "suspendida" al usuario',
      (WidgetTester tester) async {
    const estado = EstadoLicencia(
      vigente: false,
      estado: EstadoEmpresa.suspendida,
      diasRestantes: 20,
      contactoProveedor: '',
    );

    await _montar(
      tester,
      LicenciaBloqueadaScreen(estado: estado, onCerrarSesion: _dummy),
    );

    expect(find.text('Tu licencia se ha agotado'), findsOneWidget);
    expect(find.text(mensajeAmable), findsOneWidget);
    expect(find.textContaining('suspendida'), findsNothing);
    expect(find.text('No hay un contacto configurado.'), findsOneWidget);
  });

  testWidgets('LicenciaNoDisponibleScreen muestra el detalle',
      (WidgetTester tester) async {
    await _montar(
      tester,
      LicenciaNoDisponibleScreen(
        detalle: 'No se pudo verificar la licencia.',
        onCerrarSesion: _dummy,
      ),
    );

    expect(find.text('No pudimos verificar tu licencia'), findsOneWidget);
    expect(
      find.text('No se pudo verificar la licencia.'),
      findsOneWidget,
    );
  });

  testWidgets('AvisoLicencia indica los días restantes', (tester) async {
    await _montar(
      tester,
      const Scaffold(
        body: AvisoLicencia(
          estado: EstadoLicencia(
            vigente: true,
            estado: EstadoEmpresa.activa,
            diasRestantes: 3,
          ),
        ),
      ),
    );

    expect(find.text('Tu licencia vence en 3 días.'), findsOneWidget);
  });

  testWidgets('AvisoLicencia dice "mañana" cuando falta 1 día', (tester) async {
    await _montar(
      tester,
      const Scaffold(
        body: AvisoLicencia(
          estado: EstadoLicencia(
            vigente: true,
            estado: EstadoEmpresa.activa,
            diasRestantes: 1,
          ),
        ),
      ),
    );

    expect(find.text('Tu licencia vence mañana.'), findsOneWidget);
  });

  testWidgets('AvisoLicencia se oculta solo tras la duración configurada',
      (tester) async {
    await _montar(
      tester,
      const Scaffold(
        body: AvisoLicencia(
          estado: EstadoLicencia(
            vigente: true,
            estado: EstadoEmpresa.activa,
            diasRestantes: 3,
          ),
          duracion: Duration(milliseconds: 100),
        ),
      ),
    );

    expect(find.text('Tu licencia vence en 3 días.'), findsOneWidget);

    // Pasa la duración + el desvanecido + la animación de reacomodo.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Tu licencia vence en 3 días.'), findsNothing);
  });

  testWidgets('AvisoLicencia se oculta al tocar la X', (tester) async {
    await _montar(
      tester,
      const Scaffold(
        body: AvisoLicencia(
          estado: EstadoLicencia(
            vigente: true,
            estado: EstadoEmpresa.activa,
            diasRestantes: 3,
          ),
        ),
      ),
    );

    expect(find.text('Tu licencia vence en 3 días.'), findsOneWidget);

    await tester.tap(find.byTooltip('Ocultar aviso'));
    await tester.pumpAndSettle();

    expect(find.text('Tu licencia vence en 3 días.'), findsNothing);
  });
}
