# Guía Rápida: Auditoría

- **ID:** 012 | **Fecha:** 2026-10-14

---

## ¿Qué registra?

Toda operación sobre las colecciones auditadas:

| Operación | Qué guarda |
|---|---|
| **INSERT** | Valores nuevos |
| **UPDATE** | Por cada campo: valor anterior y valor nuevo |
| **DELETE** | Snapshot de los valores eliminados |

Más: **quién**, **cuándo**, **colección**, **documento**, **empresa** y **origen**.

## ¿Cómo se genera?

Automáticamente por **Cloud Functions** (triggers). La app **nunca** escribe auditoría.

```
Escritura en Firestore ─► Trigger Cloud Function ─► _auditoria
```

## Consultar la auditoría

1. Módulo **Auditoría** (solo roles autorizados: Administrador, Gerente, Auditor, Super Admin).
2. Aplicar **filtros**:
   - Empresa
   - Usuario
   - Colección
   - Operación (INSERT / UPDATE / DELETE)
   - Rango de fechas
   - Documento
3. Buscar por palabra/frase.
4. Abrir un registro para ver la tabla **antes / después**.
5. **Exportar** (CSV / Excel / PDF).

## Ejemplo de vista de detalle (UPDATE)

| Campo | Valor anterior | Valor nuevo |
|---|---|---|
| precioDetal | 30.000 | 32.000 |
| stockMinimo | 5 | 10 |

## Reglas clave

- Los registros son **inmutables**: no se editan ni se borran.
- Retención **mínima de 6 meses** (configurable hacia arriba).
- La escritura es **solo** de las Cloud Functions.
- Se respeta el **aislamiento multi-tenant** (cada empresa ve lo suyo).

## Retención

```
meses = max(6, config.mesesRetencion)
expiraEn = fecha + mesesRetencion
```

> Firestore borra automáticamente al pasar `expiraEn` (política TTL), nunca antes de 6 meses.

## Documentos relacionados

- [`spec.md`](./spec.md)
- [`plan.md`](./plan.md)
- [`data-model.md`](./data-model.md)
- [`contracts/auditoria-contracts.md`](./contracts/auditoria-contracts.md)
