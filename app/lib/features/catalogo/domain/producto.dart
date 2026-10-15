import '../../empresas/domain/parametros_empresa.dart';
import 'precio.dart';

/// Medidas y detalles físicos de un producto (spec 003, RF-02).
class Medidas {
  const Medidas({
    this.material = '',
    this.dimensiones = '',
    this.peso = '',
  });

  final String material;
  final String dimensiones;
  final String peso;

  /// `true` si no se definió ninguna medida.
  bool get vacio =>
      material.trim().isEmpty &&
      dimensiones.trim().isEmpty &&
      peso.trim().isEmpty;

  /// Resumen legible para las tarjetas del catálogo (ej. "Algodón · M/L/XL").
  String get resumen {
    final partes = <String>[
      if (material.trim().isNotEmpty) material.trim(),
      if (dimensiones.trim().isNotEmpty) dimensiones.trim(),
      if (peso.trim().isNotEmpty) peso.trim(),
    ];
    return partes.join(' · ');
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'material': material,
        'dimensiones': dimensiones,
        'peso': peso,
      };

  factory Medidas.fromMap(Map<String, dynamic>? data) {
    final m = data ?? const <String, dynamic>{};
    return Medidas(
      material: (m['material'] as String?) ?? '',
      dimensiones: (m['dimensiones'] as String?) ?? '',
      peso: (m['peso'] as String?) ?? '',
    );
  }
}

/// Producto del catálogo (`productos/{id}`). Spec 003.
class Producto {
  const Producto({
    required this.id,
    required this.empresaId,
    required this.codigo,
    required this.nombre,
    this.descripcion = '',
    this.medidas = const Medidas(),
    this.categoriaId = '',
    this.color = '',
    this.fotoPrincipal = '',
    this.galeria = const <String>[],
    this.costo = 0,
    this.margenContado,
    this.margenCredito,
    this.costoEnvio,
    this.stock = 0,
    this.stockMinimo = 0,
    this.activo = true,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  final String id;
  final String empresaId;
  final String codigo;
  final String nombre;
  final String descripcion;
  final Medidas medidas;
  final String categoriaId;

  /// Color del producto (característica propia, para mostrar y filtrar).
  final String color;
  final String fotoPrincipal;
  final List<String> galeria;

  /// Costo de compra al proveedor.
  final double costo;

  /// Margen **contado** (opcional). `null` = hereda el general de la empresa.
  final double? margenContado;

  /// Margen **crédito** (opcional). `null` = hereda el general de la empresa.
  final double? margenCredito;

  /// Costo de envío individual (opcional). `null` = hereda el general.
  final double? costoEnvio;

  final int stock;
  final int stockMinimo;
  final bool activo;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  /// `true` si el producto tiene foto principal.
  bool get tieneFoto => fotoPrincipal.trim().isNotEmpty;

  /// RN-07: avisa cuando el stock está en o por debajo del mínimo.
  bool get stockBajo => stock <= stockMinimo;

  /// Margen efectivo (RN-01, RN-02): el del producto o el general de la empresa.
  double margenEfectivo(TipoPrecio tipo, ParametrosEmpresa empresa) =>
      switch (tipo) {
        TipoPrecio.contado => margenContado ?? empresa.margenContado,
        TipoPrecio.credito => margenCredito ?? empresa.margenCredito,
      };

  /// Precio de venta para una forma de pago (RN-03).
  double precio(TipoPrecio tipo, ParametrosEmpresa empresa) =>
      calcularPrecio(costo, margenEfectivo(tipo, empresa));

  /// Costo de envío efectivo (RN-04): el del producto o el general de la empresa.
  double costoEnvioEfectivo(ParametrosEmpresa empresa) =>
      costoEnvio ?? empresa.costoEnvio;

  Producto copyWith({
    String? codigo,
    String? nombre,
    String? descripcion,
    Medidas? medidas,
    String? categoriaId,
    String? color,
    String? fotoPrincipal,
    List<String>? galeria,
    double? costo,
    Object? margenContado = _sinCambio,
    Object? margenCredito = _sinCambio,
    Object? costoEnvio = _sinCambio,
    int? stock,
    int? stockMinimo,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Producto(
      id: id,
      empresaId: empresaId,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      medidas: medidas ?? this.medidas,
      categoriaId: categoriaId ?? this.categoriaId,
      color: color ?? this.color,
      fotoPrincipal: fotoPrincipal ?? this.fotoPrincipal,
      galeria: galeria ?? this.galeria,
      costo: costo ?? this.costo,
      margenContado:
          margenContado == _sinCambio ? this.margenContado : margenContado as double?,
      margenCredito:
          margenCredito == _sinCambio ? this.margenCredito : margenCredito as double?,
      costoEnvio:
          costoEnvio == _sinCambio ? this.costoEnvio : costoEnvio as double?,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  Map<String, dynamic> toMap({DateTime? ahora}) {
    final momentos = ahora ?? DateTime.now();
    return <String, dynamic>{
      'id': id,
      'empresaId': empresaId,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'medidas': medidas.toMap(),
      'categoriaId': categoriaId,
      'color': color,
      'fotoPrincipal': fotoPrincipal,
      'galeria': galeria,
      'costo': costo,
      'margenes': <String, dynamic>{
        if (margenContado != null) 'contado': margenContado,
        if (margenCredito != null) 'credito': margenCredito,
      },
      'costoEnvio': costoEnvio,
      'stock': stock,
      'stockMinimo': stockMinimo,
      'activo': activo,
      'fechaCreacion': (fechaCreacion ?? momentos).toUtc().toIso8601String(),
      'fechaActualizacion': momentos.toUtc().toIso8601String(),
    };
  }

  factory Producto.fromMap(String id, Map<String, dynamic> data) {
    final margenes = (data['margenes'] as Map?)?.cast<String, dynamic>();
    return Producto(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      codigo: (data['codigo'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? '',
      descripcion: (data['descripcion'] as String?) ?? '',
      medidas: Medidas.fromMap(
          (data['medidas'] as Map?)?.cast<String, dynamic>()),
      categoriaId: (data['categoriaId'] as String?) ?? '',
      color: (data['color'] as String?) ?? '',
      fotoPrincipal: (data['fotoPrincipal'] as String?) ?? '',
      galeria: (data['galeria'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
      costo: (data['costo'] as num?)?.toDouble() ?? 0,
      margenContado: (margenes?['contado'] as num?)?.toDouble(),
      margenCredito: (margenes?['credito'] as num?)?.toDouble(),
      costoEnvio: (data['costoEnvio'] as num?)?.toDouble(),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      stockMinimo: (data['stockMinimo'] as num?)?.toInt() ?? 0,
      activo: (data['activo'] as bool?) ?? true,
      fechaCreacion: _aFecha(data['fechaCreacion']),
      fechaActualizacion: _aFecha(data['fechaActualizacion']),
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
