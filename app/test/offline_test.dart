import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/core/firebase/errores.dart';
import 'package:ventas_app/features/licencia/domain/licencia.dart';

void main() {
  group('esErrorDeRed', () {
    test('reconoce los errores de conectividad', () {
      expect(
        esErrorDeRed(FirebaseException(plugin: 'test', code: 'unavailable')),
        isTrue,
      );
      expect(
        esErrorDeRed(FirebaseException(plugin: 'test', code: 'deadline-exceeded')),
        isTrue,
      );
      expect(
        esErrorDeRed(FirebaseException(plugin: 'test', code: 'network-request-failed')),
        isTrue,
      );
    });

    test('NO trata los errores de permisos como errores de red', () {
      // Importante: un permiso denegado nunca debe caer en la cache local.
      expect(esErrorDeRed(FirebaseException(plugin: 'test', code: 'permission-denied')), isFalse);
      expect(esErrorDeRed(FirebaseException(plugin: 'test', code: 'unauthenticated')), isFalse);
      expect(esErrorDeRed(FirebaseException(plugin: 'test', code: 'not-found')), isFalse);
      expect(esErrorDeRed(FirebaseException(plugin: 'test', code: 'invalid-argument')), isFalse);
    });
  });

  group('ResultadoLicencia.desdeCache', () {
    const estado = EstadoLicencia(
      vigente: true,
      estado: EstadoEmpresa.activa,
      diasRestantes: 10,
    );

    test('por defecto los resultados NO vienen de la cache', () {
      expect(const LicenciaVigente(estado).desdeCache, isFalse);
      expect(const LicenciaBloqueada(estado).desdeCache, isFalse);
      expect(const LicenciaNoDisponible('x').desdeCache, isFalse);
    });

    test('se puede marcar que vienen de la cache', () {
      const vigente = LicenciaVigente(estado, desdeCache: true);
      const bloqueada = LicenciaBloqueada(estado, desdeCache: true);
      const noDisponible = LicenciaNoDisponible('x', desdeCache: true);

      expect(vigente.desdeCache, isTrue);
      expect(vigente.estado, estado);
      expect(bloqueada.desdeCache, isTrue);
      expect(bloqueada.estado, estado);
      expect(noDisponible.desdeCache, isTrue);
    });

    test('sigue siendo un resultado sellado (switch exhaustivo)', () {
      const ResultadoLicencia resultado = LicenciaBloqueada(estado);

      final descripcion = switch (resultado) {
        LicenciaVigente() => 'vigente',
        LicenciaBloqueada() => 'bloqueada',
        LicenciaNoDisponible() => 'no disponible',
      };

      expect(descripcion, 'bloqueada');
    });
  });
}
