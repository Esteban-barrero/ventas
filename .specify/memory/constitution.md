# Constitución del Proyecto — Aplicativo de Ventas

> Principios no negociables. Todo agente o desarrollador debe respetarlos.
> Versión: 1.1.0 | Fecha: Octubre 2026

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

## Principio 11 — Código documentado para soporte futuro

Todo el código debe quedar **documentado y comentado** para facilitar el
mantenimiento y el soporte futuro. Ninguna unidad de código se considera
terminada si no está documentada.

- **Todo método** (público o privado), clase, función y campo relevante lleva un
  comentario claro en **español** que explique **qué hace**, sus **parámetros**,
  su **valor de retorno** y, cuando aplique, la **spec / RF / RN / ADR** que lo
  respalda.
- En **Dart** se usa **docstring** (`///`) en las APIs públicas (repositorios,
  dominio, widgets) y comentarios inline (`//`) en los métodos privados y en los
  bloques no obvios, explicando el **por qué** y no solo el qué.
- En **TypeScript** cada función exportada lleva **JSDoc** (`/** ... */`).
- Los comentarios describen la intención y las reglas de negocio; no repiten lo
  que el código ya dice de forma evidente.
- Se documentan especialmente los **casos borde** y las **razones** de las
  decisiones (por ejemplo, por qué se refresca un token o por qué un fallo se
  trata como *fail-closed*).
- Esta regla forma parte del **Definition of Done** de cada `tasks.md`.

---

## Enmiendas

Cualquier cambio a esta constitución debe documentarse aquí con fecha y motivo.

- **2026-10-15 — v1.1.0:** se agrega el **Principio 11 — Código documentado
  para soporte futuro**: todo método, clase y función deben quedar comentados de
  forma clara y en español para facilitar el mantenimiento. Motivo: garantizar
  que el equipo (presente o futuro) pueda dar soporte sin depender de
  conocimiento tácito.
