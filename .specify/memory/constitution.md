# Constitución del Proyecto — Aplicativo de Ventas

> Principios no negociables. Todo agente o desarrollador debe respetarlos.
> Versión: 1.0.0 | Fecha: Octubre 2026

---

## Principio 1 — Especificación primero (SDD)

Ninguna funcionalidad se implementa sin `spec.md` y `plan.md` aprobados.
La especificación es la fuente de verdad; el código se deriva de ella.

## Principio 2 — Multi-tenant obligatorio

Toda colección y toda consulta debe estar filtrada por `empresaId`.
Un usuario solo puede ver y modificar datos de su propia empresa.
El Super Admin es la única excepción (acceso global).

## Principio 3 — Seguridad por roles (RBAC)

- Un usuario puede tener **múltiples roles**; los permisos efectivos son la **UNIÓN** de sus roles.
- Los formularios, opciones y datos no se muestran a roles sin permiso.
- El **Administrador** de empresa tiene acceso total dentro de su empresa.
- El rol **Developer** solo da acceso a los logs de errores.

## Principio 4 — Auditoría obligatoria

Toda operación de escritura (INSERT / UPDATE / DELETE) se registra automáticamente en
la colección `_auditoria` con: empresaId, usuario, fecha/hora, operación, tabla,
documentoId, campo, valorViejo y valorNuevo.
La auditoría se conserva mínimo **6 meses**.

## Principio 5 — Trazabilidad del dinero

Siempre debe poderse responder: quién vendió, quién tiene el dinero, dónde está y en qué estado.
Las entregas de dinero de vendedores a caja requieren aprobación del cajero.

## Principio 6 — Licencias por empresa

Cada empresa tiene una licencia con fecha de inicio y fin (plan mensual o anual).
Si la licencia vence, se bloquea el ingreso y se muestra el contacto del proveedor.

## Principio 7 — Funcionamiento offline

La app debe funcionar sin conexión y sincronizar automáticamente al recuperarla.

## Principio 8 — Simplicidad para el usuario

Interfaz intuitiva para vendedores con poca experiencia técnica.
Registrar una venta no debe tomar más de 2 minutos.

## Principio 9 — Seguridad de secretos

Nunca se suben secretos ni credenciales al repositorio.

## Principio 10 — Calidad

- Código analizado con `flutter analyze` sin errores.
- Pruebas para cada funcionalidad.
- Commits frecuentes y descriptivos.

---

## Enmiendas

Cualquier cambio a esta constitución debe documentarse aquí con fecha y motivo.
