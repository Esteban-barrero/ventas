import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/empresas/data/almacenamiento_repository.dart';
import 'package:ventas_app/features/empresas/domain/empresa.dart';
import 'package:ventas_app/features/empresas/domain/licencia.dart';
import 'package:ventas_app/features/empresas/domain/parametros_empresa.dart';
import 'package:ventas_app/features/empresas/domain/plan.dart';
import 'package:ventas_app/features/empresas/domain/resumen_empresas.dart';
import 'package:ventas_app/features/licencia/domain/licencia.dart'
    show EstadoEmpresa;

void main() {
  final hoy = DateTime(2026, 10, 14);

  group('Licencia.calcularEstado', () {
    test('activa con vencimiento lejano', () {
      final licencia = Licencia(
        tipo: TipoLicencia.mensual,
        fechaInicio: DateTime(2026, 10, 1),
        fechaFin: DateTime(2026, 11, 14),
      );
      expect(licencia.calcularEstado(hoy), EstadoLicenciaNegocio.activa);
      expect(licencia.porVencer(hoy), isFalse);
      expect(licencia.vencida(hoy), isFalse);
    });

    test('por vencer dentro de los dias de aviso', () {
      final licencia = Licencia(
        fechaFin: DateTime(2026, 10, 18),
        diasAvisoVencimiento: 5,
      );
      expect(licencia.calcularEstado(hoy), EstadoLicenciaNegocio.porVencer);
      expect(licencia.porVencer(hoy), isTrue);
    });

    test('el limite exacto del aviso (dias == aviso) es por vencer', () {
      final licencia = Licencia(
        fechaFin: DateTime(2026, 10, 19),
        diasAvisoVencimiento: 5,
      );
      expect(licencia.diasRestantes(hoy), 5);
      expect(licencia.calcularEstado(hoy), EstadoLicenciaNegocio.porVencer);
    });

    test('vencida', () {
      final licencia = Licencia(fechaFin: DateTime(2026, 10, 10));
      expect(licencia.diasRestantes(hoy), -4);
      expect(licencia.calcularEstado(hoy), EstadoLicenciaNegocio.vencida);
      expect(licencia.vencida(hoy), isTrue);
    });

    test('suspendida tiene prioridad sobre las fechas', () {
      final licencia = Licencia(fechaFin: DateTime(2030, 1, 1));
      expect(
        licencia.calcularEstado(hoy, estadoEmpresa: EstadoEmpresa.suspendida),
        EstadoLicenciaNegocio.suspendida,
      );
    });

    test('en prueba', () {
      expect(
        const Licencia().calcularEstado(
          hoy,
          estadoEmpresa: EstadoEmpresa.prueba,
        ),
        EstadoLicenciaNegocio.prueba,
      );
    });

    test('sin fecha de fin nunca vence', () {
      expect(const Licencia().calcularEstado(hoy), EstadoLicenciaNegocio.activa);
      expect(const Licencia().diasRestantes(hoy), isNull);
    });

    test('fechasCoherentes detecta un rango invertido', () {
      final mala = Licencia(
        fechaInicio: DateTime(2026, 10, 20),
        fechaFin: DateTime(2026, 10, 1),
      );
      expect(mala.fechasCoherentes, isFalse);
    });

    test('toMap guarda el estado derivado como id', () {
      final mapa = Licencia(fechaFin: DateTime(2026, 10, 18)).toMap(ahora: hoy);
      expect(mapa['estado'], 'por_vencer');
      expect(mapa['tipo'], 'mensual');
    });
  });

  group('Empresa', () {
    Map<String, dynamic> mapa() => <String, dynamic>{
          'id': 'demo',
          'nombre': 'Demo S.A.S.',
          'nit': '900123456',
          'correoNotificacion': 'avisos@demo.com',
          'estado': 'activa',
          'fechaCreacion': '2026-10-14T00:00:00.000Z',
          'plan': 'basico',
          'adminId': 'admin1',
          'licencia': <String, dynamic>{
            'tipo': 'mensual',
            'fechaInicio': '2026-10-01',
            'fechaFin': '2026-11-14',
            'diasAvisoVencimiento': 5,
            'valorPagado': 99000,
          },
          'parametros': <String, dynamic>{
            'margenDetal': 35,
            'tema': <String, dynamic>{'colorPrimario': '#111111'},
          },
          'limites': <String, dynamic>{'maxUsuarios': 10, 'maxProductos': 1000},
        };

    test('fromMap lee todos los campos', () {
      final empresa = Empresa.fromMap('demo', mapa());

      expect(empresa.nombre, 'Demo S.A.S.');
      expect(empresa.nit, '900123456');
      expect(empresa.planId, 'basico');
      expect(empresa.adminId, 'admin1');
      expect(empresa.estado, EstadoEmpresa.activa);
      expect(empresa.licencia.tipo, TipoLicencia.mensual);
      expect(empresa.licencia.valorPagado, 99000);
      expect(empresa.parametros.margenDetal, 35);
      expect(empresa.parametros.colorPrimario, '#111111');
      expect(empresa.limites.maxUsuarios, 10);
      expect(empresa.fechaCreacion, isNotNull);
    });

    test('fromMap tolera campos ausentes', () {
      final empresa = Empresa.fromMap('x', <String, dynamic>{});

      expect(empresa.nombre, '');
      expect(empresa.estado, EstadoEmpresa.activa);
      expect(empresa.licencia.tipo, TipoLicencia.mensual);
      expect(empresa.planId, 'gratis');
      expect(empresa.limites.maxUsuarios, -1);
      expect(empresa.tieneLogo, isFalse);
    });

    test('toMap calcula el estado de la licencia', () {
      final salida = Empresa.fromMap('demo', mapa()).toMap(ahora: hoy);
      final licencia = salida['licencia'] as Map<String, dynamic>;

      expect(licencia['estado'], 'activa');
      expect((salida['limites'] as Map)['maxUsuarios'], 10);
      expect(salida['plan'], 'basico');
    });

    test('roundtrip toMap/fromMap conserva los datos', () {
      final original = Empresa.fromMap('demo', mapa());
      final copia = Empresa.fromMap('demo', original.toMap(ahora: hoy));

      expect(copia.nombre, original.nombre);
      expect(copia.licencia.fechaFin, original.licencia.fechaFin);
      expect(copia.parametros.margenDetal, original.parametros.margenDetal);
      expect(copia.limites.maxProductos, original.limites.maxProductos);
    });

    test('estadoLicencia refleja el estado de la empresa', () {
      final empresa = Empresa.fromMap('demo', mapa())
          .copyWith(estado: EstadoEmpresa.suspendida);
      expect(empresa.estadoLicencia(hoy), EstadoLicenciaNegocio.suspendida);
    });

    test('una empresa eliminada deja de estar vigente y bloquea', () {
      final empresa =
          Empresa.fromMap('demo', mapa()).copyWith(estado: EstadoEmpresa.eliminada);
      expect(empresa.vigente, isFalse);
      expect(EstadoEmpresa.eliminada.bloqueaElIngreso, isTrue);
    });
  });

  group('DatosEmpresa.validar', () {
    test('exige nombre, NIT y correo del administrador', () {
      expect(const DatosEmpresa(nombre: '').validar(), isNotNull);
      expect(
        const DatosEmpresa(nombre: 'X', nit: '', adminEmail: 'a@b.com').validar(),
        contains('NIT'),
      );
      expect(
        const DatosEmpresa(nombre: 'X', nit: '1').validar(),
        contains('correo'),
      );
    });

    test('valida el formato del correo', () {
      expect(
        const DatosEmpresa(nombre: 'X', nit: '1', adminEmail: 'noesmail')
            .validar(),
        contains('válido'),
      );
    });

    test('detecta un correo de notificacion invalido', () {
      expect(
        const DatosEmpresa(
          nombre: 'X',
          nit: '1',
          adminEmail: 'a@b.com',
          correoNotificacion: 'malo',
        ).validar(),
        contains('notificación'),
      );
    });

    test('acepta datos correctos', () {
      expect(
        const DatosEmpresa(nombre: 'X', nit: '1', adminEmail: 'a@b.com')
            .validar(),
        isNull,
      );
    });

    test('aSolicitud arma el cuerpo de la Cloud Function', () {
      final solicitud = const DatosEmpresa(
        nombre: 'Demo',
        nit: '1',
        adminEmail: 'a@b.com',
      ).aSolicitud(licencia: const Licencia(), planId: 'basico');

      expect(solicitud['nombre'], 'Demo');
      expect(solicitud['plan'], 'basico');
      expect((solicitud['admin'] as Map)['email'], 'a@b.com');
      expect(solicitud['licencia'], isA<Map<String, dynamic>>());
    });
  });

  group('ResumenEmpresas', () {
    Empresa con(String id, String estado, String? fin) => Empresa(
          id: id,
          nombre: id,
          estado: EstadoEmpresa.desdeId(estado),
          licencia: Licencia(
            fechaFin: fin == null ? null : DateTime.parse(fin),
          ),
        );

    test('clasifica por estado de licencia', () {
      final resumen = ResumenEmpresas.calcular(<Empresa>[
        con('activa', 'activa', '2026-12-31'),
        con('porVencer', 'activa', '2026-10-18'),
        con('vencida', 'activa', '2026-10-01'),
        con('suspendida', 'suspendida', '2026-12-31'),
        con('prueba', 'prueba', '2026-12-31'),
        con('eliminada', 'eliminada', '2026-12-31'),
      ], hoy);

      expect(resumen.activas.map((e) => e.id), <String>['activa']);
      expect(resumen.porVencer.map((e) => e.id), <String>['porVencer']);
      expect(resumen.vencidas.map((e) => e.id), <String>['vencida']);
      expect(resumen.suspendidas.map((e) => e.id), <String>['suspendida']);
      expect(resumen.enPrueba.map((e) => e.id), <String>['prueba']);
      expect(resumen.eliminadas.map((e) => e.id), <String>['eliminada']);
      expect(resumen.totalOperativas, 3);
      expect(resumen.totalPorAtender, 2);
      expect(resumen.totalVigentes, 5);
    });

    test('ordena las por vencer por urgencia', () {
      final resumen = ResumenEmpresas.calcular(<Empresa>[
        con('lejos', 'activa', '2026-10-19'),
        con('cerca', 'activa', '2026-10-15'),
      ], hoy);

      expect(resumen.porVencer.first.id, 'cerca');
    });
  });

  group('Plan', () {
    test('los planes por defecto tienen limites', () {
      expect(Plan.porDefecto.length, 3);
      expect(Plan.porDefectoConId('basico')!.limites.maxUsuarios, 10);
      expect(Plan.porDefectoConId('premium')!.limites.maxProductos, 10000);
      expect(Plan.porDefectoConId('noexiste'), isNull);
    });

    test('roundtrip de Plan', () {
      final original = Plan.porDefecto.first;
      final copia = Plan.fromMap(original.toMap());

      expect(copia.id, original.id);
      expect(copia.valor, original.valor);
      expect(copia.limites.maxUsuarios, original.limites.maxUsuarios);
    });

    test('LimitesPlan.dentroDelLimite respeta -1 = ilimitado', () {
      expect(LimitesPlan.dentroDelLimite(9999, -1), isTrue);
      expect(LimitesPlan.dentroDelLimite(11, 10), isFalse);
      expect(LimitesPlan.dentroDelLimite(10, 10), isTrue);
    });
  });

  group('ParametrosEmpresa', () {
    test('porDefecto trae la paleta de la empresa', () {
      expect(ParametrosEmpresa.porDefecto.colorPrimario, '#1A73E8');
      expect(ParametrosEmpresa.porDefecto.colorSecundario, '#FF6B35');
    });

    test('roundtrip conserva los valores', () {
      final original = ParametrosEmpresa.porDefecto
          .copyWith(margenDetal: 42, costoEnvio: 8000);
      final copia = ParametrosEmpresa.fromMap(original.toMap());

      expect(copia.margenDetal, 42);
      expect(copia.costoEnvio, 8000);
      expect(copia.colorSecundario, '#FF6B35');
    });

    test('fromMap(null) devuelve los valores por defecto', () {
      expect(ParametrosEmpresa.fromMap(null).moneda, 'COP');
    });
  });

  group('AlmacenamientoRepository.validarLogo', () {
    test('acepta un PNG pequeno', () {
      expect(
        () => AlmacenamientoRepository.validarLogo(
          Uint8List(1024),
          extension: 'png',
        ),
        returnsNormally,
      );
    });

    test('rechaza un archivo mayor a 500 KB', () {
      expect(
        () => AlmacenamientoRepository.validarLogo(
          Uint8List(501 * 1024),
          extension: 'png',
        ),
        throwsA(isA<ArchivoInvalidoException>()),
      );
    });

    test('rechaza un formato no permitido', () {
      expect(
        () => AlmacenamientoRepository.validarLogo(
          Uint8List(1024),
          extension: 'gif',
        ),
        throwsA(isA<ArchivoInvalidoException>()),
      );
    });

    test('acepta jpg y webp', () {
      expect(
        () => AlmacenamientoRepository.validarLogo(
          Uint8List(1024),
          extension: 'jpg',
        ),
        returnsNormally,
      );
      expect(
        () => AlmacenamientoRepository.validarLogo(
          Uint8List(1024),
          extension: 'webp',
        ),
        returnsNormally,
      );
    });
  });
}
