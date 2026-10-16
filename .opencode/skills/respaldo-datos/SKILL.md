---
name: Respaldo de datos
description: Cómo respaldar y restaurar la capa de datos del aplicativo (Firestore, Authentication y Storage) usando el bucket de respaldo y las regiones correctas.
---

# Respaldo de datos

El **código** vive en GitHub; los **datos** se respaldan aparte. Hay 3 capas:
**Firestore**, **Authentication** y **Storage**.

- Bucket de respaldo: **`gs://aplicativo-de-ventas-backups`**
- Debe estar en **`southamerica-east1`** (la misma región de Firestore); un
  bucket en otra región hace fallar la exportación.

## Firestore

```bash
gcloud firestore export gs://aplicativo-de-ventas-backups/firestore/<fecha>
# restaurar
gcloud firestore import gs://aplicativo-de-ventas-backups/firestore/<fecha>
```

Exportación hecha a mano por la API (sin CLI):
`POST https://firestore.googleapis.com/v1/projects/<proj>/databases/(default):exportDocuments`
con `{"outputUriPrefix":"gs://aplicativo-de-ventas-backups/firestore/<fecha>"}`.
Se consulta el estado en `GET .../operations/<id>`.

## Authentication

```bash
firebase auth:export auth_usuarios_<fecha>.json --format=json
firebase auth:import auth_usuarios_<fecha>.json
```

> Contiene datos sensibles (UIDs, correos, *claims*). `auth_usuarios*.json` está
> en `.gitignore`: **nunca** se sube al repositorio.

## Storage

```bash
gcloud storage rsync -r \
  gs://aplicativo-de-ventas-d8bcd.firebasestorage.app \
  gs://aplicativo-de-ventas-backups/storage
# restaurar (invertir origen y destino)
```

## Notas

- La exportación de Firestore respalda **documentos**; Auth y Storage van aparte.
- Para "otro lado": `gsutil -m cp -r gs://aplicativo-de-ventas-backups/firestore/<fecha> .`
