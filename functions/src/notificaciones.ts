import * as admin from 'firebase-admin';
import {onSchedule} from 'firebase-functions/v2/scheduler';

import {aFecha, diasEntre} from './comun.js';

/** Textos y tipos de aviso de licencia (RN-06). */
function mensajeDeAviso(
  nombre: string,
  dias: number,
  fechaFin: Date | null
): {tipo: string; mensaje: string} {
  const fecha = fechaFin ? fechaFin.toISOString().split('T')[0] : '—';
  if (dias < 0) {
    return {
      tipo: 'licencia_vencida',
      mensaje:
        `La licencia de "${nombre}" venció el ${fecha}. ` +
        'Por favor comuníquese con su proveedor para renovarla.',
    };
  }
  return {
    tipo: 'licencia_por_vencer',
    mensaje:
      `La licencia de "${nombre}" vence el ${fecha} ` +
      `(${dias} ${dias === 1 ? 'día' : 'días'}).`,
  };
}

/**
 * Job diario (Cloud Scheduler) que avisa de licencias por vencer y vencidas:
 * crea una notificacion in-app y un correo. Ver spec 002, RF-13 / ADR-002.
 *
 * El correo se encola en la coleccion `mail`, que la extension oficial
 * "Trigger Email from Firestore" convierte en un envio real. Sin esa extension
 * instalada, el aviso in-app igual queda registrado.
 */
export const notificarVencimientos = onSchedule(
  {schedule: '0 8 * * *', timeZone: 'America/Bogota'},
  async () => {
    const db = admin.firestore();
    const ahora = new Date();
    const hoy = ahora.toISOString().split('T')[0];

    const snap = await db
      .collection('empresas')
      .where('estado', 'in', ['activa', 'prueba'])
      .get();

    for (const doc of snap.docs) {
      const empresa = doc.data();
      const licencia = (empresa.licencia ?? {}) as Record<string, unknown>;
      const fechaFin = aFecha(licencia.fechaFin);
      if (!fechaFin) continue;

      const dias = diasEntre(ahora, fechaFin);
      const diasAviso =
        typeof licencia.diasAvisoVencimiento === 'number'
          ? licencia.diasAvisoVencimiento
          : 5;

      const porVencer = dias >= 0 && dias <= diasAviso;
      const vencida = dias < 0;
      if (!porVencer && !vencida) continue;

      const ultima = String(empresa.ultimaNotificacion ?? '');
      // Vencidas: se recuerda como maximo cada 7 dias para no saturar.
      if (vencida && ultima) {
        const desde = aFecha(ultima);
        if (desde && diasEntre(desde, ahora) < 7) continue;
      }
      if (ultima === hoy) continue;

      const {tipo, mensaje} = mensajeDeAviso(
        String(empresa.nombre ?? ''),
        dias,
        fechaFin
      );

      const batch = db.batch();

      batch.set(db.collection('notificaciones').doc(), {
        empresaId: doc.id,
        tipo,
        mensaje,
        leida: false,
        fecha: admin.firestore.FieldValue.serverTimestamp(),
      });

      const destinatario =
        String(empresa.correoNotificacion ?? '') ||
        String(empresa.contactoProveedor ?? '');
      if (destinatario.includes('@')) {
        batch.set(db.collection('mail').doc(), {
          to: [destinatario],
          message: {
            subject:
              tipo === 'licencia_vencida'
                ? 'Su licencia se ha agotado'
                : 'Su licencia está por vencer',
            text: mensaje,
          },
        });
      }

      batch.update(doc.ref, {ultimaNotificacion: hoy});
      await batch.commit();
    }

    console.log(`Avisos de vencimiento revisados el ${hoy}`);
  }
);
