# Plan Técnico: <NOMBRE DE LA FUNCIONALIDAD>

- **ID:** <NNN> | **Spec:** [`spec.md`](./spec.md)
- **Fecha:** <YYYY-MM-DD>
- **Estado:** Borrador | Aprobado

---

## 1. Resumen Técnico

<Cómo se construirá la funcionalidad a nivel técnico.>

## 2. Arquitectura

<Componentes de Flutter, Cloud Functions, Firestore y Storage involucrados.
Diagrama de flujo si aplica.>

## 3. Estructura de Carpetas (Flutter)

```
lib/features/<feature>/
├── data/          # repositorios, fuentes de datos
├── domain/        # entidades, casos de uso
└── presentation/  # pantallas, widgets, providers
```

## 4. Modelo de Datos

<Colecciones de Firestore y campos. Ver `data-model.md`.>

## 5. Contratos / Interfaces

<Funciones de Cloud Functions, reglas de Firestore y APIs.
Ver carpeta `contracts/`.>

## 6. Reglas de Seguridad (Firestore Rules)

<Reglas por rol y por `empresaId`.>

## 7. Dependencias y Librerías

- `firebase_core`, `firebase_auth`, `cloud_firestore`, ...

## 8. Estrategia de Pruebas

<Qué se prueba y con qué (unit, widget, integration).>

## 9. Riesgos

- ...

## 10. Decisiones Técnicas (ADR)

- ...
