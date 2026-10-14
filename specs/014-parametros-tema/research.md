# Investigación y Decisiones: Parámetros Generales y Tema

- **ID:** 014 | **Fecha:** 2026-10-14

---

## 1. Contexto

Se necesita configuración por empresa: paletas de colores configurables y aplicadas en tiempo real,
logo con tamaño en píxeles, licencia con vencimiento y bloqueo, y avisos de vencimiento (correo e
in-app) con días configurables.

## 2. Opciones Evaluadas

### 2.1. Aplicación del tema

| Opción | Ventajas | Desventajas |
|---|---|---|
| Tema fijo en el código | Simple | No personalizable |
| Tema cargado al iniciar | Personalizable | Requiere reinicio |
| **Stream de la paleta activa** | **Tiempo real** | Requiere gestión de estado |

**Decisión:** **Stream de la paleta activa** → el tema cambia **en tiempo real**.

### 2.2. Paletas

| Opción | Ventajas | Desventajas |
|---|---|---|
| Paleta única global | Simple | No hay marca por empresa |
| **Paletas por empresa (base + personalizada)** | Marca propia | Más datos |

**Decisión:** **Paletas por empresa**, con paletas base sugeridas por el proveedor y
personalizables (crear, editar, duplicar, eliminar).

### 2.3. Logo

| Opción | Ventajas | Desventajas |
|---|---|---|
| Sin restricciones | Flexible | Rompe el diseño |
| **Formato + peso + tamaño en píxeles** | Consistente | Hay que validar |

**Decisión:** Validar **PNG/JPG**, peso máximo (~500 KB) y **dimensiones en píxeles**
(ej. 512×512), con compresión si aplica.

### 2.4. Licencia y vencimiento

| Opción | Ventajas | Desventajas |
|---|---|---|
| Validar solo al login | Simple | No avisa a tiempo |
| **Login + job programado** | Avisa y bloquea a tiempo | Requiere Scheduler |

**Decisión:** Validación al **login** + **Cloud Function programada** diaria que avisa y bloquea.

### 2.5. Avisos

**Decisión:** **Correo + in-app** a `diasAvisoVencimiento` días del fin (por defecto **5**),
evitando repetir el mismo día.

## 3. Preguntas Abiertas

- ¿Temas individuales por usuario? (después)
- ¿Portal de autogestión de licencia? (fase posterior)

## 4. Referencias

- Documento: `Documentacion/aplicativo ventas.docx`, secciones 11 Parámetros/Tema y 12 Licencia.
- Material 3 — `ColorScheme`, `ThemeData`.
- Cloud Scheduler + Cloud Functions.
