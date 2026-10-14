# Especificación: Reportes

- **ID:** 015 | **Carpeta:** `specs/015-reportes/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Genera los **reportes** de cada empresa a partir de los datos de los demás módulos: **ventas**,
**cartera/créditos**, **inventario**, **caja**, **compras/cuentas por pagar**, **utilidades** y un
**panel general**. Con **filtros por fecha**, **gráficos** y **exportación** (PDF/Excel/CSV).
El Super Admin tiene además una **vista consolidada** de todas las empresas.

## 2. Objetivo

- Ver el desempeño del negocio en un vistazo.
- Exportar información para contabilidad o análisis.
- Detectar productos que más/menos rotan.
- Controlar la cartera y la mora.
- Conocer la utilidad real (margen).

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Administrador** | Ve todos los reportes de su empresa. |
| **Gerente** | Ve reportes de su empresa (ventas, cartera, inventario, caja). |
| **Vendedor** | Ve sus propias ventas. |
| **Marketing** | Ve reportes de productos y rotación. |
| **Super Admin** | Ve el consolidado de todas las empresas. |

## 4. Historias de Usuario

- **Como** Administrador, **quiero** ver las ventas del mes **para** saber cómo va el negocio.
- **Como** Gerente, **quiero** ver la cartera por cobrar **para** gestionar el recaudo.
- **Como** Administrador, **quiero** ver la utilidad **para** conocer mi ganancia real.
- **Como** Marketing, **quiero** ver qué productos rotan más **para** promocionarlos.
- **Como** Super Admin, **quiero** comparar las empresas **para** ver cuál crece.

## 5. Requisitos Funcionales

- RF-01 **Reporte de ventas:** por fecha, vendedor, cliente, producto, tipo (contado/crédito) y tipo de entrega.
- RF-02 **Reporte de cartera/créditos:** saldos, cuotas vencidas, mora por cliente, recaudo.
- RF-03 **Reporte de inventario:** existencias, **valorización**, bajo stock, agotados y **rotación**.
- RF-04 **Reporte de caja:** ingresos/egresos por **medio de pago**, arqueos y diferencias.
- RF-05 **Reporte de compras:** compras por proveedor y **cuentas por pagar**.
- RF-06 **Reporte de utilidades:** margen (precio − costo) por producto y total.
- RF-07 **Reporte de pedidos/envíos:** pedidos por estado y entregas cumplidas/fallidas.
- RF-08 **Filtros por rango de fechas** y por sucursal/bodega (si aplica).
- RF-09 **Gráficos** (barras, líneas, torta) en el panel.
- RF-10 **Exportación** a PDF, Excel y CSV.
- RF-11 **Panel general** con los indicadores principales (KPI) por empresa.
- RF-12 **Vista consolidada** del Super Admin (todas las empresas).
- RF-13 Reportes **programados** y envío por correo (opcional).
- RF-14 Registrar auditoría de exportaciones (opcional).

## 6. Reglas de Negocio

- RN-01 Todo reporte respeta el **aislamiento por empresa** (`empresaId`).
- RN-02 El **Vendedor** solo ve sus propias ventas.
- RN-03 La **utilidad** usa el costo vigente del producto; se documenta si es costo promedio.
- RN-04 Los **impuestos** y **descuentos** se reflejan netos en los totales según configuración.
- RN-05 Los reportes de **períodos cerrados** son de solo lectura.
- RN-06 La **valorización** es `stock × costo`.
- RN-07 Las fechas se manejan en la **zona horaria** de la empresa.
- RN-08 Los datos sensibles no se incluyen en exportaciones de roles no autorizados.

## 7. Criterios de Aceptación

- [ ] CA-01 El reporte de ventas filtra por rango de fechas y vendedor.
- [ ] CA-02 La cartera muestra saldos y mora por cliente.
- [ ] CA-03 El inventario muestra valorización y rotación.
- [ ] CA-04 La caja muestra movimientos por medio de pago.
- [ ] CA-05 La utilidad se calcula correctamente.
- [ ] CA-06 Se exporta a PDF/Excel/CSV.
- [ ] CA-07 El panel muestra los KPI por empresa.
- [ ] CA-08 El Super Admin ve el consolidado.
- [ ] CA-09 El Vendedor solo ve sus ventas.

## 8. Datos Involucrados

(consulta de otras colecciones)

- `ventas`, `pedidos`, `envios`
- `creditos`, `pagos_credito`, `clientes`
- `productos`, `movimientos_inventario`
- `cajas`, `movimientos_caja`, `arqueos`
- `compras`, `cuentas_por_pagar`, `proveedores`
- `parametros` (moneda, impuestos)
- Colecciones de **resumen** (agregados) para acelerar

## 9. Casos Borde / Errores

- Períodos sin datos → mostrar ceros, no error.
- Volumen alto → usar **agregados**/resúmenes precalculados.
- Zona horaria mal aplicada en los cortes diarios.
- Exportaciones muy grandes → paginar/limitar y generar en segundo plano.
- Costos cambiados a mitad de período → usar el costo del momento de la venta (si se guarda).
- Permiso insuficiente → ocultar/denegar.

## 10. Fuera de Alcance

- Analítica predictiva / IA de ventas.
- Integración con BI externo (Power BI, etc.) — posible mejora.
- Estado de resultados contable completo.

## 11. Dependencias

- 003 Catálogo (productos, costos).
- 004 Clientes.
- 005 Ventas.
- 006 Créditos y Cobros.
- 007 Proveedores y Compras.
- 008 Inventario.
- 009 Caja.
- 010 Pedidos y 011 Envíos.
- 014 Parámetros (moneda, impuestos, zona horaria).
- 012 Auditoría (exportaciones).
