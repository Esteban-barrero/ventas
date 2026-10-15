import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/licencia.dart';

/// Valida la licencia de una empresa (spec 001, T012).
///
/// Flujo:
/// 1. Llama a la Cloud Function `validarLicencia` (autoritativa, verifica
///    permisos en el servidor).
/// 2. Si la funcion no esta desplegada o falla, valida localmente leyendo
///    `empresas/{empresaId}` con la misma logica de negocio.
///
/// La validacion local existe para poder operar mientras las Cloud Functions
/// no esten desplegadas (requieren plan Blaze). Al desplegarlas, el paso 1
/// pasa a mandar.
class LicenciasRepository {
  LicenciasRepository({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _functionsOverride = functions,
        _firestoreOverride = firestore;

  final FirebaseFunctions? _functionsOverride;
  final FirebaseFirestore? _firestoreOverride;

  // Se resuelven de forma perezosa para poder construir el repositorio en
  // pruebas sin inicializar Firebase.
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;
  FirebaseFirestore get _db =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Valida la licencia de la empresa y decide si se permite el ingreso.
  Future<ResultadoLicencia> validar(String empresaId) async {
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
      return _decidir(EstadoLicencia.desdeEmpresa(data));
    } catch (_) {
      return const LicenciaNoDisponible('No se pudo verificar la licencia.');
    }
  }

  ResultadoLicencia _decidir(EstadoLicencia estado) =>
      estado.vigente ? LicenciaVigente(estado) : LicenciaBloqueada(estado);
}
