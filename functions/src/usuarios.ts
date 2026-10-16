import admin from 'firebase-admin';
import {HttpsError, onCall} from 'firebase-functions/v2/https';

import {
  auditar,
  exigirGestionUsuarios,
  normalizarRoles,
} from './comun.js';

/**
 * Crea un usuario de una empresa con sus roles (spec 001, RF-03/RF-04, CA-06).
 *
 * Puede invocarla el Super Admin (cualquier empresa) o el Administrador de la
 * empresa (solo la suya). El Administrador **no** puede asignar el rol
 * `superadmin` ni crear usuarios en otra empresa. La cuenta de Authentication
 * se crea sin contrasena: el usuario define la suya con el enlace de
 * activacion que devuelve esta funcion.
 */
export const crearUsuario = onCall(async (request) => {
  const ctx = exigirGestionUsuarios(request);

  const data = (request.data ?? {}) as Record<string, unknown>;
  const nombre = String(data.nombre ?? '').trim();
  const telefono = String(data.telefono ?? '').trim();
  const email = String(data.email ?? '').trim().toLowerCase();
  const activo = data.activo !== false;
  const roles = normalizarRoles(data.roles);

  if (!nombre) {
    throw new HttpsError('invalid-argument', 'El nombre es obligatorio');
  }
  if (!email || !email.includes('@')) {
    throw new HttpsError('invalid-argument', 'El correo no es valido');
  }
  if (roles.length === 0) {
    throw new HttpsError('invalid-argument', 'Asigna al menos un rol');
  }
  if (roles.includes('superadmin') && !ctx.esSuper) {
    throw new HttpsError(
      'permission-denied',
      'Solo el Super Admin puede asignar el rol Super Admin'
    );
  }

  // El Administrador siempre crea en SU empresa; el Super Admin la indica.
  const empresaId = ctx.esSuper
    ? String(data.empresaId ?? ctx.empresaId ?? '').trim()
    : ctx.empresaId;
  if (!empresaId) {
    throw new HttpsError(
      'failed-precondition',
      'No hay una empresa asignada para crear el usuario'
    );
  }

  const db = admin.firestore();
  const empresa = await db.collection('empresas').doc(empresaId).get();
  if (!empresa.exists) {
    throw new HttpsError(
      'failed-precondition',
      'La empresa no existe'
    );
  }

  // Limite de usuarios del plan (RF-11). -1 significa ilimitado.
  const max = (empresa.get('limites.maxUsuarios') as number | undefined) ?? -1;
  if (max >= 0) {
    const conteo = await db
      .collection('usuarios')
      .where('empresaId', '==', empresaId)
      .count()
      .get();
    if (conteo.data().count >= max) {
      throw new HttpsError(
        'failed-precondition',
        `La empresa alcanzo el limite de ${max} usuarios de su plan`
      );
    }
  }

  // Cuenta de Authentication (sin contrasena: se fija con el enlace).
  let uid: string;
  try {
    const creado = await admin.auth().createUser({
      email,
      displayName: nombre,
      emailVerified: false,
      disabled: !activo,
    });
    uid = creado.uid;
  } catch (e) {
    const codigo = (e as {code?: string}).code ?? '';
    if (codigo === 'auth/email-already-exists') {
      throw new HttpsError(
        'already-exists',
        'Ese correo ya esta registrado'
      );
    }
    if (codigo === 'auth/invalid-email') {
      throw new HttpsError('invalid-argument', 'El correo no es valido');
    }
    console.error('No se pudo crear la cuenta del usuario', e);
    throw new HttpsError('internal', 'No se pudo crear la cuenta del usuario');
  }

  await db.collection('usuarios').doc(uid).set({
    uid,
    nombre,
    email,
    telefono,
    empresaId,
    roles,
    activo,
    fechaCreacion: new Date().toISOString(),
    creadoPor: ctx.uid,
  });

  // Enlace para que el usuario fije su contrasena (credenciales temporales).
  let enlaceActivacion: string | null = null;
  try {
    enlaceActivacion = await admin.auth().generatePasswordResetLink(email);
  } catch (e) {
    console.warn('No se pudo generar el enlace de activacion', e);
  }

  await auditar({
    empresaId,
    usuario: ctx.uid,
    operacion: 'INSERT',
    tabla: 'usuarios',
    documentoId: uid,
    valorNuevo: {nombre, email, telefono, empresaId, roles, activo},
  });

  return {uid, enlaceActivacion};
});

/**
 * Genera un enlace de restablecimiento de contrasena para un usuario existente
 * (spec 001). El enlace se devuelve para copiarlo, asi funciona aunque el
 * correo del usuario no reciba mensajes.
 *
 * Lo invoca el Super Admin (cualquier empresa) o el Administrador de la empresa
 * (solo usuarios de la suya).
 */
export const generarEnlaceActivacion = onCall(async (request) => {
  const ctx = exigirGestionUsuarios(request);

  const data = (request.data ?? {}) as Record<string, unknown>;
  const uid = String(data.uid ?? '').trim();
  let email = String(data.email ?? '').trim().toLowerCase();

  // El Administrador solo puede con usuarios de SU empresa.
  if (!ctx.esSuper) {
    if (!uid) {
      throw new HttpsError('invalid-argument', 'Falta el usuario');
    }
    const perfil = await admin
      .firestore()
      .collection('usuarios')
      .doc(uid)
      .get();
    const empresaObjetivo = perfil.data()?.empresaId as string | undefined;
    if (!ctx.empresaId || empresaObjetivo !== ctx.empresaId) {
      throw new HttpsError(
        'permission-denied',
        'El usuario no es de tu empresa'
      );
    }
  }

  if (!email && uid) {
    const usuario = await admin.auth().getUser(uid);
    email = (usuario.email ?? '').toLowerCase();
  }
  if (!email) {
    throw new HttpsError('invalid-argument', 'Falta el correo del usuario');
  }

  try {
    const enlaceActivacion = await admin
      .auth()
      .generatePasswordResetLink(email);
    return {enlaceActivacion};
  } catch (e) {
    console.error('No se pudo generar el enlace de restablecimiento', e);
    throw new HttpsError(
      'internal',
      'No se pudo generar el enlace de restablecimiento'
    );
  }
});
