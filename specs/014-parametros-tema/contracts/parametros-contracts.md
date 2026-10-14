# Contratos: Parámetros Generales y Tema

- **ID:** 014 | **Fecha:** 2026-10-14

---

## 1. Interfaz `ParametrosRepository` (Dart)

```dart
abstract class ParametrosRepository {
  Future<Parametros> obtener(String empresaId);
  Future<void> guardar(Parametros parametros);
}
```

---

## 2. Interfaz `PaletasRepository` (Dart)

```dart
abstract class PaletasRepository {
  Future<List<Paleta>> listar();
  Future<Paleta?> obtener(String paletaId);
  Future<String> crear(Paleta paleta);
  Future<void> editar(Paleta paleta);
  Future<String> duplicar(String paletaId, String nuevoNombre);
  Future<void> eliminar(String paletaId);
  Future<void> activar(String paletaId);          // desactiva las demas
  Stream<Paleta?> paletaActiva$();                // cambio en tiempo real
}
```

---

## 3. Aplicación del tema en tiempo real (Dart)

```dart
ThemeData buildTheme(Paleta? p, Brightness b) {
  final c = p?.colores ?? Paleta.defaultColores;
  final scheme = ColorScheme(
    brightness: b,
    primary: hex(c['primario']!),
    secondary: hex(c['secundario']!),
    tertiary: hex(c['acento']!),
    surface: hex(c['superficie']!),
    error: hex(c['error']!),
    onPrimary: hex(c['textoInverso']!),
    onSurface: hex(c['texto']!),
  );
  return ThemeData(useMaterial3: true, colorScheme: scheme);
}

// En el arbol de widgets:
final paleta = ref.watch(paletaActivaProvider);   // StreamProvider
MaterialApp(
  theme: buildTheme(paleta.value, Brightness.light),
  darkTheme: buildTheme(paleta.value, Brightness.dark),
  themeMode: modoTema,
  home: HomePage(),
);
```

---

## 4. Validación del logo

```dart
Future<String> subirLogo(File archivo) async {
  final bytes = await archivo.length();
  if (bytes > 500 * 1024) throw LogoMuyPesadoException();

  final decoded = await decodeImageFromList(await archivo.readAsBytes());
  if (decoded.width != 512 || decoded.height != 512) {
    // o validar un minimo: width >= 128, height >= 128
    throw DimensionInvalidaException(decoded.width, decoded.height);
  }

  final path = 'empresas/${sesion.empresaId}/logo.png';
  await storage.ref(path).putFile(archivo);
  return storage.ref(path).getDownloadURL();
}
```

---

## 5. Validación de licencia

```dart
Future<bool> licenciaVigente(String empresaId) async {
  final lic = await licenciasRepo.obtener(empresaId);
  if (lic == null) return false;
  final ahora = DateTime.now().toUtc();
  if (ahora.isAfter(lic.fechaFin)) {
    throw LicenciaVencidaException(lic.contactoProveedor);
  }
  return true;   // el bloqueo se aplica en el arranque/ingreso
}
```

---

## 6. Cloud Function programada: avisos de vencimiento

```typescript
export const verificarLicenciasYNotificar = functions.pubsub
  .schedule('every day 07:00')
  .timeZone('America/Bogota')
  .onRun(async () => {
    const ahora = Date.now();
    const snap = await admin.firestore().collection('licencias')
      .where('estado', 'in', ['activa', 'por_vencer']).get();

    for (const doc of snap.docs) {
      const lic = doc.data();
      const fin = lic.fechaFin.toMillis();
      const dias = Math.floor((fin - ahora) / 86400000);
      const params = (await admin.firestore().collection('parametros').doc(doc.id).get()).data() || {};
      const diasAviso = params.diasAvisoVencimiento ?? 5;

      if (dias < 0) {
        await doc.ref.update({ estado: 'vencida' });
      } else if (dias <= diasAviso) {
        if (!lic.avisoEnviado) {
          await enviarCorreoAviso(doc.id, dias, params);
          await crearNotificacionInApp(doc.id, dias);
          await doc.ref.update({
            estado: 'por_vencer',
            avisoEnviado: true,
            fechaUltimoAviso: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }
    }
  });
```

---

## 7. Reglas de Firestore

```
match /parametros/{empresaId} {
  allow read: if request.auth.token.empresaId == empresaId;
  allow write: if esAdminDeEmpresa(empresaId);
}

match /paletas/{paletaId} {
  allow read: if request.auth.token.empresaId == resource.data.empresaId;
  allow write: if esAdminDeEmpresa(request.resource.data.empresaId);
}

match /licencias/{empresaId} {
  allow read: if request.auth.token.empresaId == empresaId || esSuperAdmin();
  allow write: if esSuperAdmin();
}
```

---

## 8. Entidades (resumen)

```dart
class Parametros {
  String empresaId, nombreEmpresa, moneda, simboloMoneda, paletaActivaId;
  double impuestoPorcentaje, tasaInteresCredito, costoEnvioGeneral;
  bool aplicaImpuesto;
  int diasMora, logoAnchoPx, logoAltoPx, diasAvisoVencimiento;
  String? logoUrl, whatsappNumero, telegramChatId, telegramToken, contactoProveedor;
  String modoTema; // claro | oscuro | sistema
}

class Paleta {
  String id, empresaId, nombre;
  bool esBase, activa;
  Map<String, String> colores;
}

class Licencia {
  String empresaId, plan;   // mensual | anual
  DateTime fechaInicio, fechaFin;
  String estado;            // activa | por_vencer | vencida | suspendida
  bool avisoEnviado;
}
```
