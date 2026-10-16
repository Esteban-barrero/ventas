/// Dominio de caja y trazabilidad del dinero (spec 009).
///
/// Una **caja** es un turno con `estado: abierta`. Cada ingreso/egreso escribe
/// en `movimientos_caja` (inmutable) y recalcula el saldo de la caja.
library;

import '../../ventas/domain/venta.dart' show MedioPago;

/// Estado de la caja (RF-01, RF-02).
enum EstadoCaja {
  abierta('abierta', 'Abierta'),
  cerrada('cerrada', 'Cerrada');

  const EstadoCaja(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoCaja desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoCaja.abierta;
  }
}

/// Tipo de movimiento de caja (RF-03).
enum TipoMovimientoCaja {
  ingreso('ingreso', 'Ingreso'),
  egreso('egreso', 'Egreso'),
  retiro('retiro', 'Retiro'),
  gasto('gasto', 'Gasto');

  const TipoMovimientoCaja(this.id, this.nombre);

  final String id;
  final String nombre;

  /// `true` si el movimiento **aumenta** el saldo de la caja.
  bool get suma => this == TipoMovimientoCaja.ingreso;

  static TipoMovimientoCaja desdeId(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return TipoMovimientoCaja.ingreso;
  }
}

/// Medio de pago de la caja (RF-04).
enum MedioPagoCaja {
  efectivo('efectivo', 'Efectivo'),
  nequi('nequi', 'Nequi'),
  bancolombia('bancolombia', 'Bancolombia'),
  tarjeta('tarjeta', 'Tarjeta');

  const MedioPagoCaja(this.id, this.nombre);

  final String id;
  final String nombre;

  static MedioPagoCaja desdeId(String? id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return MedioPagoCaja.efectivo;
  }

  /// Equivalencia con el medio de pago de las ventas (spec 005).
  static MedioPagoCaja desdeVenta(MedioPago medio) => switch (medio) {
        MedioPago.efectivo => MedioPagoCaja.efectivo,
        MedioPago.tarjeta => MedioPagoCaja.tarjeta,
        MedioPago.transferenciaNequi => MedioPagoCaja.nequi,
        MedioPago.transferenciaBancolombia => MedioPagoCaja.bancolombia,
      };
}

/// Estado del dinero (RF-06, trazabilidad).
enum EstadoDinero {
  enCaja('en_caja', 'En caja'),
  enTransito('en_transito', 'En tránsito'),
  enBanco('en_banco', 'En banco'),
  entregado('entregado', 'Entregado');

  const EstadoDinero(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoDinero desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoDinero.enCaja;
  }
}

/// Origen del movimiento (RF-09).
enum ReferenciaCaja {
  venta('venta', 'Venta'),
  cobro('cobro', 'Cobro'),
  compra('compra', 'Compra'),
  manual('manual', 'Manual');

  const ReferenciaCaja(this.id, this.nombre);

  final String id;
  final String nombre;

  static ReferenciaCaja desdeId(String? id) {
    for (final r in values) {
      if (r.id == id) return r;
    }
    return ReferenciaCaja.manual;
  }
}

/// Caja/turno (`cajas/{id}`). Spec 009.
class Caja {
  const Caja({
    required this.id,
    required this.empresaId,
    this.nombre = '',
    this.usuarioUid = '',
    this.usuarioNombre = '',
    this.estado = EstadoCaja.abierta,
    this.montoInicial = 0,
    this.saldo = 0,
    this.medioPredominante = MedioPagoCaja.efectivo,
    this.fechaApertura,
    this.fechaCierre,
    this.cerradoPor = '',
    this.diferenciaCierre = 0,
  });

  final String id;
  final String empresaId;
  final String nombre;
  final String usuarioUid;
  final String usuarioNombre;
  final EstadoCaja estado;
  final double montoInicial;
  final double saldo;
  final MedioPagoCaja medioPredominante;
  final DateTime? fechaApertura;
  final DateTime? fechaCierre;
  final String cerradoPor;
  final double diferenciaCierre;

  bool get abierta => estado == EstadoCaja.abierta;

  Caja copyWith({
    EstadoCaja? estado,
    double? saldo,
    DateTime? fechaCierre,
    String? cerradoPor,
    double? diferenciaCierre,
  }) {
    return Caja(
      id: id,
      empresaId: empresaId,
      nombre: nombre,
      usuarioUid: usuarioUid,
      usuarioNombre: usuarioNombre,
      estado: estado ?? this.estado,
      montoInicial: montoInicial,
      saldo: saldo ?? this.saldo,
      medioPredominante: medioPredominante,
      fechaApertura: fechaApertura,
      fechaCierre: fechaCierre ?? this.fechaCierre,
      cerradoPor: cerradoPor ?? this.cerradoPor,
      diferenciaCierre: diferenciaCierre ?? this.diferenciaCierre,
    );
  }

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'nombre': nombre,
        'usuarioUid': usuarioUid,
        'usuarioNombre': usuarioNombre,
        'estado': estado.id,
        'montoInicial': montoInicial,
        'saldo': saldo,
        'medioPredominante': medioPredominante.id,
        'fechaApertura':
            (fechaApertura ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'fechaCierre': fechaCierre?.toUtc().toIso8601String(),
        'cerradoPor': cerradoPor,
        'diferenciaCierre': diferenciaCierre,
      };

