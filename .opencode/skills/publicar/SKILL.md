---
name: Publicar y reiniciar
description: Atajo para cerrar un cambio en el aplicativo de ventas: flutter analyze, flutter test, commit con convención, push a ventas y reinicio de la app en Chrome para que el usuario pruebe.
---

# Publicar un cambio y reiniciar la app

## 1. Verificar

```bash
cd app
flutter analyze     # sin errores
flutter test        # todo pasando
```

## 2. Commit y push (siempre al repo `ventas`)

```bash
git add <archivos>          # NO incluir PNG de logos ni archivos sueltos
git commit -m "tipo(alcance): descripción"
git push origin main
```

- Formato: `feat(...)`, `fix(...)`, `docs(...)`, `chore(...)`.
- Mensajes en español, con un cuerpo breve si aplica.
- El `git push` escribe el progreso en stderr; en PowerShell el `exit code 1` es
  normal aunque el push haya funcionado (comprobar `main -> main`).

## 3. Reiniciar la app para probar

La app corre con `flutter run -d chrome --web-port=5000`. Para recargar el código
hay que **detener** el proceso anterior y lanzarlo de nuevo:

```powershell
Get-CimInstance Win32_Process -Filter "Name='dart.exe'" |
  Where-Object { $_.CommandLine -like '*flutter_tools*run*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

Luego, desde `app/`, lanzar de nuevo en segundo plano y esperar a que arranque
(~90-110 s en Web):

```
flutter run -d chrome --web-port=5000 *> <temp>\ventas_run.log
```

La app queda en **http://localhost:5000** (recargar con F5).

## Notas

- Si el cambio toca reglas, desplegarlas antes (skill **desplegar-reglas**).
- `flutter run` deja la sesión iniciada; el usuario normalmente solo recarga (F5).
