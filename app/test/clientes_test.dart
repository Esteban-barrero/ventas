import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/clientes/data/clientes_repository.dart';
import 'package:ventas_app/features/clientes/data/ubicaciones/departamentos_ciudades.dart';
import 'package:ventas_app/features/clientes/domain/cliente.dart';
import 'package:ventas_app/features/clientes/domain/validar_cliente.dart';
import 'package:ventas_app/features/clientes/presentation/clientes_list_screen.dart';

/// Repositorio de clientes en memoria para la prueba de widget.
class _FakeClientes extends ClientesRepository {
  _FakeClientes(this.items);

  final List<Cliente> items;

  @override
  Stream<List<Cliente>> escuchar(String empresaId) => Stream.value(items);
}

Cliente _cliente({
  String id = 'c1',
  String nombre = 'María Pérez',
  String cedula = '1020304050',
  String telefono = '3001112233',
  String departamento = 'Cundinamarca',
  String ciudad = 'Bogotá',
  String direccion = 'Calle 123 #45-67',
  Clasificacion clasificacion = Clasificacion.detal,
  EstadoCliente estado = EstadoCliente.activo,
}) {
  return Cliente(
    id: id,
    empresaId: 'e',
    nombreCompleto: nombre,
    cedula: cedula,
    telefono: telefono,
    direccion: Direccion(
      departamento: departamento,
      ciudad: ciudad,
      direccion: direccion,
    ),
    clasificacion: clasificacion,
    estado: estado,
  );
}

void main() {
  group('validarCliente (RN-01..RN-03)', () {
    test('un cliente completo no tiene errores', () {
      expect(validarCliente(_cliente()), isEmpty);
    });

    test('exige nombre, cédula, teléfono y dirección', () {
      const vacio = Cliente(
        id: '',
        empresaId: 'e',
        nombreCompleto: '',
        cedula: '',
        telefono: '',
      );
      final errores = validarCliente(vacio);
      expect(errores.length, 6);
      expect(errores.any((e) => e.toLowerCase().contains('nombre')), isTrue);
      expect(errores.any((e) => e.toLowerCase().contains('cédula')), isTrue);
      expect(errores.any((e) => e.toLowerCase().contains('teléfono')), isTrue);
      expect(
          errores.any((e) => e.toLowerCase().contains('dirección')), isTrue);
    });

    test('marca la cédula duplicada en la empresa', () {
      final existentes = <Cliente>[_cliente(id: 'otro', cedula: '999')];
      final errores = validarCliente(
        _cliente(cedula: '999'),
        existentes: existentes,
      );
      expect(errores.any((e) => e.toLowerCase().contains('cédula')), isTrue);
    });

    test('no marca duplicada si es el mismo documento (edición)', () {
      final errores = validarCliente(
        _cliente(id: 'c1', cedula: '999'),
        existentes: <Cliente>[_cliente(id: 'c1', cedula: '999')],
        exceptoId: 'c1',
      );
      expect(errores, isEmpty);
    });

    test('rechaza un teléfono muy corto', () {
      final errores = validarCliente(_cliente(telefono: '123'));
      expect(errores.any((e) => e.toLowerCase().contains('teléfono')), isTrue);
    });
  });

  group('telefonoValido (RN-03)', () {
    test('acepta números con formato y longitud razonable', () {
      expect(telefonoValido('+57 300 111 2233'), isTrue);
    });
    test('rechaza cadenas sin dígitos suficientes', () {
      expect(telefonoValido('12'), isFalse);
    });
  });

  group('catálogo de ubicaciones (RN-04)', () {
    test('filtra las ciudades por departamento', () {
      expect(ciudadesDe('Antioquia'), contains('Medellín'));
      expect(ciudadesDe('Antioquia'), isNot(contains('Bogotá')));
    });
    test('devuelve vacío para un departamento desconocido', () {
      expect(ciudadesDe('Narnia'), isEmpty);
    });
  });

  group('serialización del cliente', () {
    test('guarda y recupera dirección, GPS y clasificación', () {
      final c = _cliente().copyWith(
        clasificacion: Clasificacion.mayorista,
        ubicacionGPS: const UbicacionGPS(
          latitud: 4.6486,
          longitud: -74.0628,
          direccionAproximada: 'Chapinero, Bogotá',
        ),
      );
      final vuelta = Cliente.fromMap('c1', c.toMap());
      expect(vuelta.nombreCompleto, 'María Pérez');
      expect(vuelta.clasificacion, Clasificacion.mayorista);
      expect(vuelta.direccion.ciudad, 'Bogotá');
      expect(vuelta.ubicacionGPS?.latitud, closeTo(4.6486, 0.0001));
      expect(vuelta.ubicacionGPS?.direccionAproximada, 'Chapinero, Bogotá');
    });
  });

  group('filtros de clientes', () {
    final clientes = <Cliente>[
      _cliente(id: '1', nombre: 'Ana', cedula: '111', estado: EstadoCliente.activo),
      _cliente(
        id: '2',
        nombre: 'Beto',
        cedula: '222',
        clasificacion: Clasificacion.mayorista,
        estado: EstadoCliente.moroso,
      ),
    ];

    test('busca por nombre y por cédula', () {
      expect(
        ClientesRepository.filtrar(clientes, busqueda: 'ana').map((c) => c.id),
        <String>['1'],
      );
      expect(
        ClientesRepository.filtrar(clientes, busqueda: '222').map((c) => c.id),
        <String>['2'],
      );
    });

    test('filtra por estado y clasificación', () {
      expect(
        ClientesRepository.filtrar(clientes, estado: EstadoCliente.moroso)
            .map((c) => c.id),
        <String>['2'],
      );
      expect(
        ClientesRepository.filtrar(clientes, clasificacion: Clasificacion.detal)
            .map((c) => c.id),
        <String>['1'],
      );
    });
  });

  testWidgets('el listado muestra los clientes de la empresa',
      (WidgetTester tester) async {
    const usuario = Usuario(
      uid: 'u1',
      nombre: 'Admin',
      email: 'admin@ejemplo.com',
      empresaId: 'e',
      roles: <String>['administrador'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ClientesListScreen(
          usuario: usuario,
          clientesRepository: _FakeClientes(<Cliente>[_cliente(nombre: 'María Pérez')]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('María Pérez'), findsOneWidget);
    expect(find.text('Nuevo cliente'), findsOneWidget);
  });
}
