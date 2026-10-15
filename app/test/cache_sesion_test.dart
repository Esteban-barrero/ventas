import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ventas_app/features/auth/data/cache_sesion.dart';
import 'package:ventas_app/features/auth/domain/usuario.dart';
import 'package:ventas_app/features/licencia/domain/licencia.dart';

Usuario _usuario({
  String uid = 'u1',
  List<String> roles = const <String>['vendedor'],
  String? empresaId = 'demo',
}) {
  return Usuario(
    uid: uid,
    nombre: 'Ana Pérez',
    email: 'ana@ejemplo.com',
    telefono: '3001234567',
    empresaId: empresaId,
    roles: roles,
    activo: true,
    fechaCreacion: DateTime.utc(2026, 1, 15, 10, 30),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('CacheSesion - perfil', () {
    test('guarda y recupera el perfil, incluidos roles y empresa', () async {
      final cache = CacheSesion();
      await cache.guardarPerfil(_usuario());

      final leido = await cache.leerPerfil('u1');

      expect(leido, isNotNull);
      expect(leido!.uid, 'u1');
      expect(leido.nombre, 'Ana Pérez');
      expect(leido.telefono, '3001234567');
      expect(leido.empresaId, 'demo');
      expect(leido.roles, <String>['vendedor']);
      expect(leido.activo, isTrue);
      expect(leido.fechaCreacion, DateTime.utc(2026, 1, 15, 10, 30));
    });

    test('no devuelve el perfil si es de otro usuario', () async {
      final cache = CacheSesion();
      await cache.guardarPerfil(_usuario(uid: 'u1'));

      expect(await cache.leerPerfil('otro'), isNull);
    });

    test('devuelve null si no hay nada guardado', () async {
      expect(await CacheSesion().leerPerfil('u1'), isNull);
    });

    test('ignora un perfil corrupto en lugar de fallar', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'cache.perfil': 'esto no es json',
      });

      expect(await CacheSesion().leerPerfil('u1'), isNull);
    });

    test('los permisos se conservan a traves de la cache', () async {
      final cache = CacheSesion();
      await cache.guardarPerfil(_usuario(roles: <String>['administrador']));

      final leido = (await cache.leerPerfil('u1'))!;

      expect(leido.permisos.length, greaterThan(0));
    });
  });

  group('CacheSesion - empresa', () {
    test('guarda y recupera el documento de empresa', () async {
      final cache = CacheSesion();
      await cache.guardarEmpresa('demo', <String, dynamic>{
        'nombre': 'Demo S.A.S.',
        'estado': 'activa',
        'licencia': <String, dynamic>{
          'tipo': 'mensual',
          'fechaFin': '2026-12-31',
        },
      });

      final leido = await cache.leerEmpresa('demo');

      expect(leido, isNotNull);
      expect(leido!['nombre'], 'Demo S.A.S.');
      expect((leido['licencia'] as Map)['fechaFin'], '2026-12-31');
    });

    test('no mezcla empresas distintas', () async {
      final cache = CacheSesion();
      await cache.guardarEmpresa('demo', <String, dynamic>{'nombre': 'Demo'});
      await cache.guardarEmpresa('otra', <String, dynamic>{'nombre': 'Otra'});

      expect((await cache.leerEmpresa('demo'))!['nombre'], 'Demo');
      expect((await cache.leerEmpresa('otra'))!['nombre'], 'Otra');
      expect(await cache.leerEmpresa('tercera'), isNull);
    });

    test('convierte marcas de tiempo a texto (no falla al guardar)', () async {
      final cache = CacheSesion();
      // Simula un valor tipo Timestamp de Firestore: objeto con toDate().
      final simulado = <String, dynamic>{
        'licencia': <String, dynamic>{
          'fechaFin': _FechaFalsa(DateTime.utc(2026, 12, 31)),
        },
      };

      await cache.guardarEmpresa('demo', simulado);
      final leido = await cache.leerEmpresa('demo');

      final fecha = (leido!['licencia'] as Map)['fechaFin'];
      expect(fecha, isA<String>());
      expect(DateTime.parse(fecha as String), DateTime.utc(2026, 12, 31));
    });

    test('la licencia cacheada se reevalua con la fecha actual', () async {
      final cache = CacheSesion();
      // Se guarda una empresa con licencia vencida hace tiempo.
      await cache.guardarEmpresa('demo', <String, dynamic>{
        'estado': 'activa',
        'licencia': <String, dynamic>{'fechaFin': '2020-01-01'},
      });

      final guardado = await cache.leerEmpresa('demo');
      final estado = EstadoLicencia.desdeEmpresa(guardado!);

      // Aunque la copia se haya guardado antes, hoy ya no esta vigente.
      expect(estado.vigente, isFalse);
      expect(estado.diasRestantes, lessThan(0));
    });
  });

  group('CacheSesion - limpiar', () {
    test('borra el perfil y todas las empresas guardadas', () async {
      final cache = CacheSesion();
      await cache.guardarPerfil(_usuario());
      await cache.guardarEmpresa('demo', <String, dynamic>{'nombre': 'Demo'});

      await cache.limpiar();

      expect(await cache.leerPerfil('u1'), isNull);
      expect(await cache.leerEmpresa('demo'), isNull);
    });

    test('no borra claves ajenas a la cache', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'ajena': 'se conserva',
      });
      final cache = CacheSesion();
      await cache.guardarPerfil(_usuario());

      await cache.limpiar();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ajena'), 'se conserva');
    });
  });

  test('el JSON guardado se puede volver a leer en una instancia nueva',
      () async {
    await CacheSesion().guardarPerfil(_usuario(roles: <String>['cajero']));

    final otra = CacheSesion();
    final leido = await otra.leerPerfil('u1');

    expect(leido!.roles, <String>['cajero']);
  });

  test('lo guardado es JSON valido y legible', () async {
    await CacheSesion().guardarPerfil(_usuario());

    final prefs = await SharedPreferences.getInstance();
    final crudo = prefs.getString('cache.perfil')!;
    final decodificado = jsonDecode(crudo) as Map<String, dynamic>;

    expect(decodificado['uid'], 'u1');
    expect(decodificado['roles'], <String>['vendedor']);
  });
}

/// Objeto con `toDate()`, igual que un Timestamp de Firestore.
class _FechaFalsa {
  _FechaFalsa(this._fecha);

  final DateTime _fecha;

  DateTime toDate() => _fecha;
}
