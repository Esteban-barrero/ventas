# Guía Rápida: Parámetros Generales y Tema

- **ID:** 014 | **Fecha:** 2026-10-14

---

## Cambiar los colores (paleta / tema)

1. Módulo **Parámetros** → **Paletas**.
2. Opciones:
   - **Crear** una paleta nueva.
   - **Editar** la actual.
   - **Duplicar** una existente.
   - **Eliminar** una que no uses.
3. Definir los colores: primario, secundario, acento, fondo, texto, éxito, advertencia, error.
4. **Activar** la paleta.
5. El tema **cambia al instante** (tiempo real), sin reiniciar.

> Cada empresa tiene **sus propias** paletas.

## Subir el logo

1. Parámetros → **Logo**.
2. Elegir la imagen (**PNG/JPG**).
3. Definir el **tamaño en píxeles** (ej. **512 × 512**).
4. Validaciones:
   - Peso máximo ~**500 KB**.
   - Dimensiones correctas.
5. Guardar. Se previsualiza en **móvil y web**.

## Licencia

| Campo | Descripción |
|---|---|
| Plan | **Mensual** o **anual** |
| Fecha inicio | Cuándo empieza |
| Fecha fin | Cuándo termina |

### Al vencer

- Se **bloquea el ingreso**.
- Se muestra un **mensaje** de licencia vencida con el **contacto del proveedor**.

## Avisos de vencimiento

- Se envían **antes** de que venza, a **`diasAvisoVencimiento`** días (por defecto **5**).
- Canales:
  - **Correo electrónico**
  - **Dentro de la aplicación**

## Parámetros generales

| Parámetro | Ejemplo |
|---|---|
| Moneda | COP ($) |
| Impuesto | 19% |
| Interés de crédito | 10% |
| Días de mora | 30 |
| Costo de envío por defecto | 5.000 |
| WhatsApp | 3001234567 |
| Telegram (chatId) | -1001234567890 |

## Estados de la licencia

| Estado | Significado |
|---|---|
| `activa` | Vigente, sin aviso pendiente |
| `por_vencer` | Dentro de los días de aviso |
| `vencida` | Bloqueada |
| `suspendida` | Suspendida por el proveedor |

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/parametros-contracts.md`](./contracts/parametros-contracts.md)
