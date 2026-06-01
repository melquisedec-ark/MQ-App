# Build y Distribucion para Linux y macOS

## Arquitectura General

Los ejecutables de Linux y macOS se compilan mediante **GitHub Actions** y se
suben a **GitHub Releases**. La landing page (`melquisedec-ark.github.io`)
detecta automaticamente los assets via la API de GitHub y ofrece los enlaces
de descarga.

```
Flujo de trabajo:

  workflow_dispatch o push tag v*
           |
    GitHub Actions Runner
           |
    flutter build --release
           |
    Empaquetado (tar.gz / .dmg)
           |
    GitHub Release (via tag) o Artifact (workflow_dispatch)
           |
    Landing Page -> fetchLatestRelease() -> enlace de descarga
```

## Workflows Disponibles

| Archivo | Plataforma | Runner | Output |
|---------|-----------|--------|--------|
| `build_windows.yml` | Windows | `windows-latest` | `MQ_App-windows-x64.zip` |
| `build_linux.yml` | Linux | `ubuntu-latest` | `MQ_App-linux-x64.tar.gz` |
| `build_macos.yml` | macOS | `macos-latest` | `MQ_App-macos-x64.dmg` |
| `build_ios.yml` | iOS | `macos-latest` | `MQ_App-unsigned.ipa` |

Los workflows son **independientes** entre si. Se pueden ejecutar por separado.

## Como Disparar un Build Manual

1. Ir a https://github.com/moy385/HimnarioID_2.0/actions
2. Seleccionar el workflow deseado:
   - "Build Linux (.tar.gz)"
   - "Build macOS (.dmg)"
3. Click **"Run workflow"**
4. Opcional: ingresar un version label (ej: `2.0.1`)
5. Click **"Run workflow"** (verde)

El build tarda aproximadamente:
- Linux: ~5-10 minutos
- macOS: ~10-20 minutos (la primera vez descarga Flutter SDK)

Cuando termine, el `.tar.gz` o `.dmg` queda como **artifact descargable**
desde la pagina del workflow run.

## Como Hacer un Release (para Landing Page)

Para que los assets aparezcan en la landing page, deben estar en una
**GitHub Release**. Hay dos formas:

### Opcion A: Push de Tag (automatico)

```bash
# Desde tu terminal local
git tag v2.0.1
git push origin v2.0.1
```

Esto dispara todos los workflows automaticamente. Al terminar, cada uno
sube su asset a la Release `v2.0.1`.

### Opcion B: Workflow Dispatch + Release manual

1. Dispara cada workflow manualmente (pasos de la seccion anterior)
2. Descarga los `.tar.gz` y `.dmg` de los artifacts
3. Crea una Release manual en GitHub:
   - https://github.com/moy385/HimnarioID_2.0/releases/new
   - Tag: `v2.0.1`
   - Sube los archivos descargados como assets
4. La landing page los detectara automaticamente

## Convencion de Nombres de Assets

La landing page busca assets por **substring** en el nombre del archivo.
Los patrones actuales son:

| Platform | Patron de busqueda | Asset esperado |
|----------|-------------------|----------------|
| Windows  | `windows`         | `MQ_App-windows-x64.zip` |
| Linux    | `linux`           | `MQ_App-linux-x64.tar.gz` |
| macOS    | `mac`             | `MQ_App-macos-x64.dmg` |
| Android ARM64 | `arm64-v8a`  | `MQ_App-arm64-v8a.apk` |
| Android ARM32 | `armeabi-v7a` | `MQ_App-armeabi-v7a.apk` |
| Android x86_64 | `x86_64`    | `MQ_App-x86_64.apk` |

**IMPORTANTE**: No cambiar las keywords `linux`, `mac`, `windows` etc.
en los nombres de archivo, porque la landing page los busca asi.

## Costos

El repositorio `moy385/HimnarioID_2.0` es **publico**, por lo que todos
los runners de GitHub Actions son **gratis e ilimitados**:
- `ubuntu-latest` (Linux): sin costo
- `windows-latest` (Windows): sin costo
- `macos-latest` (macOS): sin costo

Si el repositorio se volviera privado, macOS consumiria 10x minutos del
plan de GitHub Actions.

## Code Signing (macOS)

Actualmente los builds de macOS se generan con `--no-codesign`.

### Sin firma (gratis, actual)
- Gatekeeper bloquea la app al abrirla
- El usuario debe ir a:
  `Preferencias del Sistema > Privacidad y Seguridad > Abrir de todas formas`
- Es el mismo comportamiento que con `.ipa` sin firmar

### Con firma (requiere Apple Developer Program)
- Costo: $99/año (individual)
- Permite que la app se abra sin advertencias
- Requiere configurar secrets en GitHub:
  - `MACOS_CERTIFICATE_BASE64` — certificado Developer ID (.p12 en base64)
  - `MACOS_CERTIFICATE_PASSWORD` — password del .p12
  - `MACOS_NOTARIZATION_APPLE_ID` — Apple ID
  - `MACOS_NOTARIZATION_TEAM_ID` — Team ID
  - `MACOS_NOTARIZATION_APP_SPECIFIC_PASSWORD` — App-specific password

  Para implementar la firma, agregar estos pasos en `build_macos.yml`:

