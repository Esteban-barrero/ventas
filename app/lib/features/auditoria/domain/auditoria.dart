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
