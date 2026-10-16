import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/creditos/data/creditos_repository.dart';
import 'package:ventas_app/features/creditos/domain/credito.dart';
import 'package:ventas_app/features/creditos/presentation/creditos_list_screen.dart';

/// Repositorio de créditos en memoria para la prueba de widget.
class _FakeCreditos extends CreditosRepository {
  _FakeCreditos(this.items);

  final List<Credito> items;

  @override
  Stream<List<Credito>> escuchar(String empresaId) => Stream.value(items);
}

void main() {
  group('generarCuotas (RF-03, RN-02/RN-03)', () {
    test('genera las cuotas con interés y las fechas según periodicidad', () {
      final cuotas = generarCuotas(
        monto: 300000,
        numeroCuotas: 3,
        periodicidad: Periodicidad.mensual,
        fechaPrimerPago: DateTime(2026, 11, 14),
        tasaInteres: 10,
      );
      expect(cuotas.length, 3);
      expect(cuotas[0].monto, closeTo(110000, 0.01));
      expect(
        cuotas.fold<double>(0, (double a, Cuota c) => a + c.monto),
        closeTo(330000, 0.01),
      );
      expect(cuotas[0].fechaVencimiento, DateTime(2026, 11, 14));
      expect(cuotas[1].fechaVencimiento, DateTime(2026, 12, 14));
      expect(cuotas[2].fechaVencimiento, DateTime(2027, 1, 14));
    });

    test('la última cuota ajusta el redondeo (la suma cuadra)', () {
      final cuotas = generarCuotas(
        monto: 100,
        numeroCuotas: 3,
        periodicidad: Periodicidad.semanal,
        fechaPrimerPago: DateTime(2026, 1, 1),
      );
      expect(
        cuotas.fold<double>(0, (double a, Cuota c) => a + c.monto),
        closeTo(100, 0.0001),
      );
      expect(cuotas[1].fechaVencimiento, DateTime(2026, 1, 8));
    });

    test('sin cuotas devuelve lista vacía', () {
      expect(
        generarCuotas(
          monto: 100,
          numeroCuotas: 0,
          periodicidad: Periodicidad.mensual,
          fechaPrimerPago: DateTime(2026, 1, 1),
        ),
        isEmpty,
      );
    });
  });

  group('calcularMoraDeCuotas (RF-07, RN-05)', () {
    final hoy = DateTime(2026, 6, 15);

    test('toma la mayor diferencia de las cuotas vencidas sin pagar', () {
      final cuotas = <Cuota>[
        Cuota(
          numero: 1,
          fechaVencimiento: DateTime(2026, 6, 5),
          monto: 100,
        ),
        Cuota(
          numero: 2,
          fechaVencimiento: DateTime(2026, 6, 20),
          monto: 100,
        ),
      ];
      expect(calcularMoraDeCuotas(cuotas, ahora: hoy), 10);
    });

    test('las cuotas pagadas no cuentan', () {
      final cuotas = <Cuota>[
        Cuota(
          numero: 1,
          fechaVencimiento: DateTime(2026, 6, 5),
          monto: 100,
          pagado: 100,
          estado: EstadoCuota.pagada,
        ),
      ];
      expect(calcularMoraDeCuotas(cuotas, ahora: hoy), 0);
    });
  });

  group('serialización del crédito', () {
    test('guarda y recupera cuotas y crédito', () {
      final credito = Credito(
        id: 'c1',
        empresaId: 'e',
        clienteId: 'cli1',
        clienteNombre: 'María',
        ventaId: 'v1',
        montoTotal: 300000,
        tasaInteres: 10,
        montoConInteres: 330000,
        numeroCuotas: 3,
        periodicidad: Periodicidad.mensual,
        saldoActual: 330000,
      );
      final vuelta = Credito.fromMap('c1', credito.toMap());
      expect(vuelta.clienteNombre, 'María');
      expect(vuelta.montoConInteres, 330000);
      expect(vuelta.periodicidad, Periodicidad.mensual);
      expect(vuelta.estado, EstadoCredito.activo);

      final cuota = Cuota(
        numero: 1,
        fechaVencimiento: DateTime(2026, 1, 1),
        monto: 110000,
      );
      final cuotaVuelta = Cuota.fromMap(cuota.toMap());
      expect(cuotaVuelta.numero, 1);
      expect(cuotaVuelta.saldo, 110000);
    });
  });

  group('filtros de créditos', () {
    final creditos = <Credito>[
      Credito(
        id: '1',
        empresaId: 'e',
        clienteId: 'c1',
        clienteNombre: 'Ana',
      ),
      Credito(
        id: '2',
        empresaId: 'e',
        clienteId: 'c2',
        clienteNombre: 'Beto',
        estado: EstadoCredito.pagado,
      ),
    ];

    test('busca por cliente y filtra por estado', () {
      expect(
        CreditosRepository.filtrar(creditos, busqueda: 'ana').map((c) => c.id),
        <String>['1'],
      );
      expect(
        CreditosRepository.filtrar(creditos, estado: EstadoCredito.pagado)
            .map((c) => c.id),
        <String>['2'],
      );
    });
  });

  testWidgets('el listado muestra los créditos de la empresa',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u1',
      nombre: 'Admin',
      email: 'a@ejemplo.com',
      empresaId: 'e',
      roles: <String>['administrador'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CreditosListScreen(
          usuario: usuario,
          creditosRepository: _FakeCreditos(<Credito>[
            Credito(
              id: '1',
              empresaId: 'e',
              clienteId: 'c1',
              clienteNombre: 'María Pérez',
              numeroCuotas: 3,
              saldoActual: 300000,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('María Pérez'), findsOneWidget);
  });
}
