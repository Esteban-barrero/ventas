# Guía Rápida: Reportes

- **ID:** 015 | **Fecha:** 2026-10-14

---

## Reportes disponibles

| Reporte | Qué muestra |
|---|---|
| **Ventas** | Por fecha, vendedor, cliente, producto, contado/crédito |
| **Cartera** | Saldos, cuotas vencidas, mora por cliente, recaudo |
| **Inventario** | Existencias, valorización, bajo stock, agotados, rotación |
| **Caja** | Ingresos/egresos por medio de pago, arqueos, diferencias |
| **Compras** | Compras por proveedor, cuentas por pagar |
| **Utilidad** | Margen por producto (precio − costo) y total |
| **Pedidos/Envíos** | Pedidos por estado, entregas cumplidas/fallidas |
| **Panel** | KPIs principales |
| **Consolidado** | Todas las empresas (solo Super Admin) |

## Cómo generar un reporte

1. Módulo **Reportes**.
2. Elegir el reporte.
3. Aplicar **filtros**:
   - **Rango de fechas** (desde/hasta)
   - Vendedor / cliente / producto
   - Tipo de venta (contado/crédito)
   - Sucursal/bodega (si aplica)
4. Ver el resultado en **tabla** y **gráfico**.
5. **Exportar** en:
   - **PDF** (presentación)
   - **Excel** (análisis)
   - **CSV** (integraciones)

## Fórmulas clave

```
utilidad         = (precioVenta - costo) × cantidad
margen           = (precioVenta - costo) / precioVenta × 100
valorización     = stock × costo
rotación         = unidadesVendidas / stockPromedio
cartera vencida  = Σ cuotas vencidas con saldo > 0
```

## Quién ve qué

| Rol | Alcance |
|---|---|
| Vendedor | **Solo sus** ventas |
| Gerente | Toda su empresa |
| Administrador | Toda su empresa |
| Marketing | Productos y rotación |
| Super Admin | **Consolidado** de todas las empresas |

## Buenas prácticas

- Usa **agregados** (resúmenes) para períodos largos: la respuesta es más rápida.
- Los reportes se calculan en la **zona horaria** de la empresa.
- Las exportaciones grandes pueden generarse en segundo plano.

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/reportes-contracts.md`](./contracts/reportes-contracts.md)
