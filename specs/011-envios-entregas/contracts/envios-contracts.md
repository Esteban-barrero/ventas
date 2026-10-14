# Contratos: Envíos y Entregas

- **ID:** 011 | **Fecha:** 2026-10-14

---

## 1. Interfaz `EnviosRepository` (Dart)

```dart
abstract class EnviosRepository {
  Future<String> crearDesdeVenta(String ventaId, DatosEnvio datos);
  Future<String> crearDesdePedido(String pedidoId, DatosEnvio datos);
  Future<Envio?> obtener(String envioId);
  Future<List<Envio>> listar({String? estado, String? repartidorUid});
  Future<void> asignarRepartidor(String envioId, String repartidorUid);
  Future<void> cambiarEstado(String envioId, String estado, {
    String? evidenciaUrl, String? firmaUrl, String? observacion,
  });
  Future<void> registrarDevolucion(String envioId, String motivo);
  Future<Envio> rastrear(String envioId);
}
```

---

## 2. Máquina de estados (Dart)

```dart
const _transiciones = <String, List<String>>{
  'preparando':   ['despachado'],
  'despachado':   ['en_transito', 'novedad'],
  'en_transito':  ['en_reparto', 'novedad'],
  'en_reparto':   ['entregado', 'devuelto', 'novedad'],
  'entregado':    [],
  'devuelto':     [],
  'novedad':      ['en_reparto', 'devuelto'],
};

bool transicionValida(String actual, String nuevo) =>
    _transiciones[actual]?.contains(nuevo) ?? false;
```

---

## 3. Cambio de estado (transaccion)

```dart
Future<void> cambiarEstado(String envioId, String estado, {
  String? evidenciaUrl, String? firmaUrl, String? observacion,
}) async {
  await firestore.runTransaction((tx) async {
    final ref = firestore.collection('envios').doc(envioId);
    final e = await tx.get(ref);
    final actual = e['estado'] as String;
    if (!transicionValida(actual, estado)) {
      throw TransicionInvalidaException(actual, estado);
    }

    final esEntrega = estado == 'entregado';
    final requiereEvidencia = e['evidenciaObligatoria'] == true;
    if (esEntrega && requiereEvidencia && evidenciaUrl == null && firmaUrl == null) {
      throw EvidenciaRequeridaException();
    }

    final update = <String, dynamic>{
      'estado': estado,
      'historialEstados': FieldValue.arrayUnion([
        {'estado': estado, 'fecha': DateTime.now().toUtc().toIso8601String(),
         'usuarioUid': sesion.uid, 'observacion': observacion}
      ]),
    };
    if (evidenciaUrl != null) update['evidenciaUrl'] = evidenciaUrl;
    if (firmaUrl != null) update['firmaUrl'] = firmaUrl;
    if (esEntrega) {
      update['fechaEntrega'] = FieldValue.serverTimestamp();
      if (e['contraEntrega'] == true) update['estadoDinero'] = 'entregado';
    }
    tx.update(ref, update);

    // Si es entrega con contra entrega -> crear movimiento de caja (spec 009)
    // Si es devolucion -> reingresar stock (spec 008)
  });
}
```

---

## 4. Registro de evidencia (Storage)

```dart
Future<String> subirEvidencia(String envioId, File imagen) async {
  final path = 'empresas/${sesion.empresaId}/evidencias/${envioId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await storage.ref(path).putFile(imagen);
  return storage.ref(path).getDownloadURL();
}
```

---

## 5. Ubicacion (Maps / Waze)

```dart
void abrirMaps(double lat, double lng) =>
  launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'));

void abrirWaze(double lat, double lng) =>
  launchUrl(Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes'));
```

---

## 6. Cloud Function: notificar cambio de estado

```javascript
exports.notificarEnvio = functions.firestore
  .document('envios/{envioId}')
  .onUpdate(async (change, ctx) => {
    const antes = change.before.data();
    const despues = change.after.data();
    if (antes.estado === despues.estado) return;
    const cfg = await getConfigEmpresa(despues.empresaId);
    const texto = `Tu pedido ${despues.numeroGuia} esta: ${despues.estado}`;
    if (cfg.whatsapp && despues.clienteTelefono) await enviarWhatsApp(despues.clienteTelefono, texto);
    if (cfg.telegram && cfg.telegramChatId) await enviarTelegram(cfg.telegramChatId, texto);
  });
```

---

## 7. Reglas de Firestore

```
match /envios/{envioId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null && (
       esRolInternoDe(resource.data.empresaId) ||
       resource.data.clienteUid == request.auth.uid));
  allow create, update: if esRolInternoDe(request.resource.data.empresaId);
  allow delete: if false;
}
```

---

## 8. Entidades (resumen)

```dart
class Envio {
  String id, empresaId, origenTipo, origenId;
  String? numeroGuia, empresaEnvioId, empresaEnvioNombre;
  String? repartidorUid, repartidorNombre;
  String tipoEntrega;
  Map<String, String> direccion;
  Map<String, double>? gps;
  String? clienteUid, clienteNombre, clienteTelefono;
  double costoEnvio;
  bool contraEntrega;
  double? montoContraEntrega;
  String estadoDinero;   // en_caja | en_transito | en_banco | entregado
  String estado;         // preparando | despachado | en_transito | en_reparto | entregado | devuelto | novedad
  String? evidenciaUrl, firmaUrl, observaciones;
  List<Map<String, dynamic>> historialEstados;
  DateTime fechaCreacion;
}
```
