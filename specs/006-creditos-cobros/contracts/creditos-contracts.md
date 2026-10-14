# Contratos: Créditos y Cobros

- **ID:** 006 | **Fecha:** 2026-10-14

---

## 1. Interfaz `CreditosRepository` (Dart)

```dart
abstract class CreditosRepository {
  Future<String> crearDesdeVenta(String ventaId, {
    required int numeroCuotas, required String periodicidad, double tasaInteres = 0 });
  Future<void> aprobar(String creditoId);
  Future<Credito?> obtener(String creditoId);
  Future<List<Credito>> listar({String? estado, String? clienteId});
  Future<List<Cuota>> cuotas(String creditoId);
  Future<String> registrarPago(String creditoId, double monto, String medioPago);
  Future<void> cancelar(String creditoId, String motivo);
}
```

---

## 2. Generación del plan de cuotas (Dart)

```dart
List<Cuota> generarCuotas({
  required double monto,
  required int numeroCuotas,
  required String periodicidad,
  required DateTime fechaPrimerPago,
  double tasaInteres = 0,
}) {
  final total = monto * (1 + tasaInteres / 100);
  final base = total / numeroCuotas;
  final cuotas = <Cuota>[];
  for (var i = 0; i < numeroCuotas; i++) {
    final esUltima = i == numeroCuotas - 1;
    final valor = esUltima ? total - base * (numeroCuotas - 1) : base;
    cuotas.add(Cuota(
      numero: i + 1,
      fechaVencimiento: _sumar(fechaPrimerPago, i, periodicidad),
      monto: valor,
      saldo: valor,
      estado: 'pendiente',
    ));
  }
  return cuotas;
}
```

---

## 3. Cálculo de mora (Dart)

```dart
int calcularMora(List<Cuota> cuotas) {
  final hoy = DateTime.now();
  return cuotas
      .where((c) => c.estado != 'pagada' && c.fechaVencimiento.isBefore(hoy))
      .map((c) => hoy.difference(c.fechaVencimiento).inDays)
      .fold<int>(0, (a, b) => a > b ? a : b);
}
```

---

## 4. Transacción `registrarPago` (pseudocódigo)

```dart
Future<String> registrarPago(String creditoId, double monto, String medioPago) async {
  return firestore.runTransaction((tx) async {
    // 1. leer credito y cuotas pendientes -> aplicar a la mas antigua
    // 2. actualizar cuota (pagado/saldo/estado)
    // 3. actualizar credito (saldo, cuotasPagadas, estado)
    // 4. crear movimiento_caja
    // 5. auditoria
  });
}
```

---

## 5. Cloud Function programada: `actualizarMoraYNotificar`

**Tipo:** Cloud Scheduler (diario)

**Acción:**
1. Recalcula `diasMora` por crédito.
2. Marca cuotas vencidas.
3. Marca clientes morosos si superan el límite.
4. Envía avisos (correo + in-app) de cuotas por vencer y vencidas.

---

## 6. Reglas de Firestore

```
match /creditos/{creditoId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId &&
     (esRolInterno() || resource.data.clienteUid == request.auth.uid));
  allow create, update: if esRolInternoDe(request.resource.data.empresaId);
  allow delete: if false;
}
```

---

## 7. Entidades (resumen)

```dart
class Credito {
  String id, empresaId, clienteId, ventaId;
  double montoTotal, tasaInteres, montoConInteres, saldoActual;
  int numeroCuotas, cuotasPagadas, diasMora;
  String periodicidad; // semanal | quincenal | mensual
  bool aprobado;
  String estado;       // activo | pagado | vencido | cancelado
}

class Cuota {
  int numero;
  DateTime fechaVencimiento;
  double monto, pagado, saldo;
  String estado;       // pendiente | pagada | vencida | parcial
}
```
