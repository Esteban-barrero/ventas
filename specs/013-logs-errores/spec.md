# Especificación: Logs de Errores

- **ID:** 013 | **Carpeta:** `specs/013-logs-errores/`
- **Fecha:** 2026-10-14
- **Estado:** Borrador
- **Responsable:** Esteban Barrero

---

## 1. Resumen

Captura y centraliza los **errores de la aplicación** para su diagnóstico. Cada log guarda
**módulo, opción, acción, quién, fecha/hora, archivo, línea, código, descripción y stack trace**.
Se muestran **del más reciente al más antiguo** y solo el rol **Developer** puede verlos.

## 2. Objetivo

- Detectar y corregir errores rápido.
- Saber **dónde** y **cuándo** ocurrió, con **contexto** (módulo, opción, acción).
- Ver el **stack trace** y los datos exactos.
- Evitar que los errores lleguen al cliente/invitado.
- Marcar errores como **reconocidos/resueltos**.

## 3. Actores / Roles

| Rol | Acción |
|---|---|
| **Developer** | Único rol que ve y gestiona los logs de errores. |
| **Sistema** | Captura automática de excepciones (app y Cloud Functions). |
| **Administrador** | **No** accede a los logs de error (salvo delegación explícita). |

## 4. Historias de Usuario

- **Como** Developer, **quiero** ver los errores recientes **para** corregirlos rápido.
- **Como** Developer, **quiero** filtrar por módulo y severidad **para** priorizar.
- **Como** Developer, **quiero** ver el **stack trace** y la línea exacta **para** ubicar el fallo.
- **Como** Developer, **quiero** marcar un error como **resuelto** **para** llevar control.

## 5. Requisitos Funcionales

- RF-01 Capturar **automáticamente** las excepciones de la app (Flutter).
- RF-02 Capturar los errores de las **Cloud Functions**.
- RF-03 Guardar por log:
  - **Módulo**
  - **Opción**
  - **Acción**
  - **Quién** (uid, nombre, rol)
  - **Fecha/hora**
  - **Archivo**
  - **Línea**
  - **Código** de error
  - **Descripción**
  - **Stack trace**
- RF-04 Guardar contexto adicional: plataforma (Android/iOS/Web), versión de la app y del sistema.
- RF-05 **Severidad:** `info`, `warning`, `error`, `fatal`.
- RF-06 Listar **del más reciente al más antiguo**.
- RF-07 **Filtros:** módulo, severidad, usuario, rango de fechas, código.
- RF-08 **Búsqueda** por descripción/archivo.
- RF-09 Marcar como **reconocido** / **resuelto**.
- RF-10 **Acceso exclusivo** del rol Developer.
- RF-11 **Exportación** (CSV/JSON).
- RF-12 Retención configurable (por defecto 6 meses).

## 6. Reglas de Negocio

- RN-01 Solo el rol **Developer** puede leer los logs de error.
- RN-02 Los logs **no** se muestran a cliente ni invitado; el cliente ve un mensaje genérico.
- RN-03 Los logs son **inmutables** (solo cambia su estado de gestión).
- RN-04 Cada log pertenece a una empresa (`empresaId`) o es global (`sistema`).
- RN-05 El **stack trace** se trunca si es demasiado grande (con hash/adjunto).
- RN-06 No se guardan datos sensibles (contraseñas, tokens) — se **enmascaran**.
- RN-07 La captura **nunca** debe interrumpir la experiencia del usuario.
- RN-08 Se evita el **bucle**: errores del propio logger no se registran.

## 7. Criterios de Aceptación

- [ ] CA-01 Un error de la app genera su log automáticamente.
- [ ] CA-02 Un error de Cloud Function genera su log.
- [ ] CA-03 El log guarda módulo, opción, acción, archivo, línea, código y stack trace.
- [ ] CA-04 Se muestra del más reciente al más antiguo.
- [ ] CA-05 Solo el rol Developer puede verlos.
- [ ] CA-06 Se pueden filtrar por módulo y severidad.
- [ ] CA-07 Se puede marcar como resuelto.
- [ ] CA-08 No se guardan datos sensibles.

## 8. Datos Involucrados

- `logs_errores` (colección principal)
- Firebase Storage (adjuntos de stack trace grande, opcional)

## 9. Casos Borde / Errores

- Error dentro del propio manejador de errores (bucle) → protección.
- Stack trace gigante → truncar/adjuntar.
- Usuario sin sesión (error antes de login) → `usuarioUid = anonimo`.
- Offline → guardar local y enviar al reconectar.
- Errores repetidos → agrupar por `codigo`/`huella` (fingerprint).
- Volumen alto → muestreo y TTL.

## 10. Fuera de Alcance

- Monitoreo APM/crash completo tipo Crashlytics (se puede integrar después).
- Alertas automáticas por correo al Developer (fase posterior).
- IA para sugerir la corrección (mejora futura).

## 11. Dependencias

- 001 Autenticación y Roles (rol Developer, identidad).
- 002 Empresas (empresaId).
- 014 Parámetros (retención y enmascarado).
