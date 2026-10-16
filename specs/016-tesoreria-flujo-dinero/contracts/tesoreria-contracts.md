# Contratos: Tesorería y flujo del dinero

- **ID:** 016 | **Fecha:** 2026-10-16

---

## 1. Interfaz `TesoreriaRepository` (Dart)

```dart
abstract class TesoreriaRepository {
  Stream<List<MovimientoDinero>> escucharMovimientos(String empresaId);
  Future<String> registrarMovimiento({
    required String empresaId,
    required TipoMovimientoDinero tipo, // ingreso | egreso
    required double monto,
    required UbicacionDinero ubicacion,
    required MedioDinero medioPago,
    required ReferenciaDinero referenciaTipo,
    String referenciaId,
    String responsableUid,
    String responsableNombre,
    String descripcion,
    String cajaId,
    required String usuarioUid,
  });
  Future<String> trasladar({
    required String empresaId,
    required double monto,
    required UbicacionDinero origen,
    required UbicacionDinero destino,
    String descripcion,
    required String usuarioUid,
  });
  Future<Map<UbicacionDinero, double>> posiciones(String empresaId);
  Future<double> total(String empresaId);
}
```

---

## 2. Cálculo de posiciones (dominio puro)

```dart
Map<UbicacionDinero, double> calcularPosiciones(
  List<MovimientoDinero> movimientos,
) {
  final saldo = <UbicacionDinero, double>{};
  for (final m in movimientos) {
    switch (m.tipo) {
      case TipoMovimientoDinero.ingreso:
        saldo[m.ubicacion] = (saldo[m.ubicacion] ?? 0) + m.monto;
      case TipoMovimientoDinero.egreso:
        saldo[m.ubicacion] = (saldo[m.ubicacion] ?? 0) - m.monto;
      case TipoMovimientoDinero.traslado:
        saldo[m.ubicacion] = (saldo[m.ubicacion] ?? 0) - m.monto;
        saldo[m.ubicacionDestino] =
            (saldo[m.ubicacionDestino] ?? 0) + m.monto;
    }
  }
  return saldo;
}
```

---

## 3. Ubicación de una venta de contado (RN-04)

```dart
UbicacionDinero ubicacionDeVenta(MedioPago medio, TipoEntrega entrega) {
  if (medio == MedioPago.efectivo) {
    return entrega == TipoEntrega.domicilio
        ? UbicacionDinero.contraEntrega
        : UbicacionDinero.cajaFisica;
  }
  return switch (medio) {
    MedioPago.transferenciaNequi => UbicacionDinero.nequi,
    MedioPago.transferenciaBancolombia => UbicacionDinero.banco,
    MedioPago.tarjeta => UbicacionDinero.tarjetaPorConsignar,
    MedioPago.efectivo => UbicacionDinero.cajaFisica,
  };
}
```
