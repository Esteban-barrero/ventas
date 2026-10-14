# Plan Técnico: Proveedores y Compras

- **ID:** 007 | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** 2026-10-14
- **Estado:** Borrador

---

## 1. Resumen Técnico

Feature `compras` en Flutter. La confirmación de una compra es una **transacción** que suma
inventario, actualiza costos y registra la cuenta por pagar. Los **anexos** se suben a
**Firebase Storage** y sus metadatos a la subcolección `compras/{id}/anexos`.

## 2. Arquitectura

```
Flutter (proveedores_list, compras_list, compra_form, anexos)
   │
ProveedoresRepository ──► Firestore: proveedores
ComprasRepository   ──► Firestore: compras + anexos (transaction)
   └─ Storage: subir factura / PDF / anexos
   └─ si credito -> cuentas_por_pagar
   └─ movimientos_inventario (entrada)
```

## 3. Estructura de Carpetas (Flutter)

```
lib/features/compras/
├── data/
│   ├── proveedores_repository.dart
│   ├── compras_repository.dart
│   └── models/{proveedor_model,compra_model,anexo_model}.dart
├── domain/
│   ├── entities/{proveedor,compra,item_compra,anexo}.dart
│   └── usecases/calcular_totales_compra.dart
└── presentation/
    ├── proveedores_list_screen.dart
    ├── proveedor_form_screen.dart
    ├── compras_list_screen.dart
    ├── compra_form_screen.dart
    ├── anexos_widget.dart
    └── providers/compras_provider.dart
```

## 4. Modelo de Datos

Ver [`data-model.md`](./data-model.md). Colecciones: `proveedores`, `compras`, `compras/{id}/anexos`, `cuentas_por_pagar`.

## 5. Escaneo y Anexos

- **Escanear factura:** `image_picker` (cámara) → comprimir con `flutter_image_compress`.
- **Subir PDF:** `file_picker` (permite elegir PDF).
- Almacenamiento: `empresas/{empresaId}/compras/{compraId}/{timestamp}_{nombre}`.
- Metadatos en `compras/{compraId}/anexos/{anexoId}`.

## 6. Contratos / Interfaces

Ver [`contracts/compras-contracts.md`](./contracts/compras-contracts.md).

- `ComprasRepository.registrar(compra)` (transacción)
- `ComprasRepository.subirAnexo(compraId, archivo, tipo)`
- `ComprasRepository.anular(compraId, motivo)`

## 7. Reglas de Seguridad

```
match /compras/{compraId} {
  allow read: if esSuperAdmin() || esRolInternoDe(resource.data.empresaId);
  allow create, update: if esAdminDeEmpresa(resource.data.empresaId) ||
                           esGerenteDe(resource.data.empresaId);
  allow delete: if false;
}

match /compras/{compraId}/anexos/{anexoId} {
  allow read, create: if esAdminDeEmpresa(resource.data.empresaId);
  allow delete: if esSuperAdmin();
}
```

Storage:
```
match /empresas/{empresaId}/compras/{compraId}/{archivo} {
  allow read: if request.auth.token.empresaId == empresaId && esRolInterno();
  allow write: if request.auth.token.empresaId == empresaId &&
    request.auth.token.roles.hasAny(['administrador','gerente','cajero']) &&
    request.resource.size < 10 * 1024 * 1024;
}
```

## 8. Dependencias y Librerías

- `firebase_core`, `cloud_firestore`, `firebase_storage`
- `image_picker`, `file_picker`, `flutter_image_compress`
- `intl`, `flutter_riverpod`

## 9. Estrategia de Pruebas

- **Unit:** totales de compra, actualización de costo.
- **Widget:** formulario de compra, widget de anexos.
- **Integration:** compra que suma inventario y sube un anexo.

## 10. Riesgos

- Archivos pesados → comprimir y limitar tamaño.
- Anulación con inventario ya consumido → validar y advertir.
- Productos nuevos en la compra → crear o asociar.

## 11. Decisiones Técnicas (ADR)

- **ADR-001:** Anexos como **subcolección** con metadatos; archivos en Storage.
- **ADR-002:** Compra confirmada en **transacción** (inventario + costo + cuentas por pagar).
- **ADR-003:** Almacenamiento con marca de tiempo para no sobreescribir anexos.
- **ADR-004:** Actualización de costo de producto **configurable** por empresa.
