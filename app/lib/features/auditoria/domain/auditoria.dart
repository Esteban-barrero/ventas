/// Auditoría de cambios (spec 001, RF-11 / CA-07).
///
/// Colección `_auditoria/{autoId}`: un registro por cada campo modificado.
/// Ver `data-model.md` para los campos.
library;

/// Operación registrada.
enum OperacionAuditoria {
  insert('INSERT'),
  update('UPDATE'),
  delete('DELETE');

  const OperacionAuditoria(this.id);

  /// Código persistido en Firestore.
  final String id;
}

/// Un campo que cambió entre dos versiones de un documento.
class CambioCampo {
  const CambioCampo({
    required this.campo,
    this.valorViejo,
    this.valorNuevo,
  });

  final String campo;
  final dynamic valorViejo;
  final dynamic valorNuevo;

  @override
  String toString() => 'CambioCampo($campo: $valorViejo -> $valorNuevo)';
}

/// Compara dos versiones de un documento y devuelve los campos que cambiaron.
///
/// Se consideran las claves de ambos mapas, de modo que sirve tanto para
/// modificaciones como para campos agregados o eliminados.
///
/// Nota: para registrar cambios parciales, se debe pasar en `antes` solo las
/// claves que se están modificando (ver `UsuariosRepository.actualizarRoles`).
List<CambioCampo> calcularCambios(
  Map<String, dynamic> antes,
  Map<String, dynamic> despues,
) {
  final claves = <String>{...antes.keys, ...despues.keys};
  final cambios = <CambioCampo>[];

  for (final clave in claves) {
    final viejo = antes[clave];
    final nuevo = despues[clave];
    if (!_iguales(viejo, nuevo)) {
      cambios.add(CambioCampo(campo: clave, valorViejo: viejo, valorNuevo: nuevo));
    }
  }

  return cambios;
}

/// Compara valores de Firestore (primitivos, listas y mapas).
bool _iguales(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;

  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_iguales(a[i], b[i])) return false;
    }
    return true;
  }

  if (a is Map && b is Map) {
    final claves = <Object>{...a.keys, ...b.keys};
    for (final k in claves) {
      if (!_iguales(a[k], b[k])) return false;
    }
    return true;
  }

  return a == b;
}

/// Un registro de auditoría (`_auditoria/{id}`). Spec 012.
///
/// Un `UPDATE` genera un registro por **campo** cambiado; `INSERT`/`DELETE`
/// generan un registro con el snapshot completo.
class RegistroAuditoria {
  const RegistroAuditoria({
    required this.id,
    this.empresaId = '',
    this.empresaNombre = '',
    this.usuario = '',
    this.usuarioNombre = '',
    this.usuarioEmail = '',
    this.fecha,
    this.operacion = '',
    this.tabla = '',
    this.documentoId = '',
    this.campo = '',
    this.valorViejo,
    this.valorNuevo,
  });

  final String id;
  final String empresaId;

  /// Nombre de la empresa al momento del cambio (spec 012).
  final String empresaNombre;

  /// UID del usuario que hizo el cambio (`desconocido` si no se pudo saber).
  final String usuario;

  /// Nombre del usuario al momento del cambio.
  final String usuarioNombre;

  /// Correo del usuario al momento del cambio.
  final String usuarioEmail;

  final DateTime? fecha;

  /// `INSERT` | `UPDATE` | `DELETE`.
  final String operacion;

  final String tabla;
  final String documentoId;
  final String campo;
  final dynamic valorViejo;
  final dynamic valorNuevo;

  /// Descripción legible del registro.
  String get descripcion {
    if (campo.isEmpty) {
      return operacion == OperacionAuditoria.delete.id ? 'Eliminado' : 'Creado';
    }
    return '$campo: ${textoValor(valorViejo)} → ${textoValor(valorNuevo)}';
  }

  /// Nombre del usuario (o el uid si no se guardó el nombre).
  String get usuarioMostrar =>
      usuarioNombre.trim().isNotEmpty ? usuarioNombre : usuario;

  /// Nombre de la empresa (o el id si no se guardó el nombre).
  String get empresaMostrar =>
      empresaNombre.trim().isNotEmpty ? empresaNombre : empresaId;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'empresaNombre': empresaNombre,
        'usuario': usuario,
        'usuarioNombre': usuarioNombre,
        'usuarioEmail': usuarioEmail,
        'fecha': fecha?.toUtc().toIso8601String(),
        'operacion': operacion,
        'tabla': tabla,
        'documentoId': documentoId,
        'campo': campo,
        'valorViejo': valorViejo,
        'valorNuevo': valorNuevo,
      };

  factory RegistroAuditoria.fromMap(String id, Map<String, dynamic> data) {
    return RegistroAuditoria(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      empresaNombre: (data['empresaNombre'] as String?) ?? '',
      usuario: (data['usuario'] as String?) ?? '',
      usuarioNombre: (data['usuarioNombre'] as String?) ?? '',
      usuarioEmail: (data['usuarioEmail'] as String?) ?? '',
      fecha: aFechaAuditoria(data['fecha']),
      operacion: (data['operacion'] as String?) ?? '',
      tabla: (data['tabla'] as String?) ?? '',
      documentoId: (data['documentoId'] as String?) ?? '',
      campo: (data['campo'] as String?) ?? '',
      valorViejo: data['valorViejo'],
      valorNuevo: data['valorNuevo'],
    );
  }
}

/// Texto legible de un valor de auditoría.
String textoValor(dynamic valor) {
  if (valor == null) return '—';
  if (valor is String) return valor;
  return valor.toString();
}

/// Convierte un valor de Firestore (ISO string o Timestamp) a fecha.
DateTime? aFechaAuditoria(dynamic valor) {
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
