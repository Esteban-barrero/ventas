/// Parámetros por defecto de una empresa (spec 002, RF-04).
///
/// Se crean automáticamente al dar de alta la empresa y el Administrador puede
/// ajustarlos. Incluyen márgenes de ganancia por tipo de venta (detal, por
/// mayor, distribuidores), costo de envío y el tema visual de la empresa.
library;

/// Parámetros configurables de una empresa (`empresas/{id}.parametros`).
class ParametrosEmpresa {
  const ParametrosEmpresa({
    this.margenDetal = 30,
    this.margenMayor = 20,
    this.margenDistribuidor = 10,
    this.costoEnvio = 0,
    this.iva = 19,
    this.moneda = 'COP',
    this.colorPrimario = '#1A73E8',
    this.colorSecundario = '#FF6B35',
  });

  /// Márgenes de ganancia por tipo de venta (porcentaje).
  final double margenDetal;
  final double margenMayor;
  final double margenDistribuidor;

  /// Costo de envío por defecto.
  final double costoEnvio;

  /// IVA aplicado (porcentaje).
  final double iva;

  /// Moneda (ISO 4217).
  final String moneda;

  /// Colores del tema de la empresa (hex `#RRGGBB`).
  final String colorPrimario;
  final String colorSecundario;

  /// Parámetros por defecto que recibe toda empresa nueva (RF-04).
  static const ParametrosEmpresa porDefecto = ParametrosEmpresa();

  Map<String, dynamic> toMap() => <String, dynamic>{
        'margenDetal': margenDetal,
        'margenMayor': margenMayor,
        'margenDistribuidor': margenDistribuidor,
        'costoEnvio': costoEnvio,
        'iva': iva,
        'moneda': moneda,
        'tema': <String, dynamic>{
          'colorPrimario': colorPrimario,
          'colorSecundario': colorSecundario,
        },
      };

  factory ParametrosEmpresa.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ParametrosEmpresa();
    final tema = (data['tema'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return ParametrosEmpresa(
      margenDetal: (data['margenDetal'] as num?)?.toDouble() ?? 30,
      margenMayor: (data['margenMayor'] as num?)?.toDouble() ?? 20,
      margenDistribuidor: (data['margenDistribuidor'] as num?)?.toDouble() ?? 10,
      costoEnvio: (data['costoEnvio'] as num?)?.toDouble() ?? 0,
      iva: (data['iva'] as num?)?.toDouble() ?? 19,
      moneda: (data['moneda'] as String?) ?? 'COP',
      colorPrimario: (tema['colorPrimario'] as String?) ?? '#1A73E8',
      colorSecundario: (tema['colorSecundario'] as String?) ?? '#FF6B35',
    );
  }

  ParametrosEmpresa copyWith({
    double? margenDetal,
    double? margenMayor,
    double? margenDistribuidor,
    double? costoEnvio,
    double? iva,
    String? moneda,
    String? colorPrimario,
    String? colorSecundario,
  }) {
    return ParametrosEmpresa(
      margenDetal: margenDetal ?? this.margenDetal,
      margenMayor: margenMayor ?? this.margenMayor,
      margenDistribuidor: margenDistribuidor ?? this.margenDistribuidor,
      costoEnvio: costoEnvio ?? this.costoEnvio,
      iva: iva ?? this.iva,
      moneda: moneda ?? this.moneda,
      colorPrimario: colorPrimario ?? this.colorPrimario,
      colorSecundario: colorSecundario ?? this.colorSecundario,
    );
  }
}
