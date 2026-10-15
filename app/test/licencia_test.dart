import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/licencia/domain/licencia.dart';

void main() {
  final hoy = DateTime(2026, 10, 14);

  Map<String, dynamic> empresa({
    String estado = 'activa',
    String? fechaFin,
    int diasAviso = 5,
    String contacto = 'soporte@ventasapp.com / +57 300 000 0000',
  }) {
    return <String, dynamic>{
      'estado': estado,
      'contactoProveedor': contacto,
      'licencia': <String, dynamic>{
        'tipo': 'mensual',
        'fechaInicio': '2026-10-01',
        'fechaFin': fechaFin,
        'diasAvisoVencimiento': diasAviso,
      },
    };
  }

  group('EstadoLicencia.desdeEmpresa', () {
    test('licencia vigente con vencimiento lejano', () {
      final e = EstadoLicencia.desdeEmpresa(
        empresa(fechaFin: '2026-11-14'),
        ahora: hoy,
      );

      expect(e.vigente, isTrue);
      expect(e.diasRestantes, 31);
      expect(e.debeAvisar, isFalse);
    });

    test('licencia pronta a vencer dispara el aviso (RN-06)', () {
      final e = EstadoLicencia.desdeEmpresa(
        empresa(fechaFin: '2026-10-18'),
        ahora: hoy,
      );

      expect(e.vigente, isTrue);
      expect(e.diasRestantes, 4);
      expect(e.debeAvisar, isTrue);
    });

    test('justo en el limite de los dias de aviso', () {
      final e = EstadoLicencia.desdeEmpresa(
        empresa(fechaFin: '2026-10-19'), // 5 dias
        ahora: hoy,
      );

      expect(e.diasRestantes, 5);
      expect(e.debeAvisar, isTrue);
    });

    test('licencia vencida bloquea el ingreso (RN-05)', () {
      final e = EstadoLicencia.desdeEmpresa(
        empresa(fechaFin: '2026-10-10'),
        ahora: hoy,
      );

      expect(e.vigente, isFalse);
      expect(e.diasRestantes, -4);
      expect(e.motivoBloqueo, 'La licencia está vencida.');
    });

    test('empresa suspendida bloquea aunque la fecha no haya vencido', () {
      final e = EstadoLicencia.desdeEmpresa(
        empresa(estado: 'suspendida', fechaFin: '2026-11-14'),
        ahora: hoy,
      );

      expect(e.vigente, isFalse);
      expect(e.motivoBloqueo, 'La empresa está suspendida.');
    });

    test('sin fecha de fin queda vigente y sin aviso', () {
      final e = EstadoLicencia.desdeEmpresa(empresa(), ahora: hoy);

      expect(e.vigente, isTrue);
      expect(e.diasRestantes, isNull);
      expect(e.debeAvisar, isFalse);
    });

    test('estado desconocido se interpreta como activa', () {
      final e = EstadoLicencia.desdeEmpresa(
        empresa(estado: 'raro', fechaFin: '2026-11-14'),
        ahora: hoy,
      );

      expect(e.estado, EstadoEmpresa.activa);
      expect(e.vigente, isTrue);
    });

    test('el aviso respeta diasAvisoVencimiento configurado', () {
      final e = EstadoLicencia.desdeEmpresa(
        empresa(fechaFin: '2026-10-24', diasAviso: 15), // 10 dias, aviso 15
        ahora: hoy,
      );

      expect(e.diasRestantes, 10);
      expect(e.debeAvisar, isTrue);
    });
  });

  group('EstadoLicencia.desdeFuncion', () {
    test('traduce la respuesta de la Cloud Function', () {
      final e = EstadoLicencia.desdeFuncion(<String, dynamic>{
        'vigente': false,
        'estado': 'suspendida',
        'fechaInicio': '2026-10-01',
        'fechaFin': '2026-10-31',
        'diasRestantes': -2,
        'contactoProveedor': 'soporte@ventasapp.com',
        'diasAvisoVencimiento': 5,
      });

      expect(e.vigente, isFalse);
      expect(e.estado, EstadoEmpresa.suspendida);
      expect(e.diasRestantes, -2);
      expect(e.fechaFin, DateTime(2026, 10, 31));
      expect(e.contactoProveedor, 'soporte@ventasapp.com');
    });
  });
}
