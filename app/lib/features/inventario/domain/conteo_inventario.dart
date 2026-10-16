import 'movimiento_inventario.dart' show aFechaInventario;

/// Estado de un conteo físico.
enum EstadoConteo {
  enProceso('en_proceso', 'En proceso'),
  cerrado('cerrado', 'Cerrado'),
  anulado('anulado', 'Anulado');

  const EstadoConteo(this.id, this.nombre);

  final String id;
  final String nombre;

  static EstadoConteo desdeId(String? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return EstadoConteo.cerrado;
  }
}

/// Línea de un conteo físico.
class ItemConteo {
  const ItemConteo({
    required this.productoId,
    this.nombre = '',
    this.stockSistema = 0,
    this.stockFisico = 0,
    this.ajusteGenerado = false,
  });

  final String productoId;
  final String nombre;
  final int stockSistema;
  final int stockFisico;
  final bool ajusteGenerado;

  /// Diferencia entre lo contado y el sistema (`stockFisico - stockSistema`).
  int get diferencia => stockFisico - stockSistema;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'productoId': productoId,
        'nombre': nombre,
        'stockSistema': stockSistema,
        'stockFisico': stockFisico,
        'diferencia': diferencia,
        'ajusteGenerado': ajusteGenerado,
      };

  factory ItemConteo.fromMap(Map<String, dynamic> data) {
    return ItemConteo(
      productoId: (data['productoId'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      stockSistema: (data['stockSistema'] as num?)?.toInt() ?? 0,
      stockFisico: (data['stockFisico'] as num?)?.toInt() ?? 0,
      ajusteGenerado: (data['ajusteGenerado'] as bool?) ?? false,
    );
  }
}

/// Conteo físico (`conteos_inventario/{id}`). Spec 008.
class ConteoInventario {
  const ConteoInventario({
    required this.id,
    required this.empresaId,
    this.fecha,
    this.bodegaId = 'principal',
    this.estado = EstadoConteo.cerrado,
    this.items = const <ItemConteo>[],
    this.usuarioUid = '',
    this.aprobadoPor = '',
  });

  final String id;
  final String empresaId;
  final DateTime? fecha;
  final String bodegaId;
  final EstadoConteo estado;
  final List<ItemConteo> items;
  final String usuarioUid;
  final String aprobadoPor;

  /// Movimientos que generaría el conteo (solo las diferencias).
  int get itemsConDiferencia =>
      items.where((ItemConteo i) => i.diferencia != 0).length;

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'fecha': (fecha ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'bodegaId': bodegaId,
        'estado': estado.id,
        'items': items.map((ItemConteo i) => i.toMap()).toList(growable: false),
        'usuarioUid': usuarioUid,
        'aprobadoPor': aprobadoPor,
      };

  factory ConteoInventario.fromMap(String id, Map<String, dynamic> data) {
    return ConteoInventario(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      fecha: aFechaInventario(data['fecha']),
      bodegaId: (data['bodegaId'] as String?) ?? 'principal',
      estado: EstadoConteo.desdeId(data['estado'] as String?),
      items: (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> m) =>
              ItemConteo.fromMap(m.cast<String, dynamic>()))
          .toList(growable: false),
      usuarioUid: (data['usuarioUid'] as String?) ?? '',
      aprobadoPor: (data['aprobadoPor'] as String?) ?? '',
    );
  }
}
