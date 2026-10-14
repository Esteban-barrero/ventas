# Guía Rápida: Catálogo de Productos

- **ID:** 003 | **Fecha:** 2026-10-14

---

## Crear un producto (Administrador / Marketing)

1. Entrar al módulo **Catálogo**.
2. Clic en **Nuevo producto**.
3. Completar: código, nombre, descripción, medidas, categoría.
4. Subir la foto principal y, si se desea, imágenes de galería.
5. Definir costo y precios (detal y por mayor).
6. Definir márgenes de contado y crédito (si no, se usan los generales).
7. Definir costo de envío (si no, se usa el general).
8. Definir stock y stock mínimo.
9. Guardar.

## Cálculo de precio

```
precio = costo * (1 + margen / 100)
```

Ejemplo: costo 20.000 con margen de contado 50% → **30.000**

| Tipo de venta | Margen | Precio |
|---|---|---|
| Contado | 50% | 30.000 |
| Crédito | 65% | 33.000 |

## Herencia

- Si el producto **no** define margen → se usa el **general** de la empresa.
- Si el producto **no** define costo de envío → se usa el **general** de la empresa.

## Stock

- Cada venta **resta** stock; cada compra **suma** stock.
- Cuando `stock <= stockMinimo` se genera una **alerta**.

## Qué ve el cliente

- Foto principal
- Nombre
- Descripción y medidas
- Precio (según su tipo: detal o mayorista)

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/catalogo-contracts.md`](./contracts/catalogo-contracts.md)
