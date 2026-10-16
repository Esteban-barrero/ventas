/// Dominio de clientes (spec 004).
///
/// Un cliente pertenece a una empresa (`empresaId`), tiene dirección completa y
/// (opcionalmente) ubicación GPS, clasificación comercial y estado.
library;

/// Clasificación comercial del cliente (RF-06).
enum Clasificacion {
  detal('detal', 'Detal'),
  mayorista('mayorista', 'Mayorista');

  const Clasificacion(this.id, this.nombre);

  final String id;
  final String nombre;

  static Clasificacion desdeId(String? id) {
    for (final c in values) {
      if (c.id == id) return c;
    }
    return Clasificacion.detal;
  }
}

/// Estado del cliente (RF-09).
enum EstadoCliente {
  activo('activo', 'Activo'),
  inactivo('inactivo', 'Inactivo'),
  moroso('moroso', 'Moroso');

  const EstadoCliente(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoCliente desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoCliente.activo;
  }
}

/// Tipo de documento de identidad.
enum TipoDocumento {
  cc('CC', 'Cédula de ciudadanía'),
  nit('NIT', 'NIT'),
  ce('CE', 'Cédula de extranjería'),
  pasaporte('PA', 'Pasaporte');

  const TipoDocumento(this.id, this.nombre);

  final String id;
  final String nombre;

  static TipoDocumento desdeId(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return TipoDocumento.cc;
  }
}

/// Dirección completa del cliente (RF-02).
class Direccion {
  const Direccion({
    this.departamento = '',
    this.ciudad = '',
    this.direccion = '',
    this.barrio = '',
    this.referencia = '',
  });

  final String departamento;
  final String ciudad;
  final String direccion;
  final String barrio;
  final String referencia;

  /// Obligatorios de la dirección (RN-01).
  bool get completa =>
      departamento.trim().isNotEmpty &&
      ciudad.trim().isNotEmpty &&
      direccion.trim().isNotEmpty;

  /// Resumen legible (ej. "Calle 1 #2-3, Chapinero, Bogotá").
  String get resumen {
    final partes = <String>[
      if (direccion.trim().isNotEmpty) direccion.trim(),
      if (barrio.trim().isNotEmpty) barrio.trim(),
      if (ciudad.trim().isNotEmpty) ciudad.trim(),
      if (departamento.trim().isNotEmpty) departamento.trim(),
    ];
    return partes.join(', ');
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'departamento': departamento,
        'ciudad': ciudad,
        'direccion': direccion,
        'barrio': barrio,
        'referencia': referencia,
      };

  factory Direccion.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};
    return Direccion(
      departamento: (d['departamento'] as String?) ?? '',
      ciudad: (d['ciudad'] as String?) ?? '',
      direccion: (d['direccion'] as String?) ?? '',
      barrio: (d['barrio'] as String?) ?? '',
      referencia: (d['referencia'] as String?) ?? '',
    );
  }

  Direccion copyWith({
    String? departamento,
    String? ciudad,
    String? direccion,
    String? barrio,
    String? referencia,
  }) {
    return Direccion(
      departamento: departamento ?? this.departamento,
      ciudad: ciudad ?? this.ciudad,
      direccion: direccion ?? this.direccion,
      barrio: barrio ?? this.barrio,
      referencia: referencia ?? this.referencia,
    );
  }
}

/// Ubicación GPS del cliente (RF-04).
class UbicacionGPS {
  const UbicacionGPS({
    required this.latitud,
    required this.longitud,
    this.direccionAproximada = '',
    this.fecha,
  });

  final double latitud;
  final double longitud;
  final String direccionAproximada;
  final DateTime? fecha;

  /// Texto corto para mostrar (ej. "4.6486, -74.0628").
  String get coordenadas =>
      '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}';

