---
name: Desplegar reglas
description: Desplegar las reglas de Firestore y Storage a Firebase usando la API de reglas (sin Firebase CLI), con los detalles de la región, el cuerpo source/release y la codificación UTF-8.
---

# Desplegar reglas de Firestore y Storage

Este proyecto **no tiene el Firebase CLI** instalado, así que las reglas se
despliegan con la **API de Firebase Rules** usando el token de la CLI
(guardado en `%USERPROFILE%\.config\configstore\firebase-tools.json`).

- Proyecto Firebase: `aplicativo-de-ventas-d8bcd`
- Firestore: región **`southamerica-east1`**
- Release de Firestore: `cloud.firestore`
- Release de Storage: `firebase.storage/aplicativo-de-ventas-d8bcd.firebasestorage.app`

## Pasos (PowerShell)

1. Refresca un access token con el `refresh_token` del configstore y el
   *client id/secret* públicos de firebase-tools.
2. Crea un **ruleset** con el contenido del archivo (cuerpo **envuelto en
   `source`**).
3. Actualiza el **release** apuntando al nuevo ruleset (cuerpo **envuelto en
   `release`**).
4. Manda el cuerpo como **UTF-8** (los `.rules` tienen acentos y se corrompen si
   se envían como ANSI).

Detalles que costaron y hay que respetar:

- `POST .../rulesets` espera `{"source":{"files":[{"name":"firestore.rules","content":"..."}]}}`.
- `PATCH .../releases/<release>` espera `{"release":{"name":"...","rulesetName":"..."}}`
  y `?updateMask=rulesetName`.
- El escape del contenido debe reemplazar `\`, `"`, y `\r`/`\n`.
- El nombre del archivo en `files[].name` debe coincidir con el de `firebase.json`
  (`firestore.rules` / `storage.rules`).

Ver el script completo en `scripts/desplegar-reglas.ps1`.

## Verificación

Tras desplegar, imprime `updateTime` del release. Si el `PATCH` devuelve 200 con
`rulesetName`, quedó aplicado.
