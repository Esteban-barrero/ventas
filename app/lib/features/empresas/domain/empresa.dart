/// Entidad Empresa (tenant) del aplicativo. Ver spec 002.
///
/// Colección `empresas/{empresaId}`. Cada empresa es un cliente independiente:
/// sus datos se aíslan con el campo `empresaId` presente en todas las demás
/// colecciones (RN-01, RN-02).
library;

import '../../../core/validacion/correo.dart';
import '../../licencia/domain/licencia.dart' show EstadoEmpresa;
import 'licencia.dart';
import 'parametros_empresa.dart';
import 'plan.dart';

/// Una empresa (cliente) del aplicativo.
class Empresa {
  const Empresa({
    required this.id,
    required this.nombre,
    this.nit = '',
    this.correoNotificacion = '',
    this.telefono = '',
    this.contactoProveedor = '',
    this.logo = '',
    this.logoAncho = 0,
    this.logoAlto = 0,
    this.adminId = '',
    this.estado = EstadoEmpresa.activa,
    this.fechaCreacion,
    this.creadaPor = '',
    this.planId = 'gratis',
    this.licencia = const Licencia(),
    this.parametros = const ParametrosEmpresa(),
    this.limites = const LimitesPlan(),
  });

  final String id;
  final String nombre;

  /// NIT / RIF (único entre empresas).
  final String nit;

  /// Correo que recibe los avisos de licencia.
  final String correoNotificacion;
  final String telefono;

  /// Contacto de quien vendió el aplicativo a esta empresa.
  final String contactoProveedor;

  /// Ruta del logo en Storage (`empresas/{id}/logo.png`).
  final String logo;
  final int logoAncho;
  final int logoAlto;

  /// UID del usuario Administrador de la empresa (RF-03).
  final String adminId;

  final EstadoEmpresa estado;
  final DateTime? fechaCreacion;

  /// UID del Super Admin que creó la empresa.
  final String creadaPor;

  final String planId;
  final Licencia licencia;
  final ParametrosEmpresa parametros;

  /// Límites copiados del plan al crear la empresa (RF-11).
  final LimitesPlan limites;

  /// `true` si la empresa tiene logo cargado.
  bool get tieneLogo => logo.trim().isNotEmpty;

  /// `true` si la empresa es visible en el tablero (no eliminada).
  bool get vigente => estado != EstadoEmpresa.eliminada;

  /// Estado derivado de la licencia (para el tablero, RF-10).
  EstadoLicenciaNegocio estadoLicencia(DateTime ahora) =>
      licencia.calcularEstado(ahora, estadoEmpresa: estado);

  Empresa copyWith({
    String? nombre,
    String? nit,
    String? correoNotificacion,
    String? telefono,
    String? contactoProveedor,
    String? logo,
    int? logoAncho,
    int? logoAlto,
    String? adminId,
    EstadoEmpresa? estado,
    String? planId,
    Licencia? licencia,
    ParametrosEmpresa? parametros,
    LimitesPlan? limites,
  }) {
    return Empresa(
      id: id,
      nombre: nombre ?? this.nombre,
      nit: nit ?? this.nit,
      correoNotificacion: correoNotificacion ?? this.correoNotificacion,
      telefono: telefono ?? this.telefono,
      contactoProveedor: contactoProveedor ?? this.contactoProveedor,
      logo: logo ?? this.logo,
      logoAncho: logoAncho ?? this.logoAncho,
      logoAlto: logoAlto ?? this.logoAlto,
      adminId: adminId ?? this.adminId,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion,
      creadaPor: creadaPor,
      planId: planId ?? this.planId,
      licencia: licencia ?? this.licencia,
      parametros: parametros ?? this.parametros,
      limites: limites ?? this.limites,
    );
  }