  Map<String, dynamic> toMap() => <String, dynamic>{
        'latitud': latitud,
        'longitud': longitud,
        'direccionAproximada': direccionAproximada,
        'fecha': (fecha ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory UbicacionGPS.fromMap(Map<String, dynamic>? data) {
    final u = data ?? const <String, dynamic>{};
    return UbicacionGPS(
      latitud: (u['latitud'] as num?)?.toDouble() ?? 0,
      longitud: (u['longitud'] as num?)?.toDouble() ?? 0,
      direccionAproximada: (u['direccionAproximada'] as String?) ?? '',
      fecha: _aFecha(u['fecha']),
    );
  }
}

/// Cliente (`clientes/{id}`). Spec 004.
class Cliente {
  const Cliente({
    required this.id,
    required this.empresaId,
    required this.nombreCompleto,
    required this.cedula,
    this.tipoDocumento = TipoDocumento.cc,
    required this.telefono,
    this.correo = '',
    this.contacto = '',
    this.telefonoAlterno = '',
    this.direccion = const Direccion(),
    this.ubicacionGPS,
    this.clasificacion = Clasificacion.detal,
    this.estado = EstadoCliente.activo,
    this.creditoLimite = 0,
    this.creditoSaldo = 0,
    this.observaciones = '',
    this.uid,
    this.fechaCreacion,
  });

  final String id;
  final String empresaId;

  /// UID de Firebase Auth si el cliente tiene cuenta (rol Cliente).
  final String? uid;

  final String nombreCompleto;
  final String cedula;
  final TipoDocumento tipoDocumento;
  final String telefono;
  final String correo;
  final String contacto;
  final String telefonoAlterno;
  final Direccion direccion;
  final UbicacionGPS? ubicacionGPS;
  final Clasificacion clasificacion;
  final EstadoCliente estado;
  final double creditoLimite;
  final double creditoSaldo;
  final String observaciones;
  final DateTime? fechaCreacion;

  bool get tieneUbicacion => ubicacionGPS != null;

  Cliente copyWith({
    String? nombreCompleto,
    String? cedula,
    TipoDocumento? tipoDocumento,
    String? telefono,
    String? correo,
    String? contacto,
    String? telefonoAlterno,
    Direccion? direccion,
    Object? ubicacionGPS = _sinCambio,
    Clasificacion? clasificacion,
    EstadoCliente? estado,
    double? creditoLimite,
    double? creditoSaldo,
    String? observaciones,
    String? uid,
    DateTime? fechaCreacion,
  }) {
    return Cliente(
      id: id,
      empresaId: empresaId,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      cedula: cedula ?? this.cedula,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      contacto: contacto ?? this.contacto,
      telefonoAlterno: telefonoAlterno ?? this.telefonoAlterno,
      direccion: direccion ?? this.direccion,
      ubicacionGPS: ubicacionGPS == _sinCambio
          ? this.ubicacionGPS
          : ubicacionGPS as UbicacionGPS?,
      clasificacion: clasificacion ?? this.clasificacion,
      estado: estado ?? this.estado,
      creditoLimite: creditoLimite ?? this.creditoLimite,
      creditoSaldo: creditoSaldo ?? this.creditoSaldo,
      observaciones: observaciones ?? this.observaciones,
      uid: uid ?? this.uid,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'uid': uid,
        'nombreCompleto': nombreCompleto,
        'cedula': cedula,
        'tipoDocumento': tipoDocumento.id,
        'telefono': telefono,
        'correo': correo,
        'contacto': contacto,
        'telefonoAlterno': telefonoAlterno,
        'direccion': direccion.toMap(),
        'ubicacionGPS': ubicacionGPS?.toMap(),
        'clasificacion': clasificacion.id,
        'estado': estado.id,
        'creditoLimite': creditoLimite,
        'creditoSaldo': creditoSaldo,
        'observaciones': observaciones,
        'fechaCreacion':
            (fechaCreacion ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory Cliente.fromMap(String id, Map<String, dynamic> data) {
    return Cliente(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      uid: data['uid'] as String?,
      nombreCompleto: (data['nombreCompleto'] as String?) ?? '',
      cedula: (data['cedula'] as String?) ?? '',
      tipoDocumento: TipoDocumento.desdeId(data['tipoDocumento'] as String?),
      telefono: (data['telefono'] as String?) ?? '',
      correo: (data['correo'] as String?) ?? '',
      contacto: (data['contacto'] as String?) ?? '',
      telefonoAlterno: (data['telefonoAlterno'] as String?) ?? '',
      direccion:
          Direccion.fromMap((data['direccion'] as Map?)?.cast<String, dynamic>()),
      ubicacionGPS: data['ubicacionGPS'] == null
          ? null
          : UbicacionGPS.fromMap(
              (data['ubicacionGPS'] as Map?)?.cast<String, dynamic>()),
      clasificacion: Clasificacion.desdeId(data['clasificacion'] as String?),
      estado: EstadoCliente.desdeId(data['estado'] as String?),
      creditoLimite: (data['creditoLimite'] as num?)?.toDouble() ?? 0,
      creditoSaldo: (data['creditoSaldo'] as num?)?.toDouble() ?? 0,
      observaciones: (data['observaciones'] as String?) ?? '',
      fechaCreacion: _aFecha(data['fechaCreacion']),
    );
  }
}

/// Centinela para distinguir "no cambiar" de "poner en null" en `copyWith`.
const Object _sinCambio = Object();

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
