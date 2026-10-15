/// Licencia editable de una empresa (spec 002).
///
/// Ver [`data-model.md`](../../../../../specs/002-gestion-empresas/data-model.md):
/// el mapa `empresas/{id}.licencia` guarda el tipo, las fechas, los dias de
/// aviso, el valor y el historial de pagos. El campo `estado` es un valor
/// **derivado** (se recalcula siempre a partir de las fechas), pero se persiste
/// para poder consultar y ordenar desde el tablero sin abrir cada documento.
library;

import '../../licencia/domain/licencia.dart' show EstadoEmpresa;

/// Tipo de licencia contratada (RF-02).
enum TipoLicencia {
  gratis('gratis', 'Gratis'),
  mensual('mensual', 'Mensual'),
  anual('anual', 'Anual'),
  personalizado('personalizado', 'Personalizado');

  const TipoLicencia(this.id, this.nombre);

  final String id;
  final String nombre;

  static TipoLicencia desdeId(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return TipoLicencia.mensual;
  }
}

/// Estado **derivado** de la licencia (campo `licencia.estado`).
enum EstadoLicenciaNegocio {
  activa('activa', 'Activa'),
  porVencer('por_vencer', 'Por vencer'),
  vencida('vencida', 'Vencida'),
  suspendida('suspendida', 'Suspendida'),
  prueba('prueba', 'En prueba');

  const EstadoLicenciaNegocio(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoLicenciaNegocio desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoLicenciaNegocio.activa;
  }
}

/// Un pago o renovación registrado en el historial (RF-12).
class PagoLicencia {
  const PagoLicencia({
    required this.fecha,
    required this.valor,
    this.periodoInicio,
    this.periodoFin,
    this.nota = '',
  });

  final DateTime fecha;
  final double valor;
  final DateTime? periodoInicio;
  final DateTime? periodoFin;
  final String nota;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'fecha': fecha.toIso8601String(),
        'valor': valor,
        'periodoInicio': periodoInicio?.toIso8601String(),
        'periodoFin': periodoFin?.toIso8601String(),
        'nota': nota,
      };

  factory PagoLicencia.fromMap(Map<String, dynamic> data) => PagoLicencia(
        fecha: aFecha(data['fecha']) ?? DateTime.now(),
        valor: (data['valor'] as num?)?.toDouble() ?? 0,
        periodoInicio: aFecha(data['periodoInicio']),
        periodoFin: aFecha(data['periodoFin']),
        nota: (data['nota'] as String?) ?? '',
      );
}

/// Licencia de una empresa.
class Licencia {
  const Licencia({
    this.tipo = TipoLicencia.mensual,
    this.fechaInicio,
    this.fechaFin,
    this.diasAvisoVencimiento = 5,
    this.valorPagado = 0,
    this.historialPagos = const <PagoLicencia>[],
  });

  /// Licencia de cortesía sin vencimiento (empresas de prueba).
  static const Licencia gratuita = Licencia(tipo: TipoLicencia.gratis);

  final TipoLicencia tipo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  /// Días de anticipación con los que se avisa del vencimiento (RN-06).
  final int diasAvisoVencimiento;

  final double valorPagado;
  final List<PagoLicencia> historialPagos;

  /// Días que faltan para el vencimiento (negativo si ya venció).
  int? diasRestantes(DateTime ahora) =>
      fechaFin == null ? null : diasEntre(ahora, fechaFin!);

  /// Calcula el estado a partir de las fechas y del estado de la empresa.
  ///
  /// Prioriza el estado de la empresa (suspendida/eliminada/en prueba) y, si
  /// no, decide por fechas: vencida, por vencer (dentro de los días de aviso)
  /// o activa.
  EstadoLicenciaNegocio calcularEstado(
    DateTime ahora, {
    EstadoEmpresa estadoEmpresa = EstadoEmpresa.activa,
  }) {
    if (estadoEmpresa == EstadoEmpresa.suspendida) {
      return EstadoLicenciaNegocio.suspendida;
    }
    if (estadoEmpresa == EstadoEmpresa.prueba) {
      return EstadoLicenciaNegocio.prueba;
    }
    final dias = diasRestantes(ahora);
    if (dias == null) return EstadoLicenciaNegocio.activa;
    if (dias < 0) return EstadoLicenciaNegocio.vencida;
    if (dias <= diasAvisoVencimiento) return EstadoLicenciaNegocio.porVencer;
    return EstadoLicenciaNegocio.activa;
  }

  /// `true` si la fecha de fin no es anterior a la de inicio (caso borde).
  bool get fechasCoherentes =>
      fechaInicio == null || fechaFin == null || !fechaFin!.isBefore(fechaInicio!);

  /// `true` si la licencia vence dentro de los días de aviso (RN-06).
  bool porVencer(DateTime ahora) {
    final dias = diasRestantes(ahora);
    return dias != null && dias >= 0 && dias <= diasAvisoVencimiento;
  }

  /// `true` si la licencia ya venció.
  bool vencida(DateTime ahora) {
    final dias = diasRestantes(ahora);
    return dias != null && dias < 0;
  }

  Licencia copyWith({
    TipoLicencia? tipo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? diasAvisoVencimiento,
    double? valorPagado,
    List<PagoLicencia>? historialPagos,
  }) {
    return Licencia(
      tipo: tipo ?? this.tipo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      diasAvisoVencimiento: diasAvisoVencimiento ?? this.diasAvisoVencimiento,
      valorPagado: valorPagado ?? this.valorPagado,
      historialPagos: historialPagos ?? this.historialPagos,
    );
  }

  Map<String, dynamic> toMap({
    DateTime? ahora,
    EstadoEmpresa estadoEmpresa = EstadoEmpresa.activa,
  }) =>
      <String, dynamic>{
        'tipo': tipo.id,
        'fechaInicio': fechaInicio?.toIso8601String(),
        'fechaFin': fechaFin?.toIso8601String(),
        'estado': calcularEstado(ahora ?? DateTime.now(), estadoEmpresa: estadoEmpresa).id,
        'diasAvisoVencimiento': diasAvisoVencimiento,
        'valorPagado': valorPagado,
        'historialPagos':
            historialPagos.map((PagoLicencia p) => p.toMap()).toList(growable: false),
      };

  factory Licencia.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const Licencia();
    return Licencia(
      tipo: TipoLicencia.desdeId(data['tipo'] as String?),
      fechaInicio: aFecha(data['fechaInicio']),
      fechaFin: aFecha(data['fechaFin']),
      diasAvisoVencimiento:
          (data['diasAvisoVencimiento'] as num?)?.toInt() ?? 5,
      valorPagado: (data['valorPagado'] as num?)?.toDouble() ?? 0,
      historialPagos: (data['historialPagos'] as List<dynamic>? ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              PagoLicencia.fromMap(m.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

/// Días completos entre dos fechas (comparando por día, sin horas).
int diasEntre(DateTime desde, DateTime hasta) {
  final d = DateTime(desde.year, desde.month, desde.day);
  final h = DateTime(hasta.year, hasta.month, hasta.day);
  return h.difference(d).inDays;
}

/// Convierte un valor de Firestore (ISO string, [DateTime] o Timestamp) a fecha.
DateTime? aFecha(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor;
  if (valor is String) return DateTime.tryParse(valor);
  try {
    final dynamic fecha = (valor as dynamic).toDate();
    if (fecha is DateTime) return fecha;
  } catch (_) {
    // Tipo desconocido; se ignora.
  }
  return null;
}
