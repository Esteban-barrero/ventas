import * as admin from 'firebase-admin';
import {HttpsError, CallableRequest} from 'firebase-functions/v2/https';

/** Roles y bandera de Super Admin a partir de los custom claims. */
export function esSuperAdmin(request: CallableRequest): boolean {
  const token = (request.auth?.token ?? {}) as Record<string, unknown>;
  const roles = Array.isArray(token.roles) ? (token.roles as string[]) : [];
  return token.superAdmin === true || roles.includes('superadmin');
}

/** Exige que quien llama sea Super Admin. */
export function exigirSuperAdmin(request: CallableRequest): void {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Usuario no autenticado');
  }
  if (!esSuperAdmin(request)) {
    throw new HttpsError(
      'permission-denied',
      'Solo el Super Admin puede realizar esta accion'
    );
  }
}

/** Convierte un valor de Firestore (string ISO o Timestamp) a Date. */
export function aFecha(valor: unknown): Date | null {
  if (!valor) return null;
  if (valor instanceof Date) return valor;
  if (typeof valor === 'string') {
    const fecha = new Date(valor);
    return Number.isNaN(fecha.getTime()) ? null : fecha;
  }
  const posible = valor as {toDate?: () => Date};
  if (typeof posible.toDate === 'function') return posible.toDate();
  return null;
}

/** Dias completos entre dos fechas (por dia, sin horas). */
export function diasEntre(desde: Date, hasta: Date): number {
  const d = Date.UTC(desde.getUTCFullYear(), desde.getUTCMonth(), desde.getUTCDate());
  const h = Date.UTC(hasta.getUTCFullYear(), hasta.getUTCMonth(), hasta.getUTCDate());
  return Math.round((h - d) / 86400000);
}

/**
 * Calcula el estado derivado de la licencia con la misma logica que el cliente
 * (app/lib/features/empresas/domain/licencia.dart).
 */
export function calcularEstadoLicencia(
  fechaFin: Date | null,
  diasAviso: number,
  estadoEmpresa: string,
  ahora: Date
): string {
  if (estadoEmpresa === 'suspendida') return 'suspendida';
  if (estadoEmpresa === 'prueba') return 'prueba';
  if (!fechaFin) return 'activa';
  const dias = diasEntre(ahora, fechaFin);
  if (dias < 0) return 'vencida';
  if (dias <= diasAviso) return 'por_vencer';
  return 'activa';
}

/** Normaliza el mapa `licencia` que llega desde el cliente. */
export function normalizarLicencia(
  datos: Record<string, unknown> | undefined,
  estadoEmpresa: string,
  ahora: Date
): Record<string, unknown> {
  const lic = (datos ?? {}) as Record<string, unknown>;
  const tipo = typeof lic.tipo === 'string' ? lic.tipo : 'mensual';
  const fechaInicio = aFecha(lic.fechaInicio);
  const fechaFin = aFecha(lic.fechaFin);
  const diasAviso =
    typeof lic.diasAvisoVencimiento === 'number'
      ? lic.diasAvisoVencimiento
      : 5;
  const valorPagado =
    typeof lic.valorPagado === 'number' ? lic.valorPagado : 0;
  const historial = Array.isArray(lic.historialPagos) ? lic.historialPagos : [];

  return {
    tipo,
    fechaInicio: fechaInicio ? fechaInicio.toISOString() : null,
    fechaFin: fechaFin ? fechaFin.toISOString() : null,
    estado: calcularEstadoLicencia(fechaFin, diasAviso, estadoEmpresa, ahora),
    diasAvisoVencimiento: diasAviso,
    valorPagado,
    historialPagos: historial,
  };
}

/** Registra un evento en `_auditoria` (solo insercion). */
export async function auditar(params: {
  empresaId: string;
  usuario: string;
  operacion: 'INSERT' | 'UPDATE' | 'DELETE';
  tabla: string;
  documentoId: string;
  campo?: string | null;
  valorViejo?: unknown;
  valorNuevo?: unknown;
}): Promise<void> {
  await admin.firestore().collection('_auditoria').add({
    empresaId: params.empresaId,
    usuario: params.usuario,
    fecha: admin.firestore.FieldValue.serverTimestamp(),
    operacion: params.operacion,
    tabla: params.tabla,
    documentoId: params.documentoId,
    campo: params.campo ?? null,
    valorViejo: params.valorViejo ?? null,
    valorNuevo: params.valorNuevo ?? null,
  });
}
