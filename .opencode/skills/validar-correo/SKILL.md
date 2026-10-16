---
name: Validar correo
description: Convención del proyecto para validar correos electrónicos. Usa el helper esCorreoValido de lib/core/validacion/correo.dart en formularios y en el dominio, en lugar de comprobar solo que el texto contenga "@".
---

# Validación de correo

## Regla

Valida los correos con el helper compartido **`esCorreoValido`**
(`lib/core/validacion/correo.dart`).

**No** uses validaciones ingenuas tipo `texto.contains('@')` ni dupliques
expresiones regulares en cada formulario.

```dart
import '../../../core/validacion/correo.dart';

// En un validador de campo:
if (texto.isNotEmpty && !esCorreoValido(texto)) {
  return 'Correo no válido';
}

// En el dominio:
if (correo.isNotEmpty && !esCorreoValido(correo)) {
  errores.add('El correo no es válido.');
}
```

## Dónde se usa hoy

- `features/clientes/domain/validar_cliente.dart`
- `features/empresas/domain/empresa.dart` (`DatosEmpresa.validar`)
- `features/empresas/presentation/empresa_form_screen.dart`
- `features/auth/presentation/login_screen.dart`

## Alcance

`esCorreoValido` comprueba un formato razonable (`algo@dominio.ext`); **no** es
una validación RFC completa ni verifica que el buzón exista. Los campos de
correo suelen ser **opcionales**: solo valida cuando el texto no está vacío.
