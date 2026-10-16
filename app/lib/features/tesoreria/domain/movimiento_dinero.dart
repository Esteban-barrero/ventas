/// Dominio de tesorería (spec 016): el **libro único del dinero** de la empresa.
///
/// Todo el dinero se registra como `MovimientoDinero` (ingreso, egreso o
/// traslado) con una **ubicación** y un **responsable**. La caja por turno
/// (spec 009) es la ubicación `cajaFisica` dentro de este mismo libro.
library;

import '../../ventas/domain/venta.dart' show MedioPago;

/// Ubicación del dinero: **dónde** está y **quién** lo tiene (RF-02, RF-06).
enum UbicacionDinero {
  cajaFisica('caja_fisica', 'Caja física'),
  vendedorEfectivo('vendedor_efectivo', 'Efectivo con el vendedor'),
  contraEntrega('contra_entrega', 'Pago contra entrega (en tránsito)'),
  nequi('nequi', 'Nequi'),
  banco('banco', 'Banco (Bancolombia)'),
  tarjetaPorConsignar('tarjeta_por_consignar', 'Tarjeta (por consignar)');

  const UbicacionDinero(this.id, this.nombre);

  final String id;
  final String nombre;

  /// ¿El dinero está físicamente en poder de la empresa (efectivo)?
  bool get esEfectivo =>
      this == UbicacionDinero.cajaFisica ||
      this == UbicacionDinero.vendedorEfectivo ||
      this == UbicacionDinero.contraEntrega;

  static UbicacionDinero desdeId(String? id) {
    for (final u in values) {
      if (u.id == id) return u;
    }
    return UbicacionDinero.cajaFisica;
  }
}

/// Tipo de movimiento del libro (RF-01, RN-02).
enum TipoMovimientoDinero {
  ingreso('ingreso', 'Ingreso'),
  egreso('egreso', 'Egreso'),
  traslado('traslado', 'Traslado');

  const TipoMovimientoDinero(this.id, this.nombre);

  final String id;
  final String nombre;

  /// `true` si el movimiento **suma** a la ubicación de origen.
  bool get suma => this == TipoMovimientoDinero.ingreso;

  static TipoMovimientoDinero desdeId(String? id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return TipoMovimientoDinero.ingreso;
  }
}

/// Medio de pago del dinero (RF-02).
enum MedioDinero {
  efectivo('efectivo', 'Efectivo'),
  nequi('nequi', 'Nequi'),
  bancolombia('bancolombia', 'Bancolombia'),
  tarjeta('tarjeta', 'Tarjeta');

  const MedioDinero(this.id, this.nombre);

  final String id;
  final String nombre;

  static MedioDinero desdeId(String? id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return MedioDinero.efectivo;
  }

  /// Equivalencia con el medio de pago de las ventas (spec 005).
  static MedioDinero desdeVenta(MedioPago medio) => switch (medio) {
        MedioPago.efectivo => MedioDinero.efectivo,
        MedioPago.tarjeta => MedioDinero.tarjeta,
        MedioPago.transferenciaNequi => MedioDinero.nequi,
        MedioPago.transferenciaBancolombia => MedioDinero.bancolombia,
      };
}

/// Origen del movimiento (RF-06).
enum ReferenciaDinero {
  venta('venta', 'Venta'),
  cobro('cobro', 'Cobro'),
  compra('compra', 'Compra'),
  gasto('gasto', 'Gasto'),
  retiro('retiro', 'Retiro'),
  traslado('traslado', 'Traslado'),
  ajuste('ajuste', 'Ajuste'),
  manual('manual', 'Manual'),
  apertura('apertura', 'Saldo inicial');

  const ReferenciaDinero(this.id, this.nombre);

  final String id;
  final String nombre;

  static ReferenciaDinero desdeId(String? id) {
    for (final r in values) {
      if (r.id == id) return r;
    }
    return ReferenciaDinero.manual;
  }
}

/// Movimiento de dinero (`movimientos_dinero/{id}`). Inmutable (RN-01).
class MovimientoDinero {
  const MovimientoDinero({
    required this.id,
    required this.empresaId,
    this.fecha,
    this.tipo = TipoMovimientoDinero.ingreso,
    this.monto = 0,
    this.medioPago = MedioDinero.efectivo,
    this.ubicacion = UbicacionDinero.cajaFisica,
    this.ubicacionDestino,
    this.responsableUid = '',
    this.responsableNombre = '',
    this.descripcion = '',
    this.referenciaTipo = ReferenciaDinero.manual,
    this.referenciaId = '',
    this.cajaId = '',
    this.usuarioUid = '',
    this.usuarioNombre = '',
  });

  final String id;
  final String empresaId;
  final DateTime? fecha;
  final TipoMovimientoDinero tipo;
  final double monto;
  final MedioDinero medioPago;

  /// Ubicación del dinero (origen, si es un traslado).
  final UbicacionDinero ubicacion;

  /// Destino del dinero (solo en `traslado`).
  final UbicacionDinero? ubicacionDestino;

  /// Quién tiene o recibe el dinero (RF-02).
  final String responsableUid;
  final String responsableNombre;

  final String descripcion;
  final ReferenciaDinero referenciaTipo;
  final String referenciaId;

  /// Turno de caja asociado (opcional; ubicación `cajaFisica`).
  final String cajaId;

  final String usuarioUid;
  final String usuarioNombre;

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'empresaId': empresaId,
        'fecha': (fecha ?? ahora ?? DateTime.now()).toUtc().toIso8601String(),
        'tipo': tipo.id,
        'monto': monto,
        'medioPago': medioPago.id,
        'ubicacion': ubicacion.id,
        'ubicacionDestino': ubicacionDestino?.id,
        'responsableUid': responsableUid,
        'responsableNombre': responsableNombre,
        'descripcion': descripcion,
        'referenciaTipo': referenciaTipo.id,
        'referenciaId': referenciaId,
        'cajaId': cajaId,
        'usuarioUid': usuarioUid,
        'usuarioNombre': usuarioNombre,
      };

  factory MovimientoDinero.fromMap(String id, Map<String, dynamic> data) {
    return MovimientoDinero(
      id: (data['id'] as String?) ?? id,
      empresaId: (data['empresaId'] as String?) ?? '',
      fecha: aFechaDinero(data['fecha']),
      tipo: TipoMovimientoDinero.desdeId(data['tipo'] as String?),
      monto: (data['monto'] as num?)?.toDouble() ?? 0,
      medioPago: MedioDinero.desdeId(data['medioPago'] as String?),
      ubicacion: UbicacionDinero.desdeId(data['ubicacion'] as String?),
      ubicacionDestino: data['ubicacionDestino'] == null
          ? null
          : UbicacionDinero.desdeId(data['ubicacionDestino'] as String?),
      responsableUid: (data['responsableUid'] as String?) ?? '',
      responsableNombre: (data['responsableNombre'] as String?) ?? '',
      descripcion: (data['descripcion'] as String?) ?? '',
      referenciaTipo: ReferenciaDinero.desdeId(data['referenciaTipo'] as String?),
      referenciaId: (data['referenciaId'] as String?) ?? '',
      cajaId: (data['cajaId'] as String?) ?? '',
      usuarioUid: (data['usuarioUid'] as String?) ?? '',
      usuarioNombre: (data['usuarioNombre'] as String?) ?? '',
    );
  }
}

/// Convierte un valor de Firestore (ISO string o Timestamp) a fecha.
DateTime? aFechaDinero(dynamic valor) {
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
