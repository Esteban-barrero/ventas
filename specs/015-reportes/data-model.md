# Modelo de Datos: Reportes

- **ID:** 015 | **Fecha:** 2026-10-14

---

> Los reportes **consultan** los datos de otros módulos. Aquí se documentan los **agregados** que
> aceleran los cálculos y los **filtros** estándar.

---

## `resumen_ventas_diario/{empresaId_fecha}`

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa |
| fecha | string | Fecha (`YYYY-MM-DD`) |
| totalVentas | number | Valor total vendido |
| numeroVentas | number | Cantidad de ventas |
| totalContado | number | Ventas de contado |
| totalCredito | number | Ventas a crédito |
| utilidad | number | Utilidad del día |
| porVendedor | map | uid → total |
| porMedioPago | map | medio → total |
| fechaCalculo | timestamp | Última actualización |

---

## `resumen_inventario/{empresaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa |
| valorizacionTotal | number | Σ (stock × costo) |
| itemsBajoStock | number | Cantidad de productos bajo el mínimo |
| itemsAgotados | number | Cantidad agotados |
| rotacion | map | productoId → rotación |
| fechaCalculo | timestamp | Última actualización |

---

## `resumen_cartera/{empresaId}`

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa |
| totalCartera | number | Saldo total por cobrar |
| carteraVencida | number | Saldo vencido |
| clientesMorosos | number | Cantidad de clientes en mora |
| recaudoMes | number | Recaudado en el mes |
| fechaCalculo | timestamp | Última actualización |

---

## Filtro estándar (`FiltroReporte`)

| Campo | Tipo | Descripción |
|---|---|---|
| empresaId | string | Empresa |
| desde | timestamp | Inicio del rango |
| hasta | timestamp | Fin del rango |
| vendedorUid | string | Filtro por vendedor |
| clienteId | string | Filtro por cliente |
| productoId | string | Filtro por producto |
| tipoVenta | string | `contado` \| `credito` |
| bodegaId | string | Sucursal/bodega |

---

## Fórmulas

```
utilidad         = (precioVenta - costo) * cantidad
margenPorcentaje = (precioVenta - costo) / precioVenta * 100
valorizacion     = stock * costo
rotacion         = unidadesVendidas / stockPromedio
carteraVencida   = Σ cuotas con fechaVencimiento < hoy y saldo > 0
```

---

## Reportes y su fuente

| Reporte | Fuente |
|---|---|
| Ventas | `ventas`, `resumen_ventas_diario` |
| Cartera | `creditos`, `cuotas`, `pagos_credito`, `resumen_cartera` |
| Inventario | `productos`, `movimientos_inventario`, `resumen_inventario` |
| Caja | `movimientos_caja`, `arqueos` |
| Compras | `compras`, `cuentas_por_pagar` |
| Utilidad | `ventas` (costo guardado en la venta) |
| Pedidos/Envíos | `pedidos`, `envios` |
| Panel/Consolidado | `resumen_*` de todas las empresas |

---

## Índices sugeridos

- `ventas`: `empresaId` + `fecha` (desc)
- `resumen_ventas_diario`: `empresaId` + `fecha` (desc)
- `creditos`: `empresaId` + `estado`
- `movimientos_caja`: `empresaId` + `fecha` (desc)
- `compras`: `empresaId` + `fecha` (desc)
