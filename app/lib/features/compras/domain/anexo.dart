import 'proveedor.dart' show aFecha;

/// Tipo de anexo legal de una compra (RF-04).
enum TipoAnexo {
  facturaEscaneada('factura_escaneada', 'Factura escaneada'),
  facturaPdf('factura_pdf', 'Factura PDF'),
  anexoLegal('anexo_legal', 'Anexo legal'),
  otro('otro', 'Otro');

  const TipoAnexo(this.id, this.nombre);

  final String id;
  final String nombre;

  static TipoAnexo desdeId(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return TipoAnexo.otro;
  }
}

/// Anexo legal de una compra (`compras/{id}/anexos/{anexoId}`). Spec 007.
class Anexo {
  const Anexo({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.tipo = TipoAnexo.otro,
    this.url = '',
    this.tamano = 0,
    this.contentType = '',
    this.fechaSubida,
    this.subidoPor = '',
  });

  final String id;
  final String empresaId;
  final String nombre;
  final TipoAnexo tipo;

  /// URL de descarga en Storage.
  final String url;
  final int tamano;
  final String contentType;
  final DateTime? fechaSubida;

  /// UID del usuario que subió el archivo (trazabilidad, RF-06).
  final String subidoPor;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'nombre': nombre,
        'tipo': tipo.id,
        'url': url,
        'tamano': tamano,
        'contentType': contentType,
        'fechaSubida':
            (fechaSubida ?? DateTime.now()).toUtc().toIso8601String(),
        'subidoPor': subidoPor,
      };

  factory Anexo.fromMap(String id, Map<String, dynamic> data) {
    return Anexo(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      tipo: TipoAnexo.desdeId(data['tipo'] as String?),
      url: (data['url'] as String?) ?? '',
      tamano: (data['tamano'] as num?)?.toInt() ?? 0,
      contentType: (data['contentType'] as String?) ?? '',
      fechaSubida: aFecha(data['fechaSubida']),
      subidoPor: (data['subidoPor'] as String?) ?? '',
    );
  }
}
