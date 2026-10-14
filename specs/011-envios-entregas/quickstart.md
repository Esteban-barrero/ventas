# Guía Rápida: Envíos y Entregas

- **ID:** 011 | **Fecha:** 2026-10-14

---

## Tipos de entrega

| Tipo | Envío | Transportadora | Contra entrega |
|---|---|---|---|
| Presencial | No | — | No |
| Recoger en local | No | — | No |
| Entrega local | Sí (propia) | Repartidor | Opcional |
| Envío | Sí | Sí | Opcional |

## Crear un envío

1. Desde la **venta** o el **pedido** → **Crear envío**.
2. Elegir **transportadora** y número de **guía**.
3. Indicar **repartidor** (si es propio).
4. Confirmar **dirección** y **costo de envío**.
5. Despachar.

## Estados del envío

```
preparando ─► despachado ─► en_transito ─► en_reparto ─► entregado
                                                │
                                                ├─► devuelto
                                                └─► novedad
```

| Estado | Significado |
|---|---|
| `preparando` | Alistando el paquete |
| `despachado` | Entregado a la transportadora |
| `en_transito` | En camino a la ciudad |
| `en_reparto` | Salió a entregar |
| `entregado` | Recibido por el cliente |
| `devuelto` | Regresó (reingresa stock) |
| `novedad` | Problema en la entrega |

## Evidencia de entrega

1. Al marcar **entregado**, tomar **foto** y/o **firma**.
2. Se guarda en Firebase Storage y se enlaza al envío.
3. Según configuración, la evidencia es **obligatoria**.

## Pago contra entrega

1. La venta se marca **contra entrega**.
2. El dinero queda **en tránsito** (responsable = repartidor).
3. Al **entregar**, el repartidor entrega el dinero al **cajero**.
4. El dinero pasa a **caja** (spec 009) y cambia a **entregado**.

## Rastreo del cliente

El cliente ve:
- Estado actual e **historial** de estados.
- **Guía** y transportadora.
- **Fecha estimada** de entrega.
- Ubicación (abrir en **Google Maps** / **Waze**).

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/envios-contracts.md`](./contracts/envios-contracts.md)