  Map<String, dynamic> toMap({DateTime? ahora}) => <String, dynamic>{
        'id': id,
        'nombre': nombre,
        'nit': nit,
        'correoNotificacion': correoNotificacion,
        'telefono': telefono,
        'contactoProveedor': contactoProveedor,
        'logo': logo,
        'logoAncho': logoAncho,
        'logoAlto': logoAlto,
        'adminId': adminId,
        'estado': estado.id,
        'fechaCreacion': (fechaCreacion ?? DateTime.now()).toIso8601String(),
        'creadaPor': creadaPor,
        'plan': planId,
        'licencia': licencia.toMap(ahora: ahora, estadoEmpresa: estado),
        'parametros': parametros.toMap(),
        'limites': limites.toMap(),
      };

  factory Empresa.fromMap(String id, Map<String, dynamic> data) {
    return Empresa(
      id: (data['id'] as String?) ?? id,
      nombre: (data['nombre'] as String?) ?? '',
      nit: (data['nit'] as String?) ?? '',
      correoNotificacion: (data['correoNotificacion'] as String?) ?? '',
      telefono: (data['telefono'] as String?) ?? '',
      contactoProveedor: (data['contactoProveedor'] as String?) ?? '',
      logo: (data['logo'] as String?) ?? '',
      logoAncho: (data['logoAncho'] as num?)?.toInt() ?? 0,
      logoAlto: (data['logoAlto'] as num?)?.toInt() ?? 0,
      adminId: (data['adminId'] as String?) ?? '',
      estado: EstadoEmpresa.desdeId(data['estado'] as String?),
      fechaCreacion: aFecha(data['fechaCreacion']),
      creadaPor: (data['creadaPor'] as String?) ?? '',
      planId: (data['plan'] as String?) ?? 'gratis',
      licencia: Licencia.fromMap(
          (data['licencia'] as Map?)?.cast<String, dynamic>()),
      parametros: ParametrosEmpresa.fromMap(
          (data['parametros'] as Map?)?.cast<String, dynamic>()),
      limites: LimitesPlan.fromMap(
          (data['limites'] as Map?)?.cast<String, dynamic>()),
    );
  }
}

/// Datos mínimos para dar de alta una empresa (RF-01) y su administrador.
class DatosEmpresa {
  const DatosEmpresa({
    required this.nombre,
    this.nit = '',
    this.correoNotificacion = '',
    this.telefono = '',
    this.contactoProveedor = '',
    this.adminNombre = '',
    this.adminEmail = '',
  });

  final String nombre;
  final String nit;
  final String correoNotificacion;
  final String telefono;
  final String contactoProveedor;

  /// Nombre y correo del Administrador que se creará (RF-03).
  final String adminNombre;
  final String adminEmail;

  /// Arma el cuerpo que espera la Cloud Function `crearEmpresa`.
  Map<String, dynamic> aSolicitud({
    required Licencia licencia,
    required String planId,
  }) =>
      <String, dynamic>{
        'nombre': nombre,
        'nit': nit,
        'correoNotificacion': correoNotificacion,
        'telefono': telefono,
        'contactoProveedor': contactoProveedor,
        'plan': planId,
        'licencia': licencia.toMap(),
        'admin': <String, dynamic>{
          'nombre': adminNombre.isEmpty ? nombre : adminNombre,
          'email': adminEmail,
        },
      };

  /// Valida los datos antes de enviarlos (devuelve el primer error o `null`).
  String? validar() {
    if (nombre.trim().isEmpty) return 'El nombre es obligatorio.';
    if (nit.trim().isEmpty) return 'El NIT es obligatorio.';
    if (adminEmail.trim().isEmpty) return 'El correo del administrador es obligatorio.';
    if (!esCorreoValido(adminEmail)) {
      return 'El correo del administrador no es válido.';
    }
    if (correoNotificacion.trim().isNotEmpty &&
        !esCorreoValido(correoNotificacion)) {
      return 'El correo de notificación no es válido.';
    }
    return null;
  }
}
