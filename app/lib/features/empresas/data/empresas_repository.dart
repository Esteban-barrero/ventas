import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auditoria/data/auditoria_repository.dart';
import '../../auditoria/domain/auditoria.dart';
import '../../licencia/domain/licencia.dart' show EstadoEmpresa;
import '../domain/empresa.dart';
import '../domain/licencia.dart';
import '../domain/parametros_empresa.dart';
import '../domain/plan.dart';
import '../domain/resumen_empresas.dart';
import 'almacenamiento_repository.dart';
import 'crear_empresa_local.dart';

/// Resultado de crear una empresa (spec 002, RF-01..RF-05).
class ResultadoCrearEmpresa {
  const ResultadoCrearEmpresa({
    this.empresa,
    this.adminUid = '',
    this.desdeRespaldo = false,
    this.aviso,
  });

  final Empresa? empresa;
  final String adminUid;

  /// `true` si la empresa y su administrador se crearon con el respaldo local
  /// (la Cloud Function `crearEmpresa` todavía no está desplegada).
  final bool desdeRespaldo;

  /// Mensaje adicional para mostrar al Super Admin (por ejemplo, avisos).
  final String? aviso;
}

/// Acceso a la colección `empresas`. Ver spec 002.
///
/// La creación pasa primero por la Cloud Function `crearEmpresa` (Admin SDK,
/// ADR-001). Mientras esa función no esté desplegada, se usa un **respaldo
/// local** que crea la cuenta del administrador con una instancia secundaria de
/// Firebase (sin cerrar la sesión del Super Admin).
class EmpresasRepository {
  EmpresasRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
    AuditoriaRepository? auditoria,
    AlmacenamientoRepository? almacenamiento,
    CreadorAdminLocal? creadorLocal,
  })  : _firestoreOverride = firestore,
        _functionsOverride = functions,
        _authOverride = auth,
        _auditoria = auditoria ?? AuditoriaRepository(),
        _almacenamiento = almacenamiento ?? AlmacenamientoRepository(),
        _creadorLocal = creadorLocal ?? CreadorAdminLocal(firestore: firestore);

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseFunctions? _functionsOverride;
  final FirebaseAuth? _authOverride;
  final AuditoriaRepository _auditoria;
  final AlmacenamientoRepository _almacenamiento;
  final CreadorAdminLocal _creadorLocal;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _coleccion =>
      _db.collection('empresas');

  String get _autor => _auth.currentUser?.uid ?? '';

  // ───────────────────────────── Lectura ─────────────────────────────

  /// Lista las empresas (más recientes primero).
  Future<List<Empresa>> listar({bool incluirEliminadas = false}) async {
    final snap = await _coleccion.get();
    final lista = snap.docs
        .map((DocumentSnapshot<Map<String, dynamic>> d) =>
            Empresa.fromMap(d.id, d.data()!))
        .where((Empresa e) => incluirEliminadas || e.vigente)
        .toList();
    lista.sort((Empresa a, Empresa b) =>
        (b.fechaCreacion ?? DateTime(0)).compareTo(a.fechaCreacion ?? DateTime(0)));
    return lista;
  }

  /// Escucha la colección en tiempo real.
  Stream<List<Empresa>> escuchar({bool incluirEliminadas = false}) {
    return _coleccion.snapshots().map((QuerySnapshot<Map<String, dynamic>> snap) {
      final lista = snap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              Empresa.fromMap(d.id, d.data()))
          .where((Empresa e) => incluirEliminadas || e.vigente)
          .toList();
      lista.sort((Empresa a, Empresa b) => (b.fechaCreacion ?? DateTime(0))
          .compareTo(a.fechaCreacion ?? DateTime(0)));
      return lista;
    });
  }

  /// Obtiene una empresa por su id.
  Future<Empresa?> obtener(String empresaId) async {
    final doc = await _coleccion.doc(empresaId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Empresa.fromMap(doc.id, doc.data()!);
  }

  /// Resumen para el tablero de vencimientos (RF-10).
  Future<ResumenEmpresas> resumen({DateTime? ahora}) async {
    final empresas = await listar(incluirEliminadas: true);
    return ResumenEmpresas.calcular(empresas, ahora ?? DateTime.now());
  }

  // ───────────────────────────── Alta ─────────────────────────────

  /// Crea una empresa con su licencia y su administrador (RF-01..RF-05).
  Future<ResultadoCrearEmpresa> crear(
    DatosEmpresa datos, {
    required Licencia licencia,
    String planId = 'gratis',
    Uint8List? logo,
    String logoExtension = 'png',
    int logoAncho = 0,
    int logoAlto = 0,
  }) async {
    final error = datos.validar();
    if (error != null) throw ArgumentError(error);
    if (!licencia.fechasCoherentes) {
      throw ArgumentError('La fecha de fin no puede ser anterior a la de inicio.');
    }

    // El id se genera aquí para poder subir el logo antes de crear el documento.
    final empresaId = _coleccion.doc().id;

    var logoUrl = '';
    if (logo != null && logo.isNotEmpty) {
      logoUrl = await _almacenamiento.subirLogo(
        empresaId,
        logo,
        extension: logoExtension,
      );
    }

    // 1) Cloud Function (autoritativa).
    try {
      final callable = _functions.httpsCallable('crearEmpresa');
      final respuesta = await callable.call(<String, dynamic>{
        ...datos.aSolicitud(licencia: licencia, planId: planId),
        'empresaId': empresaId,
        'logo': logoUrl,
        'logoAncho': logoAncho,
        'logoAlto': logoAlto,
      });
      final data = Map<String, dynamic>.from(respuesta.data as Map);
      final id = (data['empresaId'] as String?) ?? empresaId;
      return ResultadoCrearEmpresa(
        empresa: await obtener(id),
        adminUid: (data['adminUid'] as String?) ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      // La función existe y rechazó la petición: se respeta el motivo.
      if (e.code == 'permission-denied' ||
          e.code == 'unauthenticated' ||
          e.code == 'invalid-argument' ||
          e.code == 'already-exists') {
        rethrow;
      }
      // No desplegada / sin conexión -> respaldo local.
    } catch (_) {
      // Sin conexión u otro fallo de la llamada -> respaldo local.
    }

    // 2) Respaldo local.
    return _crearLocal(
      empresaId: empresaId,
      datos: datos,
      licencia: licencia,
      planId: planId,
      logoUrl: logoUrl,
      logoAncho: logoAncho,
      logoAlto: logoAlto,
    );
  }

  Future<ResultadoCrearEmpresa> _crearLocal({
    required String empresaId,
    required DatosEmpresa datos,
    required Licencia licencia,
    required String planId,
    required String logoUrl,
    required int logoAncho,
    required int logoAlto,
  }) async {
    final autor = _autor;
    final limites = Plan.porDefectoConId(planId)?.limites ?? const LimitesPlan();

    // a) La empresa nace en `creacion_incompleta` para que un fallo posterior
    //    (por ejemplo, al crear el administrador) sea recuperable.
    await _creadorLocal.guardarEmpresa(
      empresaId: empresaId,
      datos: datos,
      licencia: licencia,
      planId: planId,
      estado: EstadoEmpresa.creacionIncompleta,
      autor: autor,
      limites: limites,
      logoUrl: logoUrl,
      logoAncho: logoAncho,
      logoAlto: logoAlto,
    );

    final nombreAdmin =
        datos.adminNombre.isEmpty ? datos.nombre : datos.adminNombre;

    // b) Cuenta del administrador.
    final adminUid = await _creadorLocal.crearCuentaAdmin(
      email: datos.adminEmail,
      nombre: nombreAdmin,
    );

    await _creadorLocal.guardarPerfilAdmin(
      uid: adminUid,
      email: datos.adminEmail,
      nombre: nombreAdmin,
      empresaId: empresaId,
      autor: autor,
    );

    // c) Estado final de la empresa.
    final estadoFinal = licencia.tipo == TipoLicencia.gratis
        ? EstadoEmpresa.prueba
        : EstadoEmpresa.activa;

    await _creadorLocal.guardarEmpresa(
      empresaId: empresaId,
      datos: datos,
      licencia: licencia,
      planId: planId,
      estado: estadoFinal,
      adminUid: adminUid,
      autor: autor,
      limites: limites,
      logoUrl: logoUrl,
      logoAncho: logoAncho,
      logoAlto: logoAlto,
    );

    // d) Auditoría (RF: trazabilidad de altas).
    await _auditoria.registrarEvento(
      empresaId: empresaId,
      operacion: OperacionAuditoria.insert,
      tabla: 'empresas',
      documentoId: empresaId,
      datos: <String, dynamic>{
        'nombre': datos.nombre,
        'nit': datos.nit,
        'plan': planId,
        'estado': estadoFinal.id,
        'adminId': adminUid,
        'adminEmail': datos.adminEmail,
      },
      autor: autor,
    );

    return ResultadoCrearEmpresa(
      empresa: await obtener(empresaId),
      adminUid: adminUid,
      desdeRespaldo: true,
      aviso: 'La cuenta del administrador se creó y se envió un correo a '
          '${datos.adminEmail} para que defina su contraseña.',
    );
  }

  // ───────────────────────────── Edición ─────────────────────────────

  /// Actualiza campos de la empresa y registra los cambios en la auditoría.
  Future<void> actualizar(
    String empresaId,
    Map<String, dynamic> cambios, {
    String? autor,
  }) async {
    if (cambios.isEmpty) return;

    final ref = _coleccion.doc(empresaId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('La empresa ya no existe.');
    }
    final antes = snap.data() ?? const <String, dynamic>{};

    await ref.update(cambios);

    final antesParcial = <String, dynamic>{
      for (final clave in cambios.keys) clave: antes[clave],
    };
    await _auditoria.registrarCambios(
      empresaId: empresaId,
      tabla: 'empresas',
      documentoId: empresaId,
      antes: antesParcial,
      despues: cambios,
      autor: autor ?? _autor,
    );
  }

  /// Guarda los datos generales de la empresa (RF-07).
  Future<void> editarDatos(
    Empresa empresa, {
    required String nombre,
    required String nit,
    required String correoNotificacion,
    required String telefono,
    required String contactoProveedor,
  }) async {
    await actualizar(empresa.id, <String, dynamic>{
      'nombre': nombre,
      'nit': nit,
      'correoNotificacion': correoNotificacion,
      'telefono': telefono,
      'contactoProveedor': contactoProveedor,
    });
  }

  /// Renueva / extiende la licencia y la agrega al historial (RF-09, RF-12).
  Future<void> renovar(
    String empresaId, {
    required Licencia licencia,
    String? nota,
  }) async {
    if (!licencia.fechasCoherentes) {
      throw ArgumentError('La fecha de fin no puede ser anterior a la de inicio.');
    }

    final empresa = await obtener(empresaId);
    if (empresa == null) throw StateError('La empresa ya no existe.');

    final pago = PagoLicencia(
      fecha: DateTime.now(),
      valor: licencia.valorPagado,
      periodoInicio: licencia.fechaInicio,
      periodoFin: licencia.fechaFin,
      nota: nota ?? 'Renovación',
    );

    final actualizada = licencia.copyWith(
      historialPagos: <PagoLicencia>[...empresa.licencia.historialPagos, pago],
    );

    await actualizar(empresaId, <String, dynamic>{
      'licencia': actualizada.toMap(
        ahora: DateTime.now(),
        estadoEmpresa: empresa.estado,
      ),
    });
  }

  /// Cambia el estado de la empresa (RF-08): activar, suspender, reactivar,
  /// eliminar lógicamente (RN-08).
  Future<void> cambiarEstado(String empresaId, EstadoEmpresa estado) async {
    final empresa = await obtener(empresaId);
    if (empresa == null) throw StateError('La empresa ya no existe.');

    await actualizar(empresaId, <String, dynamic>{
      'estado': estado.id,
      'licencia': empresa.licencia.toMap(
        ahora: DateTime.now(),
        estadoEmpresa: estado,
      ),
    });
  }

  /// Elimina la empresa de forma lógica (RN-08).
  Future<void> eliminar(String empresaId) =>
      cambiarEstado(empresaId, EstadoEmpresa.eliminada);

  /// Actualiza los parámetros de configuración de la empresa (RF-04).
  Future<void> actualizarParametros(
    Empresa empresa,
    ParametrosEmpresa parametros,
  ) async {
    await actualizar(empresa.id, <String, dynamic>{
      'parametros': parametros.toMap(),
    });
  }

  // ───────────────────────────── Logo ─────────────────────────────

  /// Sube el logo de la empresa y guarda su ruta y dimensiones (RF-06, ADR-004).
  Future<String> subirLogo(
    String empresaId,
    Uint8List bytes, {
    String extension = 'png',
    int ancho = 0,
    int alto = 0,
  }) async {
    final url = await _almacenamiento.subirLogo(
      empresaId,
      bytes,
      extension: extension,
    );

    await actualizar(empresaId, <String, dynamic>{
      'logo': url,
      'logoAncho': ancho,
      'logoAlto': alto,
    });

    return url;
  }

  /// Borra el logo de la empresa.
  Future<void> borrarLogo(String empresaId) async {
    await _almacenamiento.borrarLogo(empresaId);
    await actualizar(empresaId, <String, dynamic>{
      'logo': '',
      'logoAncho': 0,
      'logoAlto': 0,
    });
  }
}
