# Guía Rápida: Gestión de Empresas

- **ID:** 002 | **Fecha:** 2026-10-14

---

## Crear una empresa (Super Admin)

1. Entrar al módulo **Gestión de Empresas**.
2. Clic en **Nueva empresa**.
3. Completar datos: nombre, NIT, correo, teléfono.
4. Definir licencia: tipo (mensual/anual), fecha de inicio y fecha de fin.
5. Subir el logo (512x512 px recomendado).
6. Guardar. El sistema:
   - Crea el documento de la empresa.
   - Crea el usuario **Administrador** con credenciales temporales.
   - Crea los parámetros y roles por defecto.
7. Entregar las credenciales al cliente.

## Renovar una licencia (Super Admin)

1. Abrir la empresa.
2. Clic en **Renovar**.
3. Extender `fechaFin` (nuevo periodo).
4. Guardar (queda en `historialPagos`).

## Suspender / reactivar (Super Admin)

1. Abrir la empresa.
2. Cambiar **estado** a `suspendida` o `activa`.

## Tablero de vencimientos

Muestra tres grupos:
- **Por vencer:** licencias dentro de los días de aviso (por defecto 5).
- **Vencidas:** `fechaFin` ya pasó.
- **Activas:** vigentes sin riesgo.

## Estado de licencia

| Estado | Condición |
|---|---|
| `activa` | `fechaFin` > hoy + días de aviso |
| `por_vencer` | hoy <= `fechaFin` <= hoy + días de aviso |
| `vencida` | `fechaFin` < hoy |
| `suspendida` | estado manual de la empresa |

## Documentos relacionados

- [`spec.md`](./spec.md) — qué y por qué
- [`plan.md`](./plan.md) — cómo
- [`data-model.md`](./data-model.md) — estructura de datos
- [`contracts/empresas-contracts.md`](./contracts/empresas-contracts.md) — contratos