```yaml
- name: Import certificate
  if: ${{ secrets.MACOS_CERTIFICATE_BASE64 != '' }}
  env:
    CERT_BASE64: ${{ secrets.MACOS_CERTIFICATE_BASE64 }}
    CERT_PWD: ${{ secrets.MACOS_CERTIFICATE_PASSWORD }}
  run: |
    echo "$CERT_BASE64" | base64 --decode > certificate.p12
    security create-keychain -p temp build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p temp build.keychain
    security import certificate.p12 -k build.keychain -P "$CERT_PWD" -T /usr/bin/codesign
    rm certificate.p12
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k temp build.keychain

- name: Sign and notarize .dmg
  if: ${{ secrets.MACOS_CERTIFICATE_BASE64 != '' }}
  env:
    APPLE_ID: ${{ secrets.MACOS_NOTARIZATION_APPLE_ID }}
    TEAM_ID: ${{ secrets.MACOS_NOTARIZATION_TEAM_ID }}
    APP_PWD: ${{ secrets.MACOS_NOTARIZATION_APP_SPECIFIC_PASSWORD }}
  run: |
    # Firmar el .app dentro del .dmg
    codesign --force --options runtime --sign "Developer ID Application: NAME" \
      build/macos/Build/Products/Release/Runner.app
    # Re-empaquetar .dmg con la app firmada
    # ... (regenerar .dmg)
    # Notarizar
    xcrun notarytool submit MQ_App-macos-x64.dmg \
      --apple-id "$APPLE_ID" \
      --team-id "$TEAM_ID" \
      --password "$APP_PWD" \
      --wait
    # Staple
    xcrun stapler staple MQ_App-macos-x64.dmg
```

**Recomendacion**: Empezar sin firma. Si hay traccion de usuarios y solicitudes,
considerar el Apple Developer Program en una fase posterior.

## Arquitecturas Soportadas

| Plataforma | Runner | Arquitectura | Compatibilidad |
|------------|--------|-------------|----------------|
| Linux      | `ubuntu-latest` | x86_64 | Cualquier Linux con glibc >= 2.31 (Ubuntu 20.04+) |
| macOS      | `macos-latest` | ARM64 (Apple Silicon) | Mac M1/M2/M3/M4 nativo + Intel via Rosetta 2 |

Si se necesita compilar para macOS Intel, cambiar el runner a `macos-13`
(Intel, macOS 13 Ventura). Sin embargo, el binario ARM64 corre en Intel
via Rosetta 2 sin problemas perceptibles.

## Dependencias del Proyecto

Las siguientes dependencias de `himnario_id_2` son compatibles con ambas
plataformas sin cambios adicionales:

| Dependencia | Linux | macOS |
|------------|-------|-------|
| `sqflite_common_ffi` | ✅ SQLite nativo incluido | ✅ SQLite nativo incluido |
| `window_manager` | ✅ GTK window | ✅ Cocoa window |
| `desktop_multi_window` | ✅ GTK | ✅ Cocoa |
| `grpc` | ✅ Dart puro | ✅ Dart puro |
| `nsd` (mDNS) | ✅ Avahi | ✅ Bonjour |
| `audioplayers` | ✅ GStreamer | ✅ AVFoundation |

## Mantenimiento

### Actualizar version de Flutter

Los workflows usan `subosito/flutter-action@v2` con `channel: stable`.
Para fijar una version especifica, agregar:

```yaml
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.41.9'  # version especifica
    channel: 'stable'
    cache: true
```

### Cache

- `subosito/flutter-action` con `cache: true` cachea el SDK de Flutter
  entre builds, reduciendo el tiempo de setup de ~2 min a segundos.
- Para limpiar el cache (si hay problemas):
  GitHub.com > repo > Actions > Caches > Delete

### Troubleshooting

#### Linux: "version `GLIBC_X.XX' not found"

Ocurre si el runner de Ubuntu es muy nuevo. Solucion:
- Cambiar `runs-on: ubuntu-latest` a `runs-on: ubuntu-22.04`
- O compilar en Ubuntu 20.04 para maxima compatibilidad

#### macOS: Gatekeeper bloquea la app

La app no esta firmada. El usuario debe:
1. Intentar abrir la app → aparece "no se puede abrir"
2. Ir a Preferencias del Sistema > Privacidad y Seguridad
3. Click "Abrir de todas formas" junto al nombre de la app
4. Click "Abrir" en el dialogo de confirmacion

#### El asset no aparece en la landing page

1. Verificar que el asset este subido a GitHub Releases
2. Verificar que el nombre contenga la palabra clave (`linux`, `mac`, etc.)
3. La landing page solo busca en la **latest release** (la mas reciente)
4. Esperar ~5 minutos (GitHub API cachea las releases)

## Pruebas Locales

Para probar el build de Linux localmente:

```bash
flutter config --enable-linux-desktop
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
flutter pub get
flutter build linux --release
# Output en: build/linux/x64/release/bundle/
tar -czf MQ_App-linux-x64.tar.gz -C build/linux/x64/release bundle/
```

Para probar el build de macOS localmente (solo en Mac):

```bash
flutter config --enable-macos-desktop
flutter pub get
flutter build macos --release
# Output en: build/macos/Build/Products/Release/Runner.app
```
