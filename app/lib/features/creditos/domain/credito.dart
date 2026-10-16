/// Dominio de créditos y cobros (spec 006).
///
/// Un crédito nace de una venta a crédito, tiene un **plan de cuotas** y un
/// saldo que baja con los abonos. Es multi-tenant (`empresaId`).
library;

/// Periodicidad del plan de cuotas (RF-02).
enum Periodicidad {
  semanal('semanal', 'Semanal'),
  quincenal('quincenal', 'Quincenal'),
  mensual('mensual', 'Mensual');

  const Periodicidad(this.id, this.nombre);

  final String id;
  final String nombre;

  static Periodicidad desdeId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return Periodicidad.mensual;
  }
}

/// Estado del crédito (RF-08).
enum EstadoCredito {
  activo('activo', 'Activo'),
  pagado('pagado', 'Pagado'),
  vencido('vencido', 'Vencido'),
  cancelado('cancelado', 'Cancelado');

  const EstadoCredito(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoCredito desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoCredito.activo;
  }
}

/// Estado de una cuota.
enum EstadoCuota {
  pendiente('pendiente', 'Pendiente'),
  parcial('parcial', 'Parcial'),
  pagada('pagada', 'Pagada'),
  vencida('vencida', 'Vencida');

  const EstadoCuota(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoCuota desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoCuota.pendiente;
  }
}

/// Una cuota del crédito (`creditos/{id}/cuotas/{cuotaId}`).
class Cuota {
  const Cuota({
    required this.numero,
    required this.fechaVencimiento,
    required this.monto,
    this.pagado = 0,
    this.estado = EstadoCuota.pendiente,
    this.fechaPago,
  });

  final int numero;
  final DateTime fechaVencimiento;
  final double monto;
  final double pagado;
  final EstadoCuota estado;
  final DateTime? fechaPago;

  /// Saldo pendiente de la cuota.
  double get saldo => (monto - pagado) < 0 ? 0 : monto - pagado;

  bool get estaPagada => estado == EstadoCuota.pagada;

  /// `true` si venció y aún tiene saldo (para el cálculo de mora).
  bool vencidaAl(DateTime ahora) =>
      !estaPagada && fechaVencimiento.isBefore(_soloFecha(ahora));

  Cuota copyWith({
    double? pagado,
    EstadoCuota? estado,
    DateTime? fechaPago,
  }) {
    return Cuota(
      numero: numero,
      fechaVencimiento: fechaVencimiento,
      monto: monto,
      pagado: pagado ?? this.pagado,
      estado: estado ?? this.estado,
      fechaPago: fechaPago ?? this.fechaPago,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'numero': numero,
        'fechaVencimiento': fechaVencimiento.toUtc().toIso8601String(),
        'monto': monto,
        'pagado': pagado,
        'saldo': saldo,
        'estado': estado.id,
        'fechaPago': fechaPago?.toUtc().toIso8601String(),
      };

  factory Cuota.fromMap(Map<String, dynamic> data) {
    return Cuota(
      numero: (data['numero'] as num?)?.toInt() ?? 0,
      fechaVencimiento: _aFecha(data['fechaVencimiento']) ?? DateTime.now(),
      monto: (data['monto'] as num?)?.toDouble() ?? 0,
      pagado: (data['pagado'] as num?)?.toDouble() ?? 0,
      estado: EstadoCuota.desdeId(data['estado'] as String?),
      fechaPago: _aFecha(data['fechaPago']),
    );
  }
}

/// Un crédito (`creditos/{id}`). Spec 006.
class Credito {
  const Credito({
    required this.id,
    required this.empresaId,
    required this.clienteId,
    this.clienteNombre = '',
    this.clienteUid,
    this.ventaId = '',
    this.montoTotal = 0,
    this.tasaInteres = 0,
    this.montoConInteres = 0,
    this.numeroCuotas = 0,
    this.periodicidad = Periodicidad.mensual,
    this.fechaInicio,
    this.fechaPrimerPago,
    this.saldoActual = 0,
    this.cuotasPagadas = 0,
    this.diasMora = 0,
    this.aprobado = false,
    this.aprobadoPor = '',
    this.fechaAprobacion,
    this.estado = EstadoCredito.activo,
    this.motivoCancelacion = '',
  });

  final String id;
  final String empresaId;
  final String clienteId;
  final String clienteNombre;
  final String? clienteUid;
  final String ventaId;
  final double montoTotal;
  final double tasaInteres;
  final double montoConInteres;
  final int numeroCuotas;
  final Periodicidad periodicidad;
  final DateTime? fechaInicio;
  final DateTime? fechaPrimerPago;
  final double saldoActual;
  final int cuotasPagadas;
  final int diasMora;
  final bool aprobado;
  final String aprobadoPor;
  final DateTime? fechaAprobacion;
  final EstadoCredito estado;
  final String motivoCancelacion;

  bool get pagado => estado == EstadoCredito.pagado;
  bool get cancelado => estado == EstadoCredito.cancelado;

  /// Cuotas que faltan por pagar (según el contador persistido).
  int get cuotasPendientes =>
      (numeroCuotas - cuotasPagadas) < 0 ? 0 : numeroCuotas - cuotasPagadas;

