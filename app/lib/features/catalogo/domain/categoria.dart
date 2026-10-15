/// Categoría del catálogo (`categorias/{id}`). Spec 003, RF-10.
///
/// Cada empresa tiene sus propias categorías (multi-tenant: `empresaId`).
class Categoria {
  const Categoria({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.descripcion = '',
    this.activo = true,
  });

  final String id;
  final String empresaId;
  final String nombre;
  final String descripcion;
  final bool activo;

  Categoria copyWith({
    String? nombre,
    String? descripcion,
    bool? activo,
  }) {
    return Categoria(
      id: id,
      empresaId: empresaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'nombre': nombre,
        'descripcion': descripcion,
        'activo': activo,
      };

  factory Categoria.fromMap(String id, Map<String, dynamic> data) {
    return Categoria(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      descripcion: (data['descripcion'] as String?) ?? '',
      activo: (data['activo'] as bool?) ?? true,
    );
  }
}
