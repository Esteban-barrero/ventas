# Guía Rápida: Proveedores y Compras

- **ID:** 007 | **Fecha:** 2026-10-14

---

## Registrar un proveedor

1. Módulo **Proveedores** → **Nuevo proveedor**.
2. Llenar: nombre, NIT, dirección, teléfono, correo, contacto.
3. Guardar.

## Registrar una compra

1. Módulo **Compras** → **Nueva compra**.
2. Seleccionar **proveedor**.
3. Agregar **productos**, cantidades y **costo unitario**.
4. Elegir **forma de pago**: contado, crédito o transferencia.
5. Confirmar. El sistema:
   - **Suma al inventario**.
   - Actualiza el **costo** del producto (si está habilitado).
   - Crea la **cuenta por pagar** (si es a crédito).
   - Registra **auditoría**.

## Anexos legales (sustento)

1. En el detalle de la compra, sección **Anexos**.
2. Opciones:
   - **Escanear factura** (cámara).
   - **Subir PDF** de la factura.
   - **Subir otros anexos** (contratos, remesas).
3. Cada anexo muestra: nombre, tipo, fecha y **usuario que lo subió**.

## Estados de la compra

| Estado | Significado |
|---|---|
| `pendiente` | Registrada, sin pagar (o pago parcial) |
| `pagada` | Pago completo |
| `anulada` | Revertida (devuelve inventario) |

## Formas de pago

| Forma | Efecto |
|---|---|
| Contado | Sale dinero de caja |
| Transferencia | Sale dinero de la cuenta |
| Crédito | Genera cuenta por pagar |

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/compras-contracts.md`](./contracts/compras-contracts.md)
