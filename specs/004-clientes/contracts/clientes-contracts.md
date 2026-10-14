# Contratos: Clientes

- **ID:** 004 | **Fecha:** 2026-10-14

---

## 1. Interfaz `ClientesRepository` (Dart)

```dart
abstract class ClientesRepository {
  Future<List<Cliente>> listar({String? busqueda});
  Future<Cliente?> obtener(String clienteId);
  Future<Cliente?> porCedula(String cedula);
  Future<Cliente?> porUid(String uid);
  Future<String> crear(Cliente cliente);
  Future<void> actualizar(Cliente cliente);
  Future<void> cambiarEstado(String clienteId, String estado);
  Future<List<Venta>> historialCompras(String clienteId);
  Future<List<Pedido>> historialPedidos(String clienteId);
}
```

---

## 2. Validaciones (Dart)

```dart
List<String> validarCliente(Cliente c, List<Cliente> existentes) {
  final errores = <String>[];
  if (c.nombreCompleto.trim().isEmpty) errores.add('Nombre obligatorio');
  if (c.cedula.trim().isEmpty) errores.add('Cédula obligatoria');
  if (c.telefono.trim().isEmpty) errores.add('Teléfono obligatorio');
  if (c.direccion.departamento.isEmpty) errores.add('Departamento obligatorio');
  if (c.direccion.ciudad.isEmpty) errores.add('Ciudad obligatoria');
  if (c.direccion.direccion.trim().isEmpty) errores.add('Dirección obligatoria');
  if (existentes.any((e) => e.cedula == c.cedula && e.id != c.id)) {
    errores.add('Cédula duplicada');
  }
  return errores;
}
```

---

## 3. Ubicación GPS (Dart)

```dart
Future<UbicacionGPS?> capturarUbicacion() async {
  final permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }
  final pos = await Geolocator.getCurrentPosition();
  final dir = await GeocodingPlatform.instance
      .placemarkFromCoordinates(pos.latitude, pos.longitude);
  return UbicacionGPS(
    latitud: pos.latitude,
    longitud: pos.longitude,
    direccionAproximada: dir.isNotEmpty ? dir.first.locality ?? '' : '',
  );
}
```

---

## 4. Abrir en mapas (Dart)

```dart
Future<void> abrirEnMapa(double lat, double lng, {bool waze = false}) async {
  final url = waze
      ? 'https://waze.com/ul?ll=$lat,$lng&navigate=yes'
      : 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
```

---

## 5. Reglas de Firestore

```
match /clientes/{clienteId} {
  allow read: if esSuperAdmin() ||
    (request.auth != null &&
     resource.data.empresaId == request.auth.token.empresaId &&
     (esRolInterno() || resource.data.uid == request.auth.uid));
  allow create: if esRolInternoDe(request.resource.data.empresaId);
  allow update: if esRolInternoDe(resource.data.empresaId) ||
    (resource.data.uid == request.auth.uid
     && sinCambiarEmpresaNiEstado());
  allow delete: if false; // eliminación lógica
}
```

---

## 6. Entidades (resumen)

```dart
class Cliente {
  String id;
  String empresaId;
  String? uid;
  String nombreCompleto;   // obligatorio
  String cedula;           // obligatorio, único por empresa
  String telefono;         // obligatorio
  Direccion direccion;     // obligatorio
  UbicacionGPS? ubicacionGPS;
  String? correo;
  String clasificacion;    // detal | mayorista
  String estado;           // activo | inactivo | moroso
  double? creditoLimite;
  double? creditoSaldo;
}

class Direccion {
  String departamento;
  String ciudad;
  String direccion;
  String? barrio;
  String? referencia;
}

class UbicacionGPS {
  double latitud;
  double longitud;
  String? direccionAproximada;
}
```
