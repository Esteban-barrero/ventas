# Contratos: Caja y Trazabilidad del dinero

- **ID:** 009 | **Fecha:** 2026-10-14

---

## 1. Interfaz `CajaRepository` (Dart)

```dart
abstract class CajaRepository {
  Future<Caja?> cajaAbierta(String usuarioUid);
  Future<String> abrirCaja(double montoInicial, {String medioPredominante = 'efectivo'});
  Future<void> registrarMovimiento(MovimientoCaja mov);
  Future<Arqueo> cerrarCaja({
    required double totalContado,
    required Map<String, num> desglose,
    String? justificacion,
  });
  Future<List<MovimientoCaja>> movimientos({String? cajaId, DateTime? desde, DateTime? hasta});
  Future<List<MovimientoCaja>> trazabilidad({String? estadoDinero, String? responsableUid});
  Future<double> saldoConsolidado({String? medioPago});
}
```

---

## 2. Apertura de caja (transaccion)

```dart
Future<String> abrirCaja(double montoInicial, {String medioPredominante = 'efectivo'}) async {
  return firestore.runTransaction((tx) async {
    final abiertas = await tx.get(
      firestore.collection('cajas')
        .where('empresaId', isEqualTo: sesion.empresaId)
        .where('usuarioUid', isEqualTo: sesion.uid)
        .where('estado', isEqualTo: 'abierta')
        .limit(1),
    );   // verificar dentro de la transaccion
    if (abiertas.docs.isNotEmpty) throw CajaYaAbiertaException();

    final ref = firestore.collection('cajas').doc();
    tx.set(ref, {
      'empresaId': sesion.empresaId,
      'nombre': 'Caja ${sesion.usuarioNombre}',
      'usuarioUid': sesion.uid,
      'usuarioNombre': sesion.usuarioNombre,
      'estado': 'abierta',
      'montoInicial': montoInicial,
      'saldo': montoInicial,
      'medioPredominante': medioPredominante,
      'fechaApertura': FieldValue.serverTimestamp(),
    });
    return ref.id;
  });
}
```

---

## 3. Registrar movimiento (transaccion + saldo)

```dart
Future<void> registrarMovimiento(MovimientoCaja m) async {
  await firestore.runTransaction((tx) async {
    final cRef = firestore.collection('cajas').doc(m.cajaId);
    final c = await tx.get(cRef);
    if (c['estado'] != 'abierta') throw CajaCerradaException();

    final saldo = (c['saldo'] as num).toDouble();
    final delta = m.tipo == 'ingreso' ? m.monto : -m.monto;
    final saldoResultante = saldo + delta;

    tx.update(cRef, {'saldo': saldoResultante});
    tx.set(firestore.collection('movimientos_caja').doc(), {
      ...m.toMap(),
      'saldoResultante': saldoResultante,
      'usuarioUid': sesion.uid,
      'fecha': FieldValue.serverTimestamp(),
    });
  });
}
```

---

## 4. Cierre de caja (arqueo)

```dart
Future<Arqueo> cerrarCaja({
  required double totalContado,
  required Map<String, num> desglose,
  String? justificacion,
}) async {
  return firestore.runTransaction((tx) async {
    final cRef = firestore.collection('cajas').doc(sesion.cajaId);
    final c = await tx.get(cRef);
    final esperado = (c['saldo'] as num).toDouble();
    final diferencia = totalContado - esperado;
    if (diferencia != 0 && (justificacion == null || justificacion.isEmpty)) {
      throw JustificacionRequeridaException();
    }

    final arqueoRef = firestore.collection('arqueos').doc();
    final arqueo = {
      'empresaId': sesion.empresaId,
      'cajaId': sesion.cajaId,
      'fecha': FieldValue.serverTimestamp(),
      'totalEsperado': esperado,
      'totalContado': totalContado,
      'diferencia': diferencia,
      'desgloseEfectivo': desglose,
      'justificacion': justificacion,
      'usuarioUid': sesion.uid,
    };
    tx.set(arqueoRef, arqueo);

    tx.update(cRef, {
      'estado': 'cerrada',
      'fechaCierre': FieldValue.serverTimestamp(),
      'cerradoPor': sesion.uid,
      'diferenciaCierre': diferencia,
    });
    return Arqueo.fromMap(arqueoRef.id, arqueo);
  });
}
```

---

## 5. Reglas de Firestore

```
match /cajas/{cajaId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create, update: if esRolInternoDe(request.resource.data.empresaId);
  allow delete: if false;
}

match /movimientos_caja/{movId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create: if esRolInternoDe(request.resource.data.empresaId);
  allow update, delete: if false;   // inmutable
}

match /arqueos/{arqueoId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create: if esRolInternoDe(request.resource.data.empresaId);
  allow update: if esGerenteDe(resource.data.empresaId) || esSuperAdmin();
  allow delete: if false;
}
```

---

## 6. Entidades (resumen)

```dart
class Caja {
  String id, empresaId, nombre, usuarioUid, usuarioNombre;
  String estado;            // abierta | cerrada
  double montoInicial, saldo, diferenciaCierre;
  String medioPredominante;
  DateTime fechaApertura;
  DateTime? fechaCierre;
}

class MovimientoCaja {
  String id, empresaId, cajaId;
  String tipo;              // ingreso | egreso | retiro | gasto
  String concepto;
  double monto, saldoResultante;
  String medioPago;         // efectivo | nequi | bancolombia | tarjeta
  String referenciaTipo;    // venta | cobro | compra | manual
  String referenciaId;
  String responsableUid;
  String estadoDinero;      // en_caja | en_transito | en_banco | entregado
  String? empresaEnvio, domiciliario;
  String usuarioUid;
  DateTime fecha;
}
```
