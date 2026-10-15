import * as admin from 'firebase-admin';
import {HttpsError, onCall} from 'firebase-functions/v2/https';

import {
  aFecha,
  auditar,
  calcularEstadoLicencia,
  exigirSuperAdmin,
  normalizarLicencia,
} from './comun.js';

/**
 * Crea una empresa con su licencia, sus parametros por defecto y su usuario
 * Administrador. Ver spec 002, contratos y ADR-001.
 *
 * Solo puede invocarla el Super Admin. Es idempotente respecto al NIT: si ya
 * existe una empresa con ese NIT responde `already-exists`.
 */
export const crearEmpresa = onCall(async (request) => {
  exigirSuperAdmin(request);

  const data = (request.data ?? {}) as Record<string, unknown>;
  const nombre = String(data.nombre ?? '').trim();
  const nit = String(data.nit ?? '').trim();
  const correoNotificacion = String(data.correoNotificacion ?? '').trim();
  const telefono = String(data.telefono ?? '').trim();
  const contactoProveedor = String(data.contactoProveedor ?? '').trim();
  const planId = String(data.plan ?? 'gratis');
  const logo = String(data.logo ?? '');
  const logoAncho = Number(data.logoAncho ?? 0) || 0;
  const logoAlto = Number(data.logoAlto ?? 0) || 0;

  const adminDatos = (data.admin ?? {}) as Record<string, unknown>;
  const adminEmail = String(adminDatos.email ?? '').trim().toLowerCase();
  const adminNombre = String(adminDatos.nombre ?? nombre).trim();

  if (!nombre) throw new HttpsError('invalid-argument', 'El nombre es obligatorio');
  if (!nit) throw new HttpsError('invalid-argument', 'El NIT es obligatorio');
  if (!adminEmail) {
    throw new HttpsError(
      'invalid-argument',
      'El correo del administrador es obligatorio'
    );
  }

  const ahora = new Date();
  const tipo = String(
    (data.licencia as Record<string, unknown> | undefined)?.tipo ?? 'mensual'
  );
  const licenciaCruda = (data.licencia ?? {}) as Record<string, unknown>;
  const fechaInicio = aFecha(licenciaCruda.fechaInicio);
  const fechaFin = aFecha(licenciaCruda.fechaFin);

  if (fechaInicio && fechaFin && fechaFin < fechaInicio) {
    throw new HttpsError(
      'invalid-argument',
      'La fecha de fin no puede ser anterior a la de inicio'
    );
  }

  const db = admin.firestore();

  // NIT unico (RN: NIT duplicado es caso borde).
  const duplicado = await db
    .collection('empresas')
    .where('nit', '==', nit)
    .limit(1)
    .get();
  if (!duplicado.empty) {
    throw new HttpsError('already-exists', 'Ya existe una empresa con ese NIT');
  }

  // Limites del plan (RF-11).
  let limites: Record<string, unknown> = {};
  try {
    const planDoc = await db.collection('planes').doc(planId).get();
    if (planDoc.exists) {
      limites = (planDoc.data()?.limites as Record<string, unknown>) ?? {};
    }
  } catch (e) {
    console.warn('No se pudo leer el plan', planId, e);
  }

  const empresaRef =
    typeof data.empresaId === 'string' && data.empresaId.length > 0
      ? db.collection('empresas').doc(data.empresaId)
      : db.collection('empresas').doc();
  const empresaId = empresaRef.id;

  // Usuario Administrador: se reutiliza si el correo ya existe.
  let adminUid: string;
  try {
    const existente = await admin.auth().getUserByEmail(adminEmail);
    adminUid = existente.uid;
  } catch {
    const creado = await admin.auth().createUser({
      email: adminEmail,
      displayName: adminNombre,
      emailVerified: false,
    });
    adminUid = creado.uid;
  }

  const estadoEmpresa = tipo === 'gratis' ? 'prueba' : 'activa';
  const licencia = normalizarLicencia(licenciaCruda, estadoEmpresa, ahora);

  const batch = db.batch();
  batch.set(empresaRef, {
    id: empresaId,
    nombre,
    nit,
    correoNotificacion,
    telefono,
    contactoProveedor,
    logo,
    logoAncho,
    logoAlto,
    adminId: adminUid,
    estado: estadoEmpresa,
    fechaCreacion: ahora.toISOString(),
    creadaPor: request.auth?.uid ?? '',
    plan: planId,
    licencia,
    parametros: {
      margenDetal: 30,
      margenMayor: 20,
      margenDistribuidor: 10,
      costoEnvio: 0,
      iva: 19,
      moneda: 'COP',
      tema: {colorPrimario: '#1A73E8', colorSecundario: '#FF6B35'},
    },
    limites,
  });
  batch.set(db.collection('usuarios').doc(adminUid), {
    uid: adminUid,
    nombre: adminNombre,
    email: adminEmail,
    telefono: '',
    empresaId,
    roles: ['administrador'],
    activo: true,
    fechaCreacion: ahora.toISOString(),
    creadoPor: request.auth?.uid ?? '',
  });
  await batch.commit();

  // Custom claims (el trigger onUsuarioEscrito tambien los sincroniza).
  try {
    await admin.auth().setCustomUserClaims(adminUid, {
      empresaId,
      roles: ['administrador'],
      superAdmin: false,
    });
  } catch (e) {
    console.error('No se pudieron asignar los claims del administrador', e);
  }

  // Enlace para que el administrador defina su contrasena (credenciales
  // temporales, RN-04). Sin proveedor de correo, se devuelve al Super Admin.
  let enlaceActivacion: string | null = null;
  try {
    enlaceActivacion = await admin.auth().generatePasswordResetLink(adminEmail);
  } catch (e) {
    console.warn('No se pudo generar el enlace de activacion', e);
  }

  await auditar({
    empresaId,
    usuario: request.auth?.uid ?? '',
    operacion: 'INSERT',
    tabla: 'empresas',
    documentoId: empresaId,
    valorNuevo: {nombre, nit, plan: planId, adminId: adminUid},
  });

  return {empresaId, adminUid, enlaceActivacion};
});

