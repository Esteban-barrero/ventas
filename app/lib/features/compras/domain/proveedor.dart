/// Proveedor (`proveedores/{id}`). Spec 007.
class Proveedor {
  const Proveedor({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.nit = '',
    this.direccion = '',
    this.telefono = '',
    this.correo = '',
    this.contacto = '',
    this.activo = true,
    this.fechaCreacion,
  });

  final String id;
  final String empresaId;
  final String nombre;

  /// NIT / RIF (único por empresa, RN-07).
  final String nit;
  final String direccion;
  final String telefono;
  final String correo;
  final String contacto;
  final bool activo;
  final DateTime? fechaCreacion;

  Proveedor copyWith({
    String? nombre,
    String? nit,
    String? direccion,
    String? telefono,
    String? correo,
    String? contacto,
    bool? activo,
  }) {
    return Proveedor(
      id: id,
      empresaId: empresaId,
      nombre: nombre ?? this.nombre,
      nit: nit ?? this.nit,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      contacto: contacto ?? this.contacto,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'nombre': nombre,
        'nit': nit,
        'direccion': direccion,
        'telefono': telefono,
        'correo': correo,
        'contacto': contacto,
        'activo': activo,
        'fechaCreacion':
            (fechaCreacion ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory Proveedor.fromMap(String id, Map<String, dynamic> data) {
    return Proveedor(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      nit: (data['nit'] as String?) ?? '',
      direccion: (data['direccion'] as String?) ?? '',
      telefono: (data['telefono'] as String?) ?? '',
      correo: (data['correo'] as String?) ?? '',
      contacto: (data['contacto'] as String?) ?? '',
      activo: (data['activo'] as bool?) ?? true,
      fechaCreacion: aFecha(data['fechaCreacion']),
    );
  }
}

/// Convierte un valor de Firestore (ISO string o Timestamp) a fecha.
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
