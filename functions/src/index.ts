import * as admin from 'firebase-admin';
import {onDocumentWritten} from 'firebase-functions/v2/firestore';
import {HttpsError, onCall} from 'firebase-functions/v2/https';

admin.initializeApp();

export {crearEmpresa, actualizarLicencia, cambiarEstadoEmpresa} from './empresas.js';
export {notificarVencimientos} from './notificaciones.js';

export const onUsuarioEscrito = onDocumentWritten(
  'usuarios/{uid}',
  async (event) => {
    const snapshot = event.data?.after ?? event.data?.before;
    if (!snapshot) return;

    const uid = event.params.uid;
    const data = snapshot.data() as Record<string, unknown> | undefined;
    if (!data) return;

    const empresaId = (data.empresaId as string) || null;
    const rolesRaw = (data.roles as unknown[]) || [];
    const roles = rolesRaw.filter((r) => typeof r === 'string') as string[];

    const activo = (data.activo as boolean) ?? true;
    if (!activo) {
      try {
        await admin.auth().revokeRefreshTokens(uid);
      } catch (e) {
        console.error('No se pudieron revocar tokens para', uid, e);
      }
    }

    try {
      await admin.auth().setCustomUserClaims(uid, {
        empresaId,
        roles,
        superAdmin: roles.includes('superadmin'),
      });
    } catch (e) {
      console.error('Error al sincronizar custom claims para', uid, e);
    }
  }
);

export const validarLicencia = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Usuario no autenticado');
  }

  const empresaId = (request.data?.empresaId as string) || request.auth.token.empresaId;
  if (!empresaId) {
    throw new HttpsError('invalid-argument', 'Se requiere empresaId');
  }

  const roles = (request.auth.token.roles as string[]) || [];
  const esSuperAdmin = !!request.auth.token.superAdmin || roles.includes('superadmin');
  const mismaEmpresa = request.auth.token.empresaId === empresaId;

  if (!esSuperAdmin && !mismaEmpresa) {
    throw new HttpsError('permission-denied', 'No autorizado');
  }

  try {
    const doc = await admin.firestore().collection('empresas').doc(empresaId).get();
    if (!doc.exists) {
      throw new HttpsError('not-found', 'Empresa no encontrada');
    }

    const data = doc.data() as Record<string, unknown>;
    const licencia = (data.licencia as Record<string, unknown>) || {};
    const estadoEmpresa = (data.estado as string) || 'activa';
    const fechaFin = licencia.fechaFin as any;
    const diasAviso = (licencia.diasAvisoVencimiento as number) ?? 5;
    const contacto = (data.contactoProveedor as string) || '';

    let fechaFinDate: Date | null = null;
    if (fechaFin?.toDate) {
      fechaFinDate = fechaFin.toDate();
    } else if (typeof fechaFin === 'string') {
      fechaFinDate = new Date(fechaFin);
    }

    const hoy = new Date();
    let vigente = true;
    let diasRestantes = null;
    if (fechaFinDate) {
      diasRestantes = Math.ceil((fechaFinDate.getTime() - hoy.getTime()) / 86400000);
      if (diasRestantes < 0) vigente = false;
    }

    if (estadoEmpresa === 'suspendida') vigente = false;

    return {
      vigente,
      estado: licencia.estado || estadoEmpresa,
      fechaInicio: licencia.fechaInicio || null,
      fechaFin: fechaFinDate ? fechaFinDate.toISOString().split('T')[0] : null,
      diasRestantes,
      contactoProveedor: contacto,
      diasAvisoVencimiento: diasAviso,
    };
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error('Error al validar licencia', e);
    throw new HttpsError('internal', 'Error al validar licencia');
  }
});
