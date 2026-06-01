# Build Android - HimnarioID 2.0

## Requisitos del sistema
- Linux (probado en Ubuntu)
- Android SDK (command-line tools)
- JDK 17 (JDK 25 NO es compatible con Gradle 8.14)
- Flutter 3.x+

## Dependencias instaladas (Android SDK)
- platform 34
- build-tools 34.0.0
- platform-tools (adb)
- CMake 3.22.1

## Archivos de configuración Android
- `android/app/build.gradle.kts` — configuración de build
- `android/app/src/main/AndroidManifest.xml` — permisos y configuración
- `android/settings.gradle.kts` — settings del proyecto
- `android/gradle.properties` — propiedades de Gradle

## SQLite Multiplataforma

### El desafío
`sqflite_common_ffi` (usado para desktop Linux/Windows) NO funciona en Android.
Android requiere `sqflite` (plugin nativo con SQLite built-in).

### La solución
En `database_helper.dart` se detecta la plataforma en tiempo de ejecución:

```dart
if (Platform.isAndroid || Platform.isIOS) {
  // móvil: usar sqflite nativo
  return await mobile.openDatabase(path, version: 3, ...);
} else {
  // desktop: usar sqflite_common_ffi
  desktop.sqfliteFfiInit();
  return await desktop.databaseFactoryFfi.openDatabase(path, ...);
}
```

### Archivos modificados para multiplataforma
| Archivo | Cambio |
|---|---|
| `pubspec.yaml` | +sqflite, +sqflite_common |
| `database_helper.dart` | Platform detection + imports condicionales |
| `hymn_local_datasource.dart` | import → sqflite_common/sqlite_api.dart |
| `catalog_local_datasource.dart` | import → sqflite_common/sqlite_api.dart |
| `arreglo_local_datasource.dart` | import → sqflite_common/sqlite_api.dart |
| `user_local_datasource.dart` | import → sqflite_common/sqlite_api.dart |

## Gestión de ventanas (window_manager)
`window_manager` solo funciona en desktop. Se manejó con try-catch en `main.dart`:
```dart
try { await windowManager.ensureInitialized(); } catch (_) { }
```

## Permisos Android (AndroidManifest.xml)
```xml
INTERNET — conexión gRPC/mDNS
ACCESS_NETWORK_STATE — estado de red
MODIFY_AUDIO_SETTINGS — reproducción de audio
READ_EXTERNAL_STORAGE (maxSdkVersion=32) — archivos locales
WRITE_EXTERNAL_STORAGE (maxSdkVersion=29) — archivos locales  
CHANGE_WIFI_MULTICAST_STATE — mDNS multicast
ACCESS_WIFI_STATE — estado WiFi
```

## Cómo generar el APK

### 1. Configurar entorno (primera vez)
```bash
export JAVA_HOME=/home/melquisedec/jdk17
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_HOME=/home/melquisedec/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
flutter config --android-sdk $ANDROID_HOME
```

### 2. Build APK debug
```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
flutter build apk --debug
```
El APK se genera en: `build/app/outputs/flutter-apk/app-debug.apk`

### 3. Instalar en celular
```bash
flutter install
```
(O copiar el APK manualmente al celular)

## Solución de problemas

### Error: "25.0.3-ea" en Gradle
**Causa**: JDK 25 no es compatible con Gradle 8.14.
**Solución**: Usar JDK 17 (descargado en /home/melquisedec/jdk17).

### Error: "NOT NULL constraint failed: Version_Pais.pais"
**Causa**: La columna vieja `pais` (TEXT) quedó con NOT NULL después de la migración a `pais_id`.
**Solución**: `ALTER TABLE Version_Pais DROP COLUMN pais` con SQLite >= 3.35.0.

### APK muy grande (155MB debug)
El APK debug incluye símbolos de depuración. Para release:
```bash
flutter build apk --release
```
Esto genera un APK fat de ~65.5MB. Para APKs más pequeños:
```bash
flutter build apk --release --split-per-abi
```
Esto genera APKs ~20-30MB por arquitectura (armeabi-v7a, arm64-v8a, x86_64).
