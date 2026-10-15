# Especificación: Catálogo de Productos

- **ID:** 003 | **Carpeta:** `specs/003-catalogo-productos/`
- **Fecha:** 2026-10-14
- **Estado:** Implementado (núcleo)
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Gestiona el catálogo de productos de cada empresa: datos, descripción con **medidas**,
**fotos**, categorías, **precios** (detal y por mayor), **costo de compra**, **margen de
ganancia dual (contado y crédito)** a nivel general e individual, **costo de envío** y **stock**.

Es el insumo principal de Ventas, Carrito, Pedidos e Inventario.

## 2. Objetivo

- Tener una única fuente de verdad para los productos de cada empresa.
- Calcular precios automáticamente a partir del costo y el margen configurado.
- Mostrar al cliente (invitado o registrado) foto, nombre, descripción, medidas y precio.
- Controlar el stock y avisar cuando esté bajo.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Administrador** | CRUD completo, configura márgenes y costo de envío. |
| **Marketing** | Gestiona contenido: fotos, descripciones, medidas, categorías. |
| **Vendedor** | Consulta el catálogo y el stock (no lo modifica). |
| **Cajero** | Consulta el catálogo. |
| **Cliente / Invitado** | Solo lectura del catálogo. |

## 4. Historias de Usuario

- **Como** Administrador, **quiero** crear un producto con foto, medidas y precios **para** venderlo.
- **Como** Administrador, **quiero** definir márgenes por contado y crédito **para** calcular precios.
- **Como** Administrador, **quiero** que si no defino margen por producto se use el general.
- **Como** Marketing, **quiero** actualizar fotos y descripciones **para** mejorar el catálogo.
- **Como** Cliente, **quiero** ver foto, descripción, medidas y precio **para** decidir mi compra.
- **Como** Administrador, **quiero** recibir alertas de stock bajo **para** reabastecer.

## 5. Requisitos Funcionales

- RF-01 Crear producto: código, nombre, descripción, medidas, categoría.
- RF-02 Descripción detallada: material, dimensiones, peso, color, etc.
- RF-03 Foto principal y galería adicional (múltiples imágenes).
- RF-04 Precio de venta al detal y al por mayor.
- RF-05 Costo de compra al proveedor.
- RF-06 **Margen de ganancia dual** (contado y crédito), configurable **general** y **por producto**.
- RF-07 **Costo de envío** configurable general y por producto.
- RF-08 Control de stock por producto y **alerta de stock mínimo**.
- RF-09 Búsqueda y filtrado (nombre, código, categoría).
- RF-10 Categorías administrables.
- RF-11 Catálogo visible para clientes (invitados y registrados).
- RF-12 Activación/desactivación de productos (sin borrar historial).
- RF-13 Cálculo automático del precio según costo y margen.
- RF-14 Registro de auditoría de cambios.

## 6. Reglas de Negocio

- RN-01 **Herencia de margen:** si el producto no tiene margen propio, se usa el general de la empresa.
- RN-02 **Margen dual:** contado y crédito pueden tener porcentajes distintos.
- RN-03 Precio = costo × (1 + margen%). Se calcula distinto para contado y crédito.
- RN-04 **Costo de envío** por producto tiene prioridad sobre el general.
- RN-05 Todo producto pertenece a una empresa (`empresaId`).
- RN-06 El código del producto debe ser único por empresa.
- RN-07 El stock mínimo dispara alerta cuando el stock baja de ese valor.
- RN-08 Los productos no se eliminan físicamente (`activo = false`).
- RN-09 Precio al por mayor suele ser menor que al detal (advertencia si no lo es).

## 7. Criterios de Aceptación

- [x] CA-01 Crear un producto con foto, medidas y precios.
- [x] CA-02 El precio se calcula correctamente según costo y margen.
- [x] CA-03 Contado y crédito pueden tener márgenes distintos.
- [x] CA-04 Si no hay margen propio, se aplica el general de la empresa.
- [x] CA-05 El costo de envío individual tiene prioridad sobre el general.
- [x] CA-06 El catálogo muestra foto, nombre, descripción, medidas y precio.
- [x] CA-07 El stock se actualiza y alerta al llegar al mínimo.
- [x] CA-08 La búsqueda y el filtro por categoría funcionan.
- [x] CA-09 Un cliente solo ve productos de su empresa.

## 8. Datos Involucrados

- `productos` (datos, precios, márgenes, costo de envío, stock)
- `categorias` (por empresa)
- `imagenes` (Storage: `empresas/{empresaId}/productos/{productoId}/...`)
- `movimientos_inventario` (entradas/salidas, ver spec de Inventario)
- `_auditoria`

## 9. Casos Borde / Errores

- Código de producto duplicado dentro de la empresa.
- Producto sin foto (placeholder).
- Imagen pesada o formato no soportado.
- Margen en 0 o negativo (validación).
- Stock negativo por ventas concurrentes (usar transacciones).
- Producto con categoría eliminada.

## 10. Fuera de Alcance

- Variantes complejas (talla/color con stock independiente) — se evaluará después.
- Sinónimos/atributos dinámicos.
- Recomendaciones con IA.

## 11. Dependencias

- Funcionalidad 002 (Gestión de Empresas) para parámetros generales de margen y envío.
- Funcionalidad de Inventario (movimientos y stock).
- Funcionalidad de Proveedores y Compras (costo de compra).
