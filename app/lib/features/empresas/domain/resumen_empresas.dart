/// Resumen de empresas para el tablero de vencimientos (spec 002, RF-10).
library;

import '../../licencia/domain/licencia.dart' show EstadoEmpresa;
import 'empresa.dart';
import 'licencia.dart';

/// Agrupa las empresas por el estado de su licencia.
class ResumenEmpresas {
  const ResumenEmpresas({
    this.activas = const <Empresa>[],
    this.porVencer = const <Empresa>[],
    this.vencidas = const <Empresa>[],
    this.suspendidas = const <Empresa>[],
    this.enPrueba = const <Empresa>[],
    this.eliminadas = const <Empresa>[],
  });

  final List<Empresa> activas;
  final List<Empresa> porVencer;
  final List<Empresa> vencidas;
  final List<Empresa> suspendidas;
  final List<Empresa> enPrueba;
  final List<Empresa> eliminadas;

  /// Empresas que pueden usar el aplicativo ahora mismo.
  int get totalOperativas => activas.length + porVencer.length + enPrueba.length;

  /// Empresas que requieren atención (por vencer o vencidas).
  int get totalPorAtender => porVencer.length + vencidas.length;

  /// Todas las empresas visibles en el tablero (sin las eliminadas).
  int get totalVigentes =>
      activas.length + porVencer.length + enPrueba.length + vencidas.length + suspendidas.length;

  /// Clasifica [empresas] según su estado y el estado de su licencia.
  factory ResumenEmpresas.calcular(List<Empresa> empresas, DateTime ahora) {
    final activas = <Empresa>[];
    final porVencer = <Empresa>[];
    final vencidas = <Empresa>[];
    final suspendidas = <Empresa>[];
    final enPrueba = <Empresa>[];
    final eliminadas = <Empresa>[];

    for (final empresa in empresas) {
      if (empresa.estado == EstadoEmpresa.eliminada) {
        eliminadas.add(empresa);
        continue;
      }
      switch (empresa.estadoLicencia(ahora)) {
        case EstadoLicenciaNegocio.activa:
          activas.add(empresa);
        case EstadoLicenciaNegocio.porVencer:
          porVencer.add(empresa);
        case EstadoLicenciaNegocio.vencida:
          vencidas.add(empresa);
        case EstadoLicenciaNegocio.suspendida:
          suspendidas.add(empresa);
        case EstadoLicenciaNegocio.prueba:
          enPrueba.add(empresa);
      }
    }

    // Por vencer: lo más urgente primero (menos días restantes).
    porVencer.sort((Empresa a, Empresa b) =>
        (a.licencia.diasRestantes(ahora) ?? 0)
            .compareTo(b.licencia.diasRestantes(ahora) ?? 0));

    return ResumenEmpresas(
      activas: activas,
      porVencer: porVencer,
      vencidas: vencidas,
      suspendidas: suspendidas,
      enPrueba: enPrueba,
      eliminadas: eliminadas,
    );
  }
}
