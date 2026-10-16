/// Dominio de caja por turno (spec 009) sobre el libro único de tesorería (016).
///
/// Una **caja** es un turno con `estado: abierta`. Sus movimientos viven en el
/// libro `movimientos_dinero` (spec 016) con `ubicacion: cajaFisica` y el
/// `cajaId` del turno; el saldo del turno es la suma de esos movimientos.
library;

import '../../tesoreria/domain/movimiento_dinero.dart';

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
    this.medioPredominante = MedioDinero.efectivo,
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
  final MedioDinero medioPredominante;
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
          MedioDinero.desdeId(data['medioPredominante'] as String?),
      fechaApertura: aFechaCaja(data['fechaApertura']),
      fechaCierre: aFechaCaja(data['fechaCierre']),
      cerradoPor: (data['cerradoPor'] as String?) ?? '',
      diferenciaCierre: (data['diferenciaCierre'] as num?)?.toDouble() ?? 0,
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
    this.desglose = const <String, num>{},
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
  final Map<String, num> desglose;
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
        'desgloseEfectivo': desglose,
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
      desglose: (data['desgloseEfectivo'] as Map?)?.cast<String, num>() ??
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
