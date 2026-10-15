/// Planes comerciales y sus límites (spec 002, RF-11).
///
/// Colección `planes/{planId}`. Se siembran los planes por defecto y el Super
/// Admin puede editarlos. Al crear una empresa se copian sus límites al
/// documento de la empresa para que un cambio de plan no afecte a las
/// empresas ya creadas.
library;

import 'licencia.dart';

/// Límites de un plan. `-1` significa ilimitado.
class LimitesPlan {
  const LimitesPlan({
    this.maxUsuarios = -1,
    this.maxProductos = -1,
    this.maxAlmacenamientoMB = -1,
  });

  final int maxUsuarios;
  final int maxProductos;
  final int maxAlmacenamientoMB;

  /// `true` si el límite es ilimitado.
  static bool esIlimitado(int valor) => valor < 0;

  /// `true` si [actual] está dentro del límite [maximo].
  static bool dentroDelLimite(int actual, int maximo) =>
      esIlimitado(maximo) || actual <= maximo;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'maxUsuarios': maxUsuarios,
        'maxProductos': maxProductos,
        'maxAlmacenamientoMB': maxAlmacenamientoMB,
      };

  factory LimitesPlan.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const LimitesPlan();
    return LimitesPlan(
      maxUsuarios: (data['maxUsuarios'] as num?)?.toInt() ?? -1,
      maxProductos: (data['maxProductos'] as num?)?.toInt() ?? -1,
      maxAlmacenamientoMB:
          (data['maxAlmacenamientoMB'] as num?)?.toInt() ?? -1,
    );
  }
}

/// Un plan comercial (`planes/{planId}`).
class Plan {
  const Plan({
    required this.id,
    required this.nombre,
    this.periodicidad = TipoLicencia.mensual,
    this.valor = 0,
    this.limites = const LimitesPlan(),
    this.activo = true,
  });

  final String id;
  final String nombre;
  final TipoLicencia periodicidad;
  final double valor;
  final LimitesPlan limites;
  final bool activo;

  /// Planes que se siembran en la colección `planes` (T003).
  static const List<Plan> porDefecto = <Plan>[
    Plan(
      id: 'gratis',
      nombre: 'Gratis',
      periodicidad: TipoLicencia.gratis,
      valor: 0,
      limites: LimitesPlan(
        maxUsuarios: 2,
        maxProductos: 50,
        maxAlmacenamientoMB: 100,
      ),
    ),
    Plan(
      id: 'basico',
      nombre: 'Básico',
      periodicidad: TipoLicencia.mensual,
      valor: 99000,
      limites: LimitesPlan(
        maxUsuarios: 10,
        maxProductos: 1000,
        maxAlmacenamientoMB: 2048,
      ),
    ),
    Plan(
      id: 'premium',
      nombre: 'Premium',
      periodicidad: TipoLicencia.mensual,
      valor: 249000,
      limites: LimitesPlan(
        maxUsuarios: 50,
        maxProductos: 10000,
        maxAlmacenamientoMB: 10240,
      ),
    ),
  ];

  /// Devuelve el plan por defecto con ese id (o `null`).
  static Plan? porDefectoConId(String id) {
    for (final p in porDefecto) {
      if (p.id == id) return p;
    }
    return null;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'nombre': nombre,
        'periodicidad': periodicidad.id,
        'valor': valor,
        'limites': limites.toMap(),
        'activo': activo,
      };

  factory Plan.fromMap(Map<String, dynamic> data) => Plan(
        id: (data['id'] as String?) ?? '',
        nombre: (data['nombre'] as String?) ?? '',
        periodicidad: TipoLicencia.desdeId(data['periodicidad'] as String?),
        valor: (data['valor'] as num?)?.toDouble() ?? 0,
        limites: LimitesPlan.fromMap(
            (data['limites'] as Map?)?.cast<String, dynamic>()),
        activo: (data['activo'] as bool?) ?? true,
      );
}
