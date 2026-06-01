# Proceso de Release

> :warning: **Importante**: NO hacer merge a `main` sin autorización del usuario.
> Todo release se hace desde `main`.

---

## Pasos para publicar un nuevo release

### 1. Verificar que los workflows de CI tengan `permissions: contents: write`

Los archivos en `.github/workflows/` deben tener:

```yaml
permissions:
  contents: write
```

Sin esto, el upload a GitHub Release falla con `HTTP 403: Resource not accessible by integration`.

### 2. Bump de versiones

Editar `pubspec.yaml`:

```yaml
version: 2.1.3+1
#        ^^^^^-- version semantica
#             ^^-- build number (opcional)
```

Si el asset DB cambió, también editar `assets/db/db_version.json`:

```json
{"version": 3}
```

### 3. Commit + push

```bash
git add -A
git commit -m "chore: bump version to 2.1.3"
git push origin main
```

### 4. Build APKs Android (local)

```bash
export JAVA_HOME=/home/melquisedec/jdk17
./scripts/build_apk.sh 2.1.3
```

Esto genera:
- `build/app/outputs/flutter-apk/mq-app-arm64-v8a-<version>.apk`
- `build/app/outputs/flutter-apk/mq-app-armeabi-v7a-<version>.apk`
- `build/app/outputs/flutter-apk/mq-app-x86_64-<version>.apk`

### 5. Crear tag + release

```bash
git tag v2.1.3
git push origin v2.1.3
gh release create v2.1.3 --title "v2.1.3 — ..." --notes "..."
```

### 6. Subir APKs al release

```bash
cd build/app/outputs/flutter-apk
gh release upload v2.1.3 mq-app-arm64-v8a-2.1.3.apk --clobber
gh release upload v2.1.3 mq-app-armeabi-v7a-2.1.3.apk --clobber
gh release upload v2.1.3 mq-app-x86_64-2.1.3.apk --clobber
```

### 7. Disparar CI builds (workflow_dispatch)

```bash
gh workflow run "Build Linux (.tar.gz)" --ref main -f version=v2.1.3
gh workflow run "Build Windows .exe" --ref main -f version=v2.1.3
gh workflow run "Build macOS (.dmg)" --ref main -f version=v2.1.3
```

Los workflows:
- Buildcan desde el código en `main`
- Suben automáticamente al release `v2.1.3` (gracias al input `version`)

### 8. Verificar que todos los assets se subieron

```bash
gh release view v2.1.3 --json assets --jq '.assets[].name'
```

Deben aparecer 6 assets.

### 9. Verificar landing page

La landing page (melquisedec-ark.github.io) usa la API de GitHub para obtener el último release automáticamente. Refrescar la página (Ctrl+F5) para ver el badge actualizado.

---

## Assets esperados en el release

| Asset | Plataforma | Se genera via |
|-------|-----------|---------------|
| `mq-app-arm64-v8a-<version>.apk` | Android (celulares modernos) | `scripts/build_apk.sh` (local) |
| `mq-app-armeabi-v7a-<version>.apk` | Android (celulares antiguos) | `scripts/build_apk.sh` (local) |
| `mq-app-x86_64-<version>.apk` | Android (emuladores) | `scripts/build_apk.sh` (local) |
| `MQ_App-windows-x64.zip` | Windows | CI workflow_dispatch |
| `MQ_App-linux-x64.tar.gz` | Linux | CI workflow_dispatch |
| `MQ_App-macos-x64.dmg` | macOS | CI workflow_dispatch |

---

## Errores frecuentes

### "HTTP 403: Resource not accessible by integration"

El `github.token` por defecto no tiene permisos de escritura en tag-triggered workflows. Solución: agregar `permissions: contents: write` al workflow.

### "release not found" en CI

Ocurría cuando el workflow se ejecutaba antes de que el release existiera. Solucionado con:
1. Crear el release ANTES de disparar los CI builds
2. Usar `workflow_dispatch` con input `version` en vez de depender de `github.ref_name`

### "ParserError: MissingOpenParenthesisInIfStatement" en Windows

El workflow de Windows usa `shell: powershell` por defecto, pero los comandos de `gh release upload` usan sintaxis bash. El paso de upload debe tener `shell: bash` explícito:

```yaml
- name: Upload to GitHub Release
  shell: bash
  ...
```

### "Windows build no se ejecuta"

Los workflows de Windows requieren `windows-latest` runner. Verificar que el tag tenga `v` al inicio (ej: `v2.1.3`).

### El build compila pero no se sube al release

Verificar:
1. El release existe (paso 5)
2. El workflow tiene `permissions: contents: write`
3. En dispatch: el input `version` coincide con el tag del release
4. El nombre del asset coincide con el que busca `gh release upload`

---

## Comandos utiles

```bash
# Ver assets de un release
gh release view v2.1.3 --json assets

# Subir asset a release existente
gh release upload v2.1.3 archivo.zip --clobber

# Eliminar asset de un release
gh release delete-asset v2.1.3 nombre-del-asset

# Trigger manual de Windows (sin tag)
gh workflow run "Build Windows .exe" --ref main -f version=2.1.3

# Token de GitHub (extraido del remote)
git remote -v | head -1 | sed 's/.*://' | sed 's/@.*//'
```
