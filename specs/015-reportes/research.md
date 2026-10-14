# Investigación y Decisiones: Reportes

- **ID:** 015 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesitan reportes de ventas, cartera, inventario, caja, compras y utilidades, con filtros por
fecha, gráficos, exportación y una vista consolidada para el Super Admin.

## 2. Opciones Evaluadas

### 2.1. Cálculo de los reportes

| Opción | Ventajas | Desventajas |
|---|---|---|
| Consultar todo en vivo | Datos siempre frescos | Lento con volumen alto |
| **Agregados/resúmenes precalculados** | Rápido | Requiere reproceso |
| Motor externo (BigQuery) | Muy potente | Mayor complejidad/costo |

**Decisión:** **Agregados** propios (`resumen_*`) actualizados por Cloud Functions, con consultas
en vivo para detalle. BigQuery se evalúa a futuro.

### 2.2. Utilidad exacta

| Opción | Ventajas | Desventajas |
|---|---|---|
| Costo actual del producto | Fácil | Distorsiona períodos pasados |
| **Costo guardado en la venta** | Exacto | Ocupa un campo más |

**Decisión:** **Guardar el costo al momento de la venta** para calcular la utilidad real.

### 2.3. Exportación

**Decisión:** **PDF** (presentación), **Excel** (análisis) y **CSV** (integraciones).

### 2.4. Gráficos

**Decisión:** `fl_chart` (barras, líneas, torta).

### 2.5. Acceso

**Decisión:** **Vendedor** solo sus ventas; **Administrador/Gerente** toda la empresa; **Super Admin**
el consolidado global.

### 2.6. Reportes programados

**Decisión:** **Opcional**; envío por correo con Cloud Scheduler + Cloud Function.

## 3. Preguntas Abiertas

- ¿Integración con Power BI / BigQuery? (mejora)
- ¿Reportes por sucursal? (previsto)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, sección 11 Reportes.
- `fl_chart`, `pdf`, `excel`, `csv`.