  Credito copyWith({
    String? clienteNombre,
    double? saldoActual,
    int? cuotasPagadas,
    int? diasMora,
    bool? aprobado,
    String? aprobadoPor,
    DateTime? fechaAprobacion,
    EstadoCredito? estado,
    String? motivoCancelacion,
  }) {
    return Credito(
      id: id,
      empresaId: empresaId,
      clienteId: clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteUid: clienteUid,
      ventaId: ventaId,
      montoTotal: montoTotal,
      tasaInteres: tasaInteres,
      montoConInteres: montoConInteres,
      numeroCuotas: numeroCuotas,
      periodicidad: periodicidad,
      fechaInicio: fechaInicio,
      fechaPrimerPago: fechaPrimerPago,
      saldoActual: saldoActual ?? this.saldoActual,
      cuotasPagadas: cuotasPagadas ?? this.cuotasPagadas,
      diasMora: diasMora ?? this.diasMora,
      aprobado: aprobado ?? this.aprobado,
      aprobadoPor: aprobadoPor ?? this.aprobadoPor,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      estado: estado ?? this.estado,
      motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
    );
  }

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'clienteUid': clienteUid,
        'ventaId': ventaId,
        'montoTotal': montoTotal,
        'tasaInteres': tasaInteres,
        'montoConInteres': montoConInteres,
        'numeroCuotas': numeroCuotas,
        'periodicidad': periodicidad.id,
        'fechaInicio':
            (fechaInicio ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'fechaPrimerPago': fechaPrimerPago?.toUtc().toIso8601String(),
        'saldoActual': saldoActual,
        'cuotasPagadas': cuotasPagadas,
        'diasMora': diasMora,
        'aprobado': aprobado,
        'aprobadoPor': aprobadoPor,
        'fechaAprobacion': fechaAprobacion?.toUtc().toIso8601String(),
        'estado': estado.id,
        'motivoCancelacion': motivoCancelacion,
      };

  factory Credito.fromMap(String id, Map<String, dynamic> data) {
    return Credito(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      clienteId: (data['clienteId'] as String?) ?? '',
      clienteNombre: (data['clienteNombre'] as String?) ?? '',
      clienteUid: data['clienteUid'] as String?,
      ventaId: (data['ventaId'] as String?) ?? '',
      montoTotal: (data['montoTotal'] as num?)?.toDouble() ?? 0,
      tasaInteres: (data['tasaInteres'] as num?)?.toDouble() ?? 0,
      montoConInteres: (data['montoConInteres'] as num?)?.toDouble() ?? 0,
      numeroCuotas: (data['numeroCuotas'] as num?)?.toInt() ?? 0,
      periodicidad: Periodicidad.desdeId(data['periodicidad'] as String?),
      fechaInicio: _aFecha(data['fechaInicio']),
      fechaPrimerPago: _aFecha(data['fechaPrimerPago']),
      saldoActual: (data['saldoActual'] as num?)?.toDouble() ?? 0,
      cuotasPagadas: (data['cuotasPagadas'] as num?)?.toInt() ?? 0,
      diasMora: (data['diasMora'] as num?)?.toInt() ?? 0,
      aprobado: (data['aprobado'] as bool?) ?? false,
      aprobadoPor: (data['aprobadoPor'] as String?) ?? '',
      fechaAprobacion: _aFecha(data['fechaAprobacion']),
      estado: EstadoCredito.desdeId(data['estado'] as String?),
      motivoCancelacion: (data['motivoCancelacion'] as String?) ?? '',
    );
  }
}

/// Suma `indice` periodos a una fecha (RF-03, RN-03).
DateTime sumarPeriodicidad(DateTime base, int indice, Periodicidad periodicidad) {
  switch (periodicidad) {
    case Periodicidad.semanal:
      return base.add(Duration(days: 7 * indice));
    case Periodicidad.quincenal:
      return base.add(Duration(days: 15 * indice));
    case Periodicidad.mensual:
      return DateTime(base.year, base.month + indice, base.day);
  }
}

/// Genera el plan de cuotas de un crédito (RF-03, RN-02).
///
/// `montoConInteres = monto * (1 + tasa/100)`; la cuota base es el total entre
/// el número de cuotas y la **última** ajusta el redondeo (RN/caso borde).
List<Cuota> generarCuotas({
  required double monto,
  required int numeroCuotas,
  required Periodicidad periodicidad,
  required DateTime fechaPrimerPago,
  double tasaInteres = 0,
}) {
  if (numeroCuotas <= 0) return const <Cuota>[];
  final tasa = tasaInteres < 0 ? 0.0 : tasaInteres;
  final total = monto * (1 + tasa / 100);
  final base = total / numeroCuotas;
  final cuotas = <Cuota>[];
  for (var i = 0; i < numeroCuotas; i++) {
    final esUltima = i == numeroCuotas - 1;
    final valor = esUltima ? total - base * (numeroCuotas - 1) : base;
    cuotas.add(
      Cuota(
        numero: i + 1,
        fechaVencimiento: sumarPeriodicidad(fechaPrimerPago, i, periodicidad),
        monto: valor,
      ),
    );
  }
  return cuotas;
}

/// Días de mora: la mayor diferencia (en días) entre hoy y las cuotas vencidas
/// sin pagar (RF-07, RN-05).
int calcularMoraDeCuotas(List<Cuota> cuotas, {DateTime? ahora}) {
  final hoy = _soloFecha(ahora ?? DateTime.now());
  var maximo = 0;
  for (final c in cuotas) {
    if (c.estaPagada) continue;
    final venc = _soloFecha(c.fechaVencimiento);
    if (venc.isBefore(hoy)) {
      final dias = hoy.difference(venc).inDays;
      if (dias > maximo) maximo = dias;
    }
  }
  return maximo;
}

DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);

/// Convierte un valor de Firestore (ISO string o Timestamp) a fecha.
DateTime? _aFecha(dynamic valor) {
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
