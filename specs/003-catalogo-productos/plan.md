# Plan Técnico: Catálogo de Productos

- **ID:** 003 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature de Flutter `catalogo` con Firestore para los datos y **Firebase Storage** para las
imágenes. El **cálculo de precio** vive en una capa `domain` reutilizable (usada también por
Ventas y Carrito). El stock se actualiza con **transacciones** para evitar inconsistencias.

## 2. Arquitectura

```
Flutter (presentation: catalogo, producto_form)
   │
ProductosRepository (data)
   ├─► Firestore: productos, categorias
   └─► Storage: imagenes (comprimir con image_picker + flutter_image_compress)

domain:
   ├─ CalcularPrecio(costo, margen, tipoVenta)
   └─ CalcularEnvio(producto, parametros)
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/catalogo/
├── data/
│   ├── productos_repository.dart
│   ├── categorias_repository.dart
│   └── models/producto_model.dart
├── domain/
│   ├── entities/producto.dart
│   ├── entities/categoria.dart
│   └── usecases/calcular_precio.dart
└── presentation/
    ├── catalogo_screen.dart
    ├── producto_detalle_screen.dart
    ├── producto_form_screen.dart
    ├── categorias_screen.dart
    └── providers/catalogo_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `productos`, `categorias`.

## 5. Lógica de Precios (domain)

```
precio(costo, margenPct) = costo * (1 + margenPct / 100)

margenEfectivo(producto, tipoVenta):
  si producto.margenes[tipoVenta] != null -> producto.margenes[tipoVenta]
  sino -> empresa.parametros.margen[tipoVenta]

costoEnvio(producto):
  si producto.costoEnvio != null -> producto.costoEnvio
  sino -> empresa.parametros.costoEnvio
```

## 6. Contratos / Interfaces

Ver [`contracts/catalogo-contracts.md`](./contracts/catalogo-contracts.md).

- `ProductosRepository` (CRUD, búsqueda, por categoría)
- `subirImagenProducto(empresaId, productoId, file)`
- Reglas de Storage y Firestore

## 7. Reglas de Seguridad

```
match /productos/{productoId} {
  allow read: if request.auth != null &&
    resource.data.empresaId == request.auth.token.empresaId;
  allow read: if esSuperAdmin();
  allow write: if esAdminOMarketingDeEmpresa(request.resource.data.empresaId);
}
```
- Los clientes pueden leer el catálogo de su empresa.
- Solo Administrador y Marketing escriben.

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`, `firebase_storage`
- `image_picker`, `flutter_image_compress`, `cached_network_image`
- `flutter_riverpod`

## 9. Estrategia de Pruebas

- **Unit:** `calcular_precio` (contado/crédito, general/individual), `costoEnvio`.
- **Widget:** catálogo, formulario de producto, validaciones.
- **Integration:** subida de imagen y actualización de stock con transacción.

## 10. Riesgos

- **Búsqueda:** Firestore no hace *full-text search* → usar filtros por prefijo o Algolia/Extension.
- **Stock concurrente:** usar transacciones para evitar sobreventa.
- **Imágenes:** peso y formatos → comprimir y validar.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Lógica de precio en `domain` compartida por Catálogo, Ventas y Carrito.
- **ADR-002:** Compresión de imágenes en cliente antes de subir.
- **ADR-003:** Stock con transacciones de Firestore.
- **ADR-004:** Búsqueda simple por prefijo (evaluar Algolia más adelante).
