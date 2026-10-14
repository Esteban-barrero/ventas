# Contratos: Logs de Errores

- **ID:** 013 | **Fecha:** 2026-10-14

---

## 1. `ErrorLogger` (Dart)

```dart
class ErrorLogger {
  bool _registrando = false;   // proteccion contra bucles

  Future<void> registrar(
    Object error,
    StackTrace? stack, {
    String modulo = 'desconocido',
    String opcion = '',
    String accion = '',
    String severidad = 'error',
    Map<String, dynamic>? contexto,
  }) async {
    if (_registrando) return;   // evita recursion
    _registrando = true;
    try {
      final log = ErrorLog(
        empresaId: sesion.empresaId ?? 'sistema',
        modulo: modulo,
        opcion: opcion,
        accion: accion,
        usuarioUid: sesion.uid ?? 'anonimo',
        usuarioNombre: sesion.usuarioNombre,
        usuarioRol: sesion.rolActivo,
        fecha: DateTime.now().toUtc(),
        archivo: _archivo(stack),
        linea: _linea(stack),
        codigo: error.runtimeType.toString(),
        descripcion: enmascarar(error.toString()),
        stackTrace: enmascarar(stack?.toString() ?? ''),
        severidad: severidad,
        plataforma: _plataforma(),
        appVersion: _appVersion(),
        osVersion: _osVersion(),
        huella: fingerprint(error.runtimeType.toString(), _archivo(stack), _linea(stack)),
        contexto: contexto,
      );
      await logsRepo.guardar(log);   // Firestore o cola offline
    } finally {
      _registrando = false;
    }
  }
}
```

---

## 2. Inicializacion global (main.dart)

```dart
void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (detalles) =>
        errorLogger.registrar(detalles.exception, detalles.stack,
            modulo: 'app', accion: 'render');
    PlatformDispatcher.instance.onError = (error, stack) {
      errorLogger.registrar(error, stack, modulo: 'app', accion: 'async');
      return true;
    };
    runApp(const App());
  }, (error, stack) =>
      errorLogger.registrar(error, stack, modulo: 'app', accion: 'zona'));
}
```

---

## 3. Extraccion de archivo / linea (Dart)

```dart
final _frameApp = RegExp(r'\((?<archivo>[^)]+\.dart):(?<linea>\d+):\d+\)');

String _archivo(StackTrace? st) =>
    st == null ? '' : (_frameApp.firstMatch(st.toString())?.namedGroup('archivo') ?? '');

int _linea(StackTrace? st) =>
    st == null ? 0 : int.tryParse(_frameApp.firstMatch(st.toString())?.namedGroup('linea') ?? '') ?? 0;
```

---

## 4. Enmascarado y huella

```dart
final _sensibles = [RegExp(r'password\S*', caseSensitive: false),
                    RegExp(r'token\S*', caseSensitive: false),
                    RegExp(r'bearer\s+\S+', caseSensitive: false)];

String enmascarar(String texto) {
  var t = texto;
  for (final r in _sensibles) { t = t.replaceAll(r, '***'); }
  return t;
}

String fingerprint(String codigo, String archivo, int linea) {
  final hash = _md5.convert(utf8.encode('$codigo|$archivo|$linea')).toString();
  return hash.substring(0, 8);
}
```

---

## 5. Wrapper de errores en Cloud Functions

```typescript
export function conLogs<T>(nombre: string, handler: (data: any, ctx: any) => Promise<T>) {
  return async (data: any, ctx: any) => {
    try {
      return await handler(data, ctx);
    } catch (e: any) {
      await admin.firestore().collection('logs_errores').add({
        empresaId: ctx?.auth?.token?.empresaId ?? 'sistema',
        modulo: 'cloud_functions',
        opcion: nombre,
        accion: ctx?.eventType ?? 'ejecucion',
        usuarioUid: ctx?.auth?.uid ?? 'sistema',
        fecha: admin.firestore.FieldValue.serverTimestamp(),
        archivo: e?.stack?.split('\n')[1]?.trim() ?? '',
        linea: 0,
        codigo: e?.name ?? 'Error',
        descripcion: String(e?.message ?? e),
        stackTrace: String(e?.stack ?? ''),
        severidad: 'error',
        estado: 'nuevo',
      });
      throw e;
    }
  };
}
```

---

## 6. Interfaz `LogsRepository` (Dart)

```dart
abstract class LogsRepository {
  Future<void> guardar(ErrorLog log);
  Future<List<ErrorLog>> listar({
    String? modulo, String? severidad, String? estado,
    String? usuarioUid, DateTime? desde, DateTime? hasta,
    String? codigo, String? texto, int limite = 100,
  });
  Future<ErrorLog?> obtener(String logId);
  Future<void> marcarEstado(String logId, String estado);
  Future<Uint8List> exportar({ /* filtros */ String formato = 'csv' });
}
```

---

## 7. Reglas de Firestore

```
match /logs_errores/{logId} {
  allow read: if esDeveloper();
  allow create: if request.auth != null;   // o validacion para errores pre-login
  allow update: if esDeveloper();          // solo estado (reconocido/resuelto)
  allow delete: if false;
}
```

---

## 8. Entidad (resumen)

```dart
class ErrorLog {
  String id, empresaId, modulo, opcion, accion;
  String usuarioUid, usuarioNombre, usuarioRol;
  DateTime fecha;
  String archivo;
  int linea;
  String codigo, descripcion, stackTrace;
  String severidad;      // info | warning | error | fatal
  String plataforma, appVersion, osVersion;
  String huella;
  int ocurrencias;
  String estado;         // nuevo | reconocido | resuelto
}
```
