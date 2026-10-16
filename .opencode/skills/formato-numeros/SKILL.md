---
name: Formato de números
description: Convención del proyecto para mostrar cifras y dinero (miles con punto, decimales con coma, estilo Colombia) usando formatearValor de lib/core/formato/fechas.dart. Aplica a precios, descuentos, costos, subtotales, impuestos, totales, saldos y cualquier cálculo.
---

# Formato de números (dinero y cifras)

## Regla

Usa **`formatearValor`** de `lib/core/formato/fechas.dart` para **toda cifra**
que vea el usuario: **precios, descuentos, costos, subtotales, impuestos, envío,
totales, saldos, valorización** y cualquier resultado de cálculo (no solo un
campo: es el formato global de la app).

- **Miles:** punto `.`
- **Decimales:** coma `,` con 2 dígitos, y **solo si el valor los tiene** (si son
  `,00` se omiten).
- Convención: **Colombia / es-CO**.

| Valor | `formatearValor` |
|---|---|
| `3427035` | `3.427.035` |
| `3427035.5` | `3.427.035,50` |
| `427.5` | `427,50` |
| `-2500` | `-2.500` |

```dart
import '../../../core/formato/fechas.dart';

Text(formatearValor(venta.total));
```

## No hacer

- **No** uses `intl` (`NumberFormat`) ni `toStringAsFixed` para cifras que ve el
  usuario.
- **No** cambies el separador por pantalla: el formato es **global** (un solo
  helper).

## Notas

- Los **porcentajes** (márgenes, IVA) se muestran como número + `%` (ej. `19%`),
  normalmente sin decimales.
- Las **fechas** usan `formatearFecha` (ver la skill `formato-fechas`).
- Si necesitas un formato nuevo (p. ej. con símbolo `$`), **extiende**
  `core/formato/fechas.dart` en vez de formatear a mano.
