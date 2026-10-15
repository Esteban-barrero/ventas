import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';
import '../../licencia/domain/licencia.dart' show EstadoEmpresa;
import '../domain/empresa.dart';
import '../domain/licencia.dart';
import '../domain/parametros_empresa.dart';
import '../domain/plan.dart';

/// Crea la cuenta de Firebase Auth del Administrador de una empresa **desde el
/// cliente**, sin cerrar la sesión del Super Admin.
///
/// Se usa mientras la Cloud Function `crearEmpresa` (Admin SDK, ADR-001) no
/// esté desplegada. La técnica es crear una instancia **secundaria** de
/// Firebase (`Firebase.initializeApp(name: ...)`) con su propio [FirebaseAuth]:
/// la sesión del Super Admin vive en la instancia principal y no se toca.
class CreadorAdminLocal {
  CreadorAdminLocal({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  /// Crea la cuenta del administrador y devuelve su UID.
  ///
  /// Se genera una contraseña temporal aleatoria y se envía al correo un aviso
  /// para que el administrador la restablezca (RN-04).
  Future<String> crearCuentaAdmin({
    required String email,
    required String nombre,
  }) async {
    FirebaseApp? appSecundaria;
    try {
      appSecundaria = await Firebase.initializeApp(
        name: 'creador-usuarios-${DateTime.now().microsecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final authSecundaria = FirebaseAuth.instanceFor(app: appSecundaria);
      final credencial = await authSecundaria.createUserWithEmailAndPassword(
        email: email,
        password: _passwordTemporal(),
      );

      final user = credencial.user;
      if (user == null) {
        throw StateError('No se pudo crear la cuenta del administrador.');
      }

      try {
        await user.updateDisplayName(nombre);
      } catch (_) {
        // El nombre también queda en el perfil de Firestore.
      }

      // Aviso para que el administrador fije su propia contraseña.
      try {
        await authSecundaria.sendPasswordResetEmail(email: email);
      } catch (_) {
        // Si el envío falla, el Super Admin puede reenviarlo luego.
      }

      return user.uid;
    } finally {
      // Al borrar la app secundaria se cierra su sesión y la del Super Admin
      // (instancia principal) queda intacta.
      if (appSecundaria != null) {
        try {
          await appSecundaria.delete();
        } catch (_) {
          // La app secundaria se libera igual al terminar el proceso.
        }
      }
    }
  }

  /// Escribe el perfil del administrador recién creado (`usuarios/{uid}`).
  Future<void> guardarPerfilAdmin({
    required String uid,
    required String email,
    required String nombre,
    required String empresaId,
    String? autor,
  }) async {
    await _db.collection('usuarios').doc(uid).set(<String, dynamic>{
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'telefono': '',
      'empresaId': empresaId,
      'roles': const <String>['administrador'],
      'activo': true,
      'fechaCreacion': DateTime.now().toUtc().toIso8601String(),
      'creadoPor': autor,
    });
  }

  /// Crea/actualiza el documento de la empresa y sus parámetros por defecto
  /// (RF-04). Se llama primero con `creacion_incompleta` y luego con el estado
  /// final, de modo que un fallo deje una empresa recuperable (caso borde).
  Future<void> guardarEmpresa({
    required String empresaId,
    required DatosEmpresa datos,
    required Licencia licencia,
    required String planId,
    required EstadoEmpresa estado,
    String adminUid = '',
    required String autor,
    ParametrosEmpresa parametros = ParametrosEmpresa.porDefecto,
    LimitesPlan limites = const LimitesPlan(),
    String logoUrl = '',
    int logoAncho = 0,
    int logoAlto = 0,
  }) async {
    final empresa = Empresa(
      id: empresaId,
      nombre: datos.nombre,
      nit: datos.nit,
      correoNotificacion: datos.correoNotificacion,
      telefono: datos.telefono,
      contactoProveedor: datos.contactoProveedor,
      logo: logoUrl,
      logoAncho: logoAncho,
      logoAlto: logoAlto,
      adminId: adminUid,
      estado: estado,
      fechaCreacion: DateTime.now(),
      creadaPor: autor,
      planId: planId,
      licencia: licencia,
      parametros: parametros,
      limites: limites,
    );

    await _db
        .collection('empresas')
        .doc(empresaId)
        .set(empresa.toMap(ahora: DateTime.now()));
  }

  static String _passwordTemporal() {
    const caracteres =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    return List<String>.generate(
      16,
      (_) => caracteres[random.nextInt(caracteres.length)],
    ).join();
  }
}
