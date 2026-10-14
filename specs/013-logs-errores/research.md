# Investigación y Decisiones: Logs de Errores

- **ID:** 013 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesitan logs de error para el rol **Developer**, con módulo, opción, acción, quién, fecha,
archivo, línea, código, descripción y stack trace, visibles del más reciente al más antiguo.

## 2. Opciones Evaluadas

### 2.1. Mecanismo de captura

| Opción | Ventajas | Desventajas |
|---|---|---|
| try/catch manual | Control fino | Se olvidan puntos |
| **Handlers globales de Flutter** | Captura todo | Requiere parsear el stack |
| Crashlytics / Sentry | Potente, APM | Dependencia externa / costo |

**Decisión:** **Handlers globales** (`FlutterError.onError`, `PlatformDispatcher.onError`,
`runZonedGuarded`) escribiendo a Firestore. Se puede **integrar Crashlytics** después.

### 2.2. Extracción de archivo/línea

| Opción | Ventajas | Desventajas |
|---|---|---|
| Solo el stack completo | Simple | Difícil de ubicar |
| **Parsear el primer frame de la app** | Da archivo y línea exactos | Depende del formato |

**Decisión:** **Parsear** el stack (paquete `stack_trace`) para `archivo` y `linea`.

### 2.3. Control de ruido

| Opción | Ventajas | Desventajas |
|---|---|---|
| Guardar cada ocurrencia | Completo | Mucho volumen |
| **Agrupar por huella (fingerprint)** | Menos ruido | Se pierde el conteo exacto sin contador |

**Decisión:** **Huella** = hash(código + archivo + línea); se agrupa y se guarda un **contador**.

### 2.4. Acceso

**Decisión:** **Exclusivo del rol Developer** (regla de Firestore `esDeveloper()`).

### 2.5. Offline

**Decisión:** **Encolar** localmente y enviar al reconectar (nada se pierde).

### 2.6. Datos sensibles

**Decisión:** **Enmascarar** campos como contraseña, token, correo (según configuración).

## 3. Preguntas Abiertas

- ¿Alertas automáticas por correo al Developer? (después)
- ¿Integración con Crashlytics? (evaluar)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11 Logs de errores y 12.
- Flutter — `FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`.
- Paquete `stack_trace`.
