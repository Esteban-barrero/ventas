# Guía Rápida: Logs de Errores

- **ID:** 013 | **Fecha:** 2026-10-14

---

## ¿Quién los ve?

**Solo el rol Developer.** Ni el administrador ni el cliente ni el invitado los ven.

## ¿Cómo se generan?

Automáticamente, sin que el usuario haga nada:

```
Error en la app  ─► handlers globales ─► log
Error en Functions ─► wrapper ──────────► log
```

Si el usuario no tiene internet, el log se **encola** y se envía al reconectar.

## Qué guarda cada log

| Campo | Ejemplo |
|---|---|
| Módulo | `ventas` |
| Opción | "Nueva venta" |
| Acción | "Guardar" |
| Quién | Juan Perez (`vendedor`) |
| Fecha/hora | 2026-10-14 16:40 |
| Archivo | `ventas_repository.dart` |
| Línea | 142 |
| Código | `StockInsuficienteException` |
| Descripción | "Stock insuficiente para PROD-001" |
| Stack trace | `#0 VentasRepository.registrar ...` |

## Consultar los logs (Developer)

1. Módulo **Logs de Errores**.
2. Se listan **del más reciente al más antiguo**.
3. **Filtros:** módulo, severidad, usuario, fechas, código.
4. Abrir un log para ver el **stack trace** completo.
5. Marcar como **reconocido** o **resuelto**.

## Severidades

| Severidad | Significado |
|---|---|
| `info` | Informativo |
| `warning` | Advertencia |
| `error` | Error en una operación |
| `fatal` | Error que tumbó el flujo |

## Agrupación

Los errores iguales se agrupan por **huella** (`codigo + archivo + linea`) y se cuenta el número de
**ocurrencias**, para no llenar la lista de repetidos.

## Estados

| Estado | Significado |
|---|---|
| `nuevo` | Sin revisar |
| `reconocido` | Visto, en análisis |
| `resuelto` | Corregido |

## Reglas clave

- Los logs son **inmutables** (solo cambia su estado de gestión).
- **Nunca** se guardan contraseñas ni tokens (se **enmascaran**).
- Capturan errores de **app** y de **Cloud Functions**.

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/logs-contracts.md`](./contracts/logs-contracts.md)
