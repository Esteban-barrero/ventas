---
name: Formato de fechas y valores
description: Convención del proyecto para mostrar fechas y valores numéricos usando lib/core/formato/fechas.dart (dd/MM/yyyy, separador de miles, días restantes), en lugar de intl o formatos ad hoc.
---

# Formato de fechas y valores

## Regla

Usa siempre los helpers de **`lib/core/formato/fechas.dart`**. **No** agregues
`intl` ni formatees a mano en cada pantalla.

| Helper | Resultado |
|---|---|
| `formatearFecha(DateTime?)` | `dd/MM/yyyy` (o `—` si es nulo) |
| `formatearValor(num)` | Separador de miles: `1.234.567` |
| `describirDiasRestantes(int?)` | «Vence en 3 días», «Vence hoy», «Vencida hace 2 días», «Sin vencimiento» |

```dart
import '../../../core/formato/fechas.dart';

Text(formatearFecha(venta.fecha));
Text(formatearValor(venta.total));
Text(describirDiasRestantes(licencia.diasRestantes(DateTime.now())));
```

## Convenciones

- Formato de fecha: **español/CO**, `dd/MM/yyyy`.
- Los **valores** usan punto como separador de miles (sin decimales; redondea).
- En **Firestore**, las fechas se guardan como **ISO-8601 UTC**
  (`DateTime.toUtc().toIso8601String()`) y se leen con un parser que tolera
  `String`, `DateTime` y `Timestamp` (ver `fromMap` de cada modelo).

## Notas

- No metas lógica de zona horaria en la UI: se muestra la fecha tal cual viene.
- Para nuevos formatos (moneda con decimales, etc.) **extiende**
  `core/formato/fechas.dart` en vez de crear utilidades sueltas.
