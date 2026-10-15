/// Dominio de licencias y estado de empresa (spec 001).
///
/// Reglas de negocio cubiertas aqui:
/// - RN-05: si la licencia esta vencida o la empresa suspendida, se bloquea
///   el ingreso de todos sus usuarios.
/// - RN-06: el aviso de vencimiento aparece cuando faltan los dias
///   configurados (`diasAvisoVencimiento`, por defecto 5).
library;

/// Estado de una empresa.
enum EstadoEmpresa {
  activa('activa', 'Activa'),
  suspendida('suspendida', 'Suspendida'),
  prueba('prueba', 'En prueba');

  const EstadoEmpresa(this.id, this.nombre);

  final String id;
  final String nombre;

  /// Interpreta el `estado` guardado en Firestore (por defecto `activa`).
  static EstadoEmpresa desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoEmpresa.activa;
  }
}

/// Resultado de evaluar la licencia de una empresa.
class EstadoLicencia {
  const EstadoLicencia({
    required this.vigente,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    this.diasRestantes,
    this.contactoProveedor = '',
    this.diasAvisoVencimiento = 5,
  });

  /// Si la licencia permite el ingreso.
  final bool vigente;

  final EstadoEmpresa estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  /// Dias que faltan para el vencimiento (negativo si ya vencio).
  final int? diasRestantes;

  /// Contacto del proveedor del aplicativo, para mostrar al bloquear.
  final String contactoProveedor;

  /// Dias de anticipacion con los que se avisa del vencimiento (RN-06).
  final int diasAvisoVencimiento;

  /// RN-06: hay que avisar al usuario cuando esta por vencer.
  bool get debeAvisar =>
      vigente &&
      diasRestantes != null &&
      diasRestantes! >= 0 &&
      diasRestantes! <= diasAvisoVencimiento;

  /// Explicacion del bloqueo, para el usuario.
  String get motivoBloqueo {
    if (estado == EstadoEmpresa.suspendida) {
      return 'La empresa está suspendida.';
    }
    if (diasRestantes != null && diasRestantes! < 0) {
      return 'La licencia está vencida.';
    }
    return 'La licencia no está vigente.';
  }

  /// Evalua la licencia a partir del documento `empresas/{id}` de Firestore.
  ///
  /// Se usa como verificacion local mientras la Cloud Function `validarLicencia`
  /// no este desplegada (o si no hay conexion).
  factory EstadoLicencia.desdeEmpresa(
    Map<String, dynamic> empresa, {
    DateTime? ahora,
  }) {
    final estado = EstadoEmpresa.desdeId(empresa['estado'] as String?);
    final licencia =
        (empresa['licencia'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};

    final fechaInicio = _aFecha(licencia['fechaInicio']);
    final fechaFin = _aFecha(licencia['fechaFin']);
    final diasAviso =
        (licencia['diasAvisoVencimiento'] as num?)?.toInt() ?? 5;
    final contacto = (empresa['contactoProveedor'] as String?) ?? '';

    final hoy = ahora ?? DateTime.now();
    final diasRestantes = fechaFin == null ? null : _diasEntre(hoy, fechaFin);

    var vigente = true;
    if (estado == EstadoEmpresa.suspendida) vigente = false;
    if (diasRestantes != null && diasRestantes < 0) vigente = false;

    return EstadoLicencia(
      vigente: vigente,
      estado: estado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      diasRestantes: diasRestantes,
      contactoProveedor: contacto,
      diasAvisoVencimiento: diasAviso,
    );
  }

  /// Construye el estado a partir de la respuesta de la Cloud Function
  /// `validarLicencia` (spec 001 - contratos).
  factory EstadoLicencia.desdeFuncion(Map<String, dynamic> data) {
    return EstadoLicencia(
      vigente: (data['vigente'] as bool?) ?? false,
      estado: EstadoEmpresa.desdeId(data['estado'] as String?),
      fechaInicio: _aFecha(data['fechaInicio']),
      fechaFin: _aFecha(data['fechaFin']),
      diasRestantes: (data['diasRestantes'] as num?)?.toInt(),
      contactoProveedor: (data['contactoProveedor'] as String?) ?? '',
      diasAvisoVencimiento:
          (data['diasAvisoVencimiento'] as num?)?.toInt() ?? 5,
    );
  }

  /// Dias completos entre dos fechas (comparando por dia, sin horas).
  static int _diasEntre(DateTime desde, DateTime hasta) {
    final d = DateTime(desde.year, desde.month, desde.day);
    final h = DateTime(hasta.year, hasta.month, hasta.day);
    return h.difference(d).inDays;
  }

  static DateTime? _aFecha(dynamic valor) {
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
}

/// Resultado de validar la licencia de la empresa del usuario.
sealed class ResultadoLicencia {
  const ResultadoLicencia();
}

/// La licencia esta vigente: se permite el ingreso.
class LicenciaVigente extends ResultadoLicencia {
  const LicenciaVigente(this.estado);

  final EstadoLicencia estado;
}

/// La licencia esta vencida o la empresa suspendida: se bloquea el ingreso.
class LicenciaBloqueada extends ResultadoLicencia {
  const LicenciaBloqueada(this.estado);

  final EstadoLicencia estado;
}

/// No se pudo verificar la licencia (sin conexion, sin datos, etc.).
/// Por seguridad se bloquea el ingreso.
class LicenciaNoDisponible extends ResultadoLicencia {
  const LicenciaNoDisponible(this.detalle);

  final String detalle;
}