/**
 * Renueva o extiende la licencia de una empresa y registra el pago en el
 * historial (RF-09, RF-12).
 */
export const actualizarLicencia = onCall(async (request) => {
  exigirSuperAdmin(request);

  const data = (request.data ?? {}) as Record<string, unknown>;
  const empresaId = String(data.empresaId ?? '');
  if (!empresaId) {
    throw new HttpsError('invalid-argument', 'Se requiere empresaId');
  }

  const db = admin.firestore();
  const ref = db.collection('empresas').doc(empresaId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'Empresa no encontrada');
  }

  const empresa = snap.data() ?? {};
  const estadoEmpresa = String(empresa.estado ?? 'activa');
  const ahora = new Date();

  const licenciaNueva = normalizarLicencia(
    (data.licencia ?? data) as Record<string, unknown>,
    estadoEmpresa,
    ahora
  );

  if (data.nota !== undefined || data.valorPagado !== undefined) {
    const historial = Array.isArray(licenciaNueva.historialPagos)
      ? (licenciaNueva.historialPagos as unknown[])
      : [];
    historial.push({
      fecha: ahora.toISOString(),
      valor: licenciaNueva.valorPagado ?? 0,
      periodoInicio: licenciaNueva.fechaInicio,
      periodoFin: licenciaNueva.fechaFin,
      nota: String(data.nota ?? 'Renovacion'),
    });
    licenciaNueva.historialPagos = historial;
  }

  await ref.update({licencia: licenciaNueva});

  await auditar({
    empresaId,
    usuario: request.auth?.uid ?? '',
    operacion: 'UPDATE',
    tabla: 'empresas',
    documentoId: empresaId,
    campo: 'licencia',
    valorViejo: empresa.licencia ?? null,
    valorNuevo: licenciaNueva,
  });

  return {ok: true, licencia: licenciaNueva};
});

/**
 * Activa, suspende, reactiva o elimina (logicamente) una empresa (RF-08, RN-08).
 */
export const cambiarEstadoEmpresa = onCall(async (request) => {
  exigirSuperAdmin(request);

  const data = (request.data ?? {}) as Record<string, unknown>;
  const empresaId = String(data.empresaId ?? '');
  const estado = String(data.estado ?? '');
  const permitidos = [
    'activa',
    'suspendida',
    'prueba',
    'eliminada',
    'creacion_incompleta',
  ];

  if (!empresaId) {
    throw new HttpsError('invalid-argument', 'Se requiere empresaId');
  }
  if (!permitidos.includes(estado)) {
    throw new HttpsError('invalid-argument', 'Estado no valido');
  }

  const db = admin.firestore();
  const ref = db.collection('empresas').doc(empresaId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'Empresa no encontrada');
  }

  const empresa = snap.data() ?? {};
  const licencia = (empresa.licencia ?? {}) as Record<string, unknown>;
  const ahora = new Date();
  const diasAviso =
    typeof licencia.diasAvisoVencimiento === 'number'
      ? licencia.diasAvisoVencimiento
      : 5;

  licencia.estado = calcularEstadoLicencia(
    aFecha(licencia.fechaFin),
    diasAviso,
    estado,
    ahora
  );

  await ref.update({estado, licencia});

  await auditar({
    empresaId,
    usuario: request.auth?.uid ?? '',
    operacion: 'UPDATE',
    tabla: 'empresas',
    documentoId: empresaId,
    campo: 'estado',
    valorViejo: empresa.estado ?? null,
    valorNuevo: estado,
  });

  return {ok: true, estado};
});