  factory Caja.fromMap(String id, Map<String, dynamic> data) {
    return Caja(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      usuarioUid: (data['usuarioUid'] as String?) ?? '',
      usuarioNombre: (data['usuarioNombre'] as String?) ?? '',
      estado: EstadoCaja.desdeId(data['estado'] as String?),
      montoInicial: (data['montoInicial'] as num?)?.toDouble() ?? 0,
      saldo: (data['saldo'] as num?)?.toDouble() ?? 0,
      medioPredominante:
          MedioPagoCaja.desdeId(data['medioPredominante'] as String?),
      fechaApertura: aFechaCaja(data['fechaApertura']),
      fechaCierre: aFechaCaja(data['fechaCierre']),
      cerradoPor: (data['cerradoPor'] as String?) ?? '',
      diferenciaCierre: (data['diferenciaCierre'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Movimiento de caja (`movimientos_caja/{id}`). Inmutable (ADR-002).
class MovimientoCaja {
  const MovimientoCaja({
    required this.id,
    required this.empresaId,
    required this.cajaId,
    this.tipo = TipoMovimientoCaja.ingreso,
    this.concepto = '',
    this.monto = 0,
    this.medioPago = MedioPagoCaja.efectivo,
    this.referenciaTipo = ReferenciaCaja.manual,
    this.referenciaId = '',
    this.responsableUid = '',
    this.estadoDinero = EstadoDinero.enCaja,
    this.empresaEnvio = '',
    this.domiciliario = '',
    this.saldoResultante = 0,
    this.usuarioUid = '',
    this.fecha,
  });

  final String id;
  final String empresaId;
  final String cajaId;
  final TipoMovimientoCaja tipo;
  final String concepto;
  final double monto;
  final MedioPagoCaja medioPago;
  final ReferenciaCaja referenciaTipo;
  final String referenciaId;

  /// Quién tiene o recibe el dinero (RF-05).
  final String responsableUid;
  final EstadoDinero estadoDinero;
  final String empresaEnvio;
  final String domiciliario;
  final double saldoResultante;
  final String usuarioUid;
  final DateTime? fecha;

  bool get suma => tipo.suma;

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'cajaId': cajaId,
        'tipo': tipo.id,
        'concepto': concepto,
        'monto': monto,
        'medioPago': medioPago.id,
        'referenciaTipo': referenciaTipo.id,
        'referenciaId': referenciaId,
        'responsableUid': responsableUid,
        'estadoDinero': estadoDinero.id,
        'empresaEnvio': empresaEnvio,
        'domiciliario': domiciliario,
        'saldoResultante': saldoResultante,
        'usuarioUid': usuarioUid,
        'fecha': (fecha ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory MovimientoCaja.fromMap(String id, Map<String, dynamic> data) {
    return MovimientoCaja(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      cajaId: (data['cajaId'] as String?) ?? '',
      tipo: TipoMovimientoCaja.desdeId(data['tipo'] as String?),
      concepto: (data['concepto'] as String?) ?? '',
      monto: (data['monto'] as num?)?.toDouble() ?? 0,
      medioPago: MedioPagoCaja.desdeId(data['medioPago'] as String?),
      referenciaTipo: ReferenciaCaja.desdeId(data['referenciaTipo'] as String?),
      referenciaId: (data['referenciaId'] as String?) ?? '',
      responsableUid: (data['responsableUid'] as String?) ?? '',
      estadoDinero: EstadoDinero.desdeId(data['estadoDinero'] as String?),
      empresaEnvio: (data['empresaEnvio'] as String?) ?? '',
      domiciliario: (data['domiciliario'] as String?) ?? '',
      saldoResultante: (data['saldoResultante'] as num?)?.toDouble() ?? 0,
      usuarioUid: (data['usuarioUid'] as String?) ?? '',
      fecha: aFechaCaja(data['fecha']),
    );
  }
}

/// Arqueo de cierre (`arqueos/{id}`). Spec 009.
class Arqueo {
  const Arqueo({
    required this.id,
    required this.empresaId,
    required this.cajaId,
    this.fecha,
    this.totalEsperado = 0,
    this.totalContado = 0,
    this.diferencia = 0,
    this.justificacion = '',
    this.desgloseEfectivo = const <String, num>{},
    this.usuarioUid = '',
    this.aprobadoPor = '',
  });

  final String id;
  final String empresaId;
  final String cajaId;
  final DateTime? fecha;
  final double totalEsperado;
  final double totalContado;
  final double diferencia;
  final String justificacion;
  final Map<String, num> desgloseEfectivo;
  final String usuarioUid;
  final String aprobadoPor;

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'cajaId': cajaId,
        'fecha': (fecha ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'totalEsperado': totalEsperado,
        'totalContado': totalContado,
        'diferencia': diferencia,
        'justificacion': justificacion,
        'desgloseEfectivo': desgloseEfectivo,
        'usuarioUid': usuarioUid,
        'aprobadoPor': aprobadoPor,
      };

  factory Arqueo.fromMap(String id, Map<String, dynamic> data) {
    return Arqueo(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      cajaId: (data['cajaId'] as String?) ?? '',
      fecha: aFechaCaja(data['fecha']),
      totalEsperado: (data['totalEsperado'] as num?)?.toDouble() ?? 0,
      totalContado: (data['totalContado'] as num?)?.toDouble() ?? 0,
      diferencia: (data['diferencia'] as num?)?.toDouble() ?? 0,
      justificacion: (data['justificacion'] as String?) ?? '',
      desgloseEfectivo:
          (data['desgloseEfectivo'] as Map?)?.cast<String, num>() ??
              const <String, num>{},
      usuarioUid: (data['usuarioUid'] as String?) ?? '',
      aprobadoPor: (data['aprobadoPor'] as String?) ?? '',
    );
  }
}

/// Convierte un valor de Firestore (ISO string o Timestamp) a fecha.
DateTime? aFechaCaja(dynamic valor) {
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
