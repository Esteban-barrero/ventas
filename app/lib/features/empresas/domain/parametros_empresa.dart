/// Parámetros por defecto de una empresa (spec 002, RF-04).
///
/// Se crean automáticamente al dar de alta la empresa y el Administrador puede
/// ajustarlos. Incluyen los márgenes de ganancia (generales por canal y los
/// **duales de contado/crédito** que usa el catálogo, spec 003), costo de envío
/// y el tema visual de la empresa.
library;

/// Parámetros configurables de una empresa (`empresas/{id}.parametros`).
class ParametrosEmpresa {
  const ParametrosEmpresa({
    this.margenDetal = 30,
    this.margenMayor = 20,
    this.margenDistribuidor = 10,
    this.margenContado = 30,
    this.margenCredito = 40,
    this.costoEnvio = 0,
    this.iva = 19,
    this.reteFuente = 0,
    this.reteIva = 0,
    this.reteIca = 0,
    this.moneda = 'COP',
    this.colorPrimario = '#1A73E8',
    this.colorSecundario = '#FF6B35',
    this.ciudades = const <String>[],
  });

  /// Márgenes de ganancia por tipo de venta (porcentaje).
  final double margenDetal;
  final double margenMayor;
  final double margenDistribuidor;

  /// Margen de ganancia **dual** (contado y crédito), spec 003.
  ///
  /// Es el margen general de la empresa; un producto puede definir el suyo
  /// propio y, si no lo hace, hereda estos (RN-01).
  final double margenContado;
  final double margenCredito;

  /// Costo de envío por defecto.
  final double costoEnvio;

  /// IVA aplicado (porcentaje).
  final double iva;

  /// Tasas de **retención** para compras (%), 0 = no aplica.
  final double reteFuente;
  final double reteIva;
  final double reteIca;

  /// Moneda (ISO 4217).
  final String moneda;

  /// Colores del tema de la empresa (hex `#RRGGBB`).
  final String colorPrimario;
  final String colorSecundario;

  /// Ciudades donde opera la empresa (spec 011). Una entrega en una de estas
  /// ciudades es **local**; en otra, es **envío**.
  final List<String> ciudades;

  /// `true` si la ciudad indicada es una ciudad de la empresa (local).
  bool esCiudadLocal(String? ciudad) {
    final c = (ciudad ?? '').trim().toLowerCase();
    if (c.isEmpty) return false;
    return ciudades
        .any((String x) => x.trim().toLowerCase() == c);
  }

  /// Parámetros por defecto que recibe toda empresa nueva (RF-04).
  static const ParametrosEmpresa porDefecto = ParametrosEmpresa();

  Map<String, dynamic> toMap() => <String, dynamic>{
        'margenDetal': margenDetal,
        'margenMayor': margenMayor,
        'margenDistribuidor': margenDistribuidor,
        'margenContado': margenContado,
        'margenCredito': margenCredito,
        'costoEnvio': costoEnvio,
        'iva': iva,
        'reteFuente': reteFuente,
        'reteIva': reteIva,
        'reteIca': reteIca,
        'moneda': moneda,
        'ciudades': ciudades,
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
      margenContado: (data['margenContado'] as num?)?.toDouble() ?? 30,
      margenCredito: (data['margenCredito'] as num?)?.toDouble() ?? 40,
      costoEnvio: (data['costoEnvio'] as num?)?.toDouble() ?? 0,
      iva: (data['iva'] as num?)?.toDouble() ?? 19,
      reteFuente: (data['reteFuente'] as num?)?.toDouble() ?? 0,
      reteIva: (data['reteIva'] as num?)?.toDouble() ?? 0,
      reteIca: (data['reteIca'] as num?)?.toDouble() ?? 0,
      moneda: (data['moneda'] as String?) ?? 'COP',
      ciudades: (data['ciudades'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
      colorPrimario: (tema['colorPrimario'] as String?) ?? '#1A73E8',
      colorSecundario: (tema['colorSecundario'] as String?) ?? '#FF6B35',
    );
  }

  ParametrosEmpresa copyWith({
    double? margenDetal,
    double? margenMayor,
    double? margenDistribuidor,
    double? margenContado,
    double? margenCredito,
    double? costoEnvio,
    double? iva,
    double? reteFuente,
    double? reteIva,
    double? reteIca,
    String? moneda,
    String? colorPrimario,
    String? colorSecundario,
    List<String>? ciudades,
  }) {
    return ParametrosEmpresa(
      margenDetal: margenDetal ?? this.margenDetal,
      margenMayor: margenMayor ?? this.margenMayor,
      margenDistribuidor: margenDistribuidor ?? this.margenDistribuidor,
      margenContado: margenContado ?? this.margenContado,
      margenCredito: margenCredito ?? this.margenCredito,
      costoEnvio: costoEnvio ?? this.costoEnvio,
      iva: iva ?? this.iva,
      reteFuente: reteFuente ?? this.reteFuente,
      reteIva: reteIva ?? this.reteIva,
      reteIca: reteIca ?? this.reteIca,
      moneda: moneda ?? this.moneda,
      ciudades: ciudades ?? this.ciudades,
      colorPrimario: colorPrimario ?? this.colorPrimario,
      colorSecundario: colorSecundario ?? this.colorSecundario,
    );
  }
}
