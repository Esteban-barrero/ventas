/// Dominio de **rendiciones de efectivo** (spec 016, RF-05).
///
/// Una rendición es la **entrega de efectivo** de un domiciliario a la caja,
/// con **doble control**: el domiciliario la **declara** y un responsable en
/// tesorería la **confirma** tras contar el dinero.
library;

/// Estado de la rendición.
enum EstadoRendicion {
  pendiente('pendiente', 'Pendiente'),
  confirmada('confirmada', 'Confirmada'),
  rechazada('rechazada', 'Rechazada');

  const EstadoRendicion(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoRendicion desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoRendicion.pendiente;
  }
}

/// Rendición de efectivo (`rendiciones/{id}`). Spec 016.
class Rendicion {
  const Rendicion({
    required this.id,
    required this.empresaId,
    this.fecha,
    this.domiciliarioUid = '',
    this.domiciliarioNombre = '',
    this.montoDeclarado = 0,
    this.estado = EstadoRendicion.pendiente,
    this.recibidoPorUid = '',
    this.recibidoPorNombre = '',
    this.montoContado = 0,
    this.diferencia = 0,
    this.justificacion = '',
    this.fechaConfirmacion,
    this.observaciones = '',
  });

  final String id;
  final String empresaId;
  final DateTime? fecha;

  /// Quién **entrega** el dinero.
  final String domiciliarioUid;
  final String domiciliarioNombre;

  /// Lo que el domiciliario dice tener (declarado).
  final double montoDeclarado;

  final EstadoRendicion estado;

  /// Quién **recibe** el dinero (el responsable que confirma).
  final String recibidoPorUid;
  final String recibidoPorNombre;

  /// Lo que el responsable **contó**.
  final double montoContado;

  /// `montoDeclarado − montoContado` (`> 0` faltante, `< 0` sobrante).
  final double diferencia;

  final String justificacion;
  final DateTime? fechaConfirmacion;
  final String observaciones;

  bool get pendiente => estado == EstadoRendicion.pendiente;

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'fecha': (fecha ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'domiciliarioUid': domiciliarioUid,
        'domiciliarioNombre': domiciliarioNombre,
        'montoDeclarado': montoDeclarado,
        'estado': estado.id,
        'recibidoPorUid': recibidoPorUid,
        'recibidoPorNombre': recibidoPorNombre,
        'montoContado': montoContado,
        'diferencia': diferencia,
        'justificacion': justificacion,
        'fechaConfirmacion': fechaConfirmacion?.toUtc().toIso8601String(),
        'observaciones': observaciones,
      };

  factory Rendicion.fromMap(String id, Map<String, dynamic> data) {
    return Rendicion(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      fecha: aFechaRendicion(data['fecha']),
      domiciliarioUid: (data['domiciliarioUid'] as String?) ?? '',
      domiciliarioNombre: (data['domiciliarioNombre'] as String?) ?? '',
      montoDeclarado: (data['montoDeclarado'] as num?)?.toDouble() ?? 0,
      estado: EstadoRendicion.desdeId(data['estado'] as String?),
      recibidoPorUid: (data['recibidoPorUid'] as String?) ?? '',
      recibidoPorNombre: (data['recibidoPorNombre'] as String?) ?? '',
      montoContado: (data['montoContado'] as num?)?.toDouble() ?? 0,
      diferencia: (data['diferencia'] as num?)?.toDouble() ?? 0,
      justificacion: (data['justificacion'] as String?) ?? '',
      fechaConfirmacion: aFechaRendicion(data['fechaConfirmacion']),
      observaciones: (data['observaciones'] as String?) ?? '',
    );
  }
}

/// Convierte un valor de Firestore (ISO string o Timestamp) a fecha.
DateTime? aFechaRendicion(dynamic valor) {
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
