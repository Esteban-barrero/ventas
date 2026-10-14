# Contratos: Auditoría

- **ID:** 012 | **Fecha:** 2026-10-14

---

## 1. Cloud Function: auditoría en escritura (TypeScript)

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const COLECCIONES_AUDITADAS = [
  'empresas', 'usuarios', 'productos', 'clientes',
  'ventas', 'creditos', 'pagos_credito', 'compras',
  'proveedores', 'movimientos_inventario', 'cajas',
  'movimientos_caja', 'pedidos', 'envios', 'parametros',
];

function cambiosEntre(antes: any = {}, despues: any = {}) {
  const cambios: any[] = [];
  const claves = new Set([...Object.keys(antes), ...Object.keys(despues)]);
  for (const campo of claves) {
    const a = antes[campo];
    const d = despues[campo];
    if (JSON.stringify(a) !== JSON.stringify(d)) {
      cambios.push({ campo, valorAnterior: a ?? null, valorNuevo: d ?? null });
    }
  }
  return cambios;
}

export const auditarEscritura = functions.firestore
  .document('{coleccion}/{docId}')
  .onWrite(async (change, ctx) => {
    const { coleccion, docId } = ctx.params;
    if (!COLECCIONES_AUDITADAS.includes(coleccion)) return;

    const antes  = change.before.exists ? change.before.data() : null;
    const despues = change.after.exists ? change.after.data() : null;

    let operacion = 'UPDATE';
    if (!antes) operacion = 'INSERT';
    else if (!despues) operacion = 'DELETE';

    const base = despues ?? antes ?? {};
    const meses = Math.max(6, base.mesesRetencion ?? 6);
    const expiraEn = admin.firestore.Timestamp.fromMillis(
      Date.now() + meses * 30 * 24 * 60 * 60 * 1000,
    );

    await admin.firestore().collection('_auditoria').add({
      empresaId: base.empresaId ?? 'sistema',
      operacion,
      coleccion,
      documentoId: docId,
      usuarioUid: ctx.auth?.uid ?? 'sistema',
      usuarioNombre: ctx.auth?.token?.name ?? 'sistema',
      usuarioEmail: ctx.auth?.token?.email ?? null,
      origen: ctx.auth ? 'app' : 'cloud_function',
      fecha: admin.firestore.FieldValue.serverTimestamp(),
      cambios: operacion === 'UPDATE' ? cambiosEntre(antes, despues) : [],
      valoresAnteriores: antes,
      valoresNuevos: despues,
      expiraEn,
    });
  });
```

---

## 2. Cálculo de diferencias (Dart)

```dart
List<CambioCampo> calcularCambios(
    Map<String, dynamic> antes, Map<String, dynamic> despues) {
  final cambios = <CambioCampo>[];
  final claves = {...antes.keys, ...despues.keys};
  for (final k in claves) {
    if (antes[k] != despues[k]) {
      cambios.add(CambioCampo(campo: k, valorAnterior: antes[k], valorNuevo: despues[k]));
    }
  }
  return cambios;
}
```

---

## 3. Interfaz `AuditoriaRepository` (Dart)

```dart
abstract class AuditoriaRepository {
  Future<List<RegistroAuditoria>> listar({
    String? usuarioUid, String? coleccion, String? operacion,
    DateTime? desde, DateTime? hasta, String? documentoId, String? texto,
    int limite = 100,
  });
  Future<RegistroAuditoria?> obtener(String registroId);
  Future<Uint8List> exportar({ /* mismos filtros */ String formato = 'csv' });
}
```

---

## 4. Reglas de Firestore

```
match /_auditoria/{registroId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId &&
     request.auth.token.roles.hasAny(['administrador','gerente','auditor']));
  allow write: if false;   // solo Cloud Functions (Admin SDK)
}
```

---

## 5. Política de retención (TTL)

```
// En Firestore: definir TTL sobre el campo "expiraEn" de la colección _auditoria
// Al crear cada registro:
expiraEn = fecha + max(6, mesesRetencion) meses
```

---

## 6. Entidades (resumen)

```dart
class RegistroAuditoria {
  String id, empresaId, operacion, coleccion, documentoId;
  String usuarioUid, usuarioNombre;
  String? usuarioEmail, ip;
  String origen;              // app | cloud_function | sistema
  DateTime fecha;
  List<CambioCampo> cambios;  // UPDATE
  Map<String, dynamic>? valoresAnteriores;
  Map<String, dynamic>? valoresNuevos;
  DateTime expiraEn;
}

class CambioCampo {
  String campo;
  dynamic valorAnterior;
  dynamic valorNuevo;
}
```
