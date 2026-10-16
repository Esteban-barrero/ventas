import 'package:flutter_test/flutter_test.dart';
import 'package:ventas_app/features/auth/domain/permisos.dart';
import 'package:ventas_app/features/auth/domain/roles.dart';
import 'package:ventas_app/features/empresas/domain/parametros_empresa.dart';
import 'package:ventas_app/features/ventas/domain/venta.dart';

void main() {
  group('EstadoEnvio (spec 011, RF-04)', () {
    test('desdeId con valor desconocido vuelve a pendiente', () {
      expect(EstadoEnvio.desdeId('en_reparto'), EstadoEnvio.enReparto);
      expect(EstadoEnvio.desdeId('entregado'), EstadoEnvio.entregado);
      expect(EstadoEnvio.desdeId('x'), EstadoEnvio.pendiente);
      expect(EstadoEnvio.desdeId(null), EstadoEnvio.pendiente);
    });
  });

  group('Venta.entregaPendiente (spec 011, RN-01)', () {
    Venta venta({TipoEntrega entrega = TipoEntrega.envio, String estadoEnvio = ''}) =>
        Venta(
          id: 'v1',
          empresaId: 'e1',
          numeroFactura: 'FV-000001',
          tipoEntrega: entrega,
          estadoEnvio: estadoEnvio,
        );

    test('presencial y recoger en local no requieren entrega', () {
      expect(venta(entrega: TipoEntrega.presencial).requiereEntrega, isFalse);
      expect(venta(entrega: TipoEntrega.recogerLocal).requiereEntrega, isFalse);
      expect(venta(entrega: TipoEntrega.presencial).entregaPendiente, isFalse);
    });

    test('envío y entrega local sí requieren entrega', () {
      expect(venta(entrega: TipoEntrega.envio).requiereEntrega, isTrue);
      expect(venta(entrega: TipoEntrega.entregaLocal).requiereEntrega, isTrue);
      expect(venta(entrega: TipoEntrega.entregaLocal).entregaPendiente, isTrue);
    });

    test('una venta entregada ya no está pendiente', () {
      final v = venta(estadoEnvio: 'entregado');
      expect(v.estadoEnvioActual, EstadoEnvio.entregado);
      expect(v.entregaPendiente, isFalse);
    });

    test('serializa repartidor y estado de envío', () {
      final original = Venta(
        id: 'v1',
        empresaId: 'e1',
        tipoEntrega: TipoEntrega.envio,
        estadoEnvio: 'en_reparto',
        repartidorUid: 'u9',
        repartidorNombre: 'Pepito',
      );
      final copia = Venta.fromMap('v1', original.toMap());
      expect(copia.estadoEnvioActual, EstadoEnvio.enReparto);
      expect(copia.repartidorUid, 'u9');
      expect(copia.repartidorNombre, 'Pepito');
    });
  });

  group('ParametrosEmpresa.ciudades (spec 011)', () {
    test('esCiudadLocal sin distinguir mayúsculas/espacios', () {
      const p = ParametrosEmpresa(ciudades: <String>['Bogotá', 'Medellín']);
      expect(p.esCiudadLocal('bogotá'), isTrue);
      expect(p.esCiudadLocal(' Medellín '), isTrue);
      expect(p.esCiudadLocal('Cali'), isFalse);
      expect(p.esCiudadLocal(''), isFalse);
      expect(p.esCiudadLocal(null), isFalse);
    });

    test('la lista de ciudades sobrevive la serialización', () {
      const p = ParametrosEmpresa(ciudades: <String>['Bogotá', 'Cali']);
      final copia = ParametrosEmpresa.fromMap(p.toMap());
      expect(copia.ciudades, <String>['Bogotá', 'Cali']);
    });
  });

  group('Rol domiciliario (spec 011)', () {
    test('puede ver y gestionar entregas y operar su caja', () {
      final permisos = Rol.domiciliario.permisos;
      expect(permisos.contains(Permiso.enviosVer), isTrue);
      expect(permisos.contains(Permiso.enviosEditar), isTrue);
      expect(permisos.contains(Permiso.clientesVer), isTrue);
      expect(permisos.contains(Permiso.cajaOperar), isTrue);
      expect(permisos.contains(Permiso.usuariosGestionar), isFalse);
      expect(permisos.contains(Permiso.cajaConfirmar), isFalse);
    });

    test('el cajero sí puede confirmar rendiciones', () {
      expect(Rol.cajero.permisos.contains(Permiso.cajaConfirmar), isTrue);
    });

    test('es asignable desde la gestión de usuarios', () {
      expect(Rol.asignables.contains(Rol.domiciliario), isTrue);
    });
  });
}
