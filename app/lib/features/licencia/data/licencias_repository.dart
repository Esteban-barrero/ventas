import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/firebase/errores.dart';
import '../../auth/data/cache_sesion.dart';
import '../domain/licencia.dart';

/// Valida la licencia de una empresa (spec 001, T012 / T014).
///
/// Flujo:
/// 1. Llama a la Cloud Function `validarLicencia` (autoritativa, verifica
///    permisos en el servidor).
/// 2. Si la funcion no esta desplegada o falla, valida localmente leyendo
///    `empresas/{empresaId}` con la misma logica de negocio.
/// 3. Si no hay conexion, recalcula la licencia con la copia del documento de
///    empresa guardada en el dispositivo.
///
/// La validacion local existe para poder operar mientras las Cloud Functions
/// no esten desplegadas (requieren plan Blaze). Al desplegarlas, el paso 1
/// pasa a mandar.
class LicenciasRepository {
  LicenciasRepository({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    CacheSesion? cache,
  })  : _functionsOverride = functions,
        _firestoreOverride = firestore,
        _cache = cache ?? CacheSesion();

  final FirebaseFunctions? _functionsOverride;
  final FirebaseFirestore? _firestoreOverride;
  final CacheSesion _cache;

  // Se resuelven de forma perezosa para poder construir el repositorio en
  // pruebas sin inicializar Firebase.
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;
  FirebaseFirestore get _db =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Valida la licencia de la empresa y decide si se permite el ingreso.
  Future<ResultadoLicencia> validar(String empresaId) async {
    // Refresca el ID token antes de llamar a la funcion: esta autoriza segun
    // los custom claims `empresaId`/`roles` del token, y un token viejo (por
    // ejemplo si los claims se fijaron despues del ultimo ingreso) haria que la
    // funcion respondiera 403. Mismo criterio que al subir el logo (spec 002).
    try {
      await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
    } catch (_) {
      // Si no se puede refrescar, se intenta validar de todos modos.
    }

    try {
      final callable = _functions.httpsCallable('validarLicencia');
      final respuesta = await callable.call(<String, dynamic>{
        'empresaId': empresaId,
      });
      final data = Map<String, dynamic>.from(respuesta.data as Map);
      return _decidir(EstadoLicencia.desdeFuncion(data));
    } on FirebaseFunctionsException catch (e) {
      // La funcion si existe y rechazo la peticion: respetamos el motivo.
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        return const LicenciaNoDisponible(
          'No tienes acceso a la licencia de esta empresa.',
        );
      }
      return _validarLocalmente(empresaId);
    } catch (_) {
      // Funcion no desplegada, sin conexion, etc.
      return _validarLocalmente(empresaId);
    }
  }

  Future<ResultadoLicencia> _validarLocalmente(String empresaId) async {
    try {
      final doc = await _db.collection('empresas').doc(empresaId).get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        return const LicenciaNoDisponible(
          'La empresa no tiene licencia configurada.',
        );
      }
      // Se guarda una copia para poder validar sin conexion la proxima vez.
      await _cache.guardarEmpresa(empresaId, data);
      return _decidir(EstadoLicencia.desdeEmpresa(data));
    } on FirebaseException catch (e) {
      if (esErrorDeRed(e)) return _desdeCache(empresaId);
      return const LicenciaNoDisponible('No se pudo verificar la licencia.');
    } catch (_) {
      return _desdeCache(empresaId);
    }
  }

  /// Recalcula la licencia con el documento de empresa guardado en el
  /// dispositivo. Se usa la fecha actual, de modo que si la licencia vencio
  /// mientras el equipo estaba sin conexion, el ingreso igualmente se bloquea.
  Future<ResultadoLicencia> _desdeCache(String empresaId) async {
    final guardado = await _cache.leerEmpresa(empresaId);
    if (guardado == null) {
      return const LicenciaNoDisponible(
        'No hay conexion y no se guardo la licencia de esta empresa.',
      );
    }
    return _decidir(EstadoLicencia.desdeEmpresa(guardado), desdeCache: true);
  }

  ResultadoLicencia _decidir(EstadoLicencia estado, {bool desdeCache = false}) =>
      estado.vigente
          ? LicenciaVigente(estado, desdeCache: desdeCache)
          : LicenciaBloqueada(estado, desdeCache: desdeCache);
}
