# Guía Rápida: Clientes

- **ID:** 004 | **Fecha:** 2026-10-14

---

## Registrar un cliente

1. Entrar al módulo **Clientes**.
2. Clic en **Nuevo cliente**.
3. Llenar los **obligatorios**:
   - Nombre completo
   - Cédula
   - Teléfono
   - Dirección: **departamento** → **ciudad** → **dirección** → **barrio**
4. Opcional: correo, contacto, teléfono alterno, observaciones.
5. Opcional: **Compartir ubicación GPS** (como en WhatsApp).
6. Clasificar: detal o mayorista.
7. Guardar.

## Compartir ubicación GPS

1. En el formulario, clic en **Compartir ubicación**.
2. Conceder permiso de ubicación.
3. La app toma latitud/longitud y calcula la dirección aproximada.
4. Guardar.

## Abrir la ubicación en el mapa

- En el detalle del cliente, clic en la ubicación.
- Se abre **Google Maps** o **Waze** con la ruta.

## Acceso del cliente (rol Cliente)

Un cliente registrado puede:
- Ver su perfil y actualizar dirección y ubicación.
- Ver su historial de compras.
- Ver sus pedidos y el estado de cada uno.

Un cliente **no** puede ver datos de otros clientes ni de otra empresa.

## Estados del cliente

| Estado | Significado |
|---|---|
| `activo` | Cliente normal |
| `inactivo` | Sin actividad / deshabilitado |
| `moroso` | Con crédito vencido |

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/clientes-contracts.md`](./contracts/clientes-contracts.md)
