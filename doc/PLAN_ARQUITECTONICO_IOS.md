# Plan Arquitectónico — Adaptación de HimnarioID 2.0 a iOS

> **Versión:** 1.0  
> **Fecha:** 2026-05-24  
> **Autor:** Equipo Arquitectura (con investigación de @curie)

---

## Índice

1. [Executive Summary](#1-executive-summary)
2. [Rol de iOS en la Arquitectura](#2-rol-de-ios-en-la-arquitectura)
3. [Archivos iOS Necesarios](#3-archivos-ios-necesarios)
4. [Estrategia de Regeneración de ios/](#4-estrategia-de-regeneración-de-ios)
5. [Adaptaciones de Código Dart](#5-adaptaciones-de-código-dart)
6. [Estrategia de Build y CI/CD](#6-estrategia-de-build-y-cicd)
7. [Plan de Implementación Priorizado](#7-plan-de-implementación-priorizado)
8. [Riesgos y Mitigaciones](#8-riesgos-y-mitigaciones)

---

## 1. Executive Summary

HimnarioID 2.0 es una app Flutter multiplataforma (Android, Windows, Linux, macOS) que actualmente **no puede buildear para iOS** porque la carpeta `ios/` está incompleta: carece de `Info.plist`, `Podfile`, `AppDelegate.swift`, Xcode project y esquemas. Además, existen 16 archivos Dart que importan `dart:io` y uno (`fullscreen_handler.dart`) que importa `window_manager` sin Platform guard, lo que causaría crash en iOS.

Este plan detalla:

1. **Qué archivos iOS crear** con contenidos exactos (Podfile con patch gRPC, Info.plist con permisos mDNS/fotos/audio, AppDelegate.swift).
2. **Qué código Dart modificar** (7 archivos requieren cambios directos; 9 más tienen `dart:io` ya protegido y no necesitan cambios).
3. **Cómo regenerar la carpeta `ios/`** sin perder configuración existente.
4. **Estrategia de build** (no podemos buildear iOS desde Linux — se requiere macOS/Xcode).
5. **Riesgos** (App Store Review, sandbox, red IPv6, costos).

### Decisión Arquitectónica Clave: iOS será solo **Cliente (Controlador)**

| Aspecto | Decisión | Justificación |
|---------|----------|---------------|
| Rol iOS | Solo **cliente** (control remoto) | iOS no es adecuado como servidor display por: (1) No hay `window_manager` para multi-ventana, (2) gRPC server en background es limitado en iOS, (3) La audiencia usa iOS como controlador, no como display |
| Servidor gRPC | Nunca iniciar en iOS | `app_initializer.dart` ya redirige iOS al branch `_initControllerDiscovery()` |
| mDNS | Usar `nsd` (ya soporta iOS vía `nsd_ios`) | No necesita migración a `flutter_bonjour`. El plugin `nsd` v5.0.1 ya tiene soporte iOS nativo |

---

## 2. Rol de iOS en la Arquitectura

### 2.1 Modo Controlador (único modo en iOS)

```
┌──────────────────────────────────────────────────────────┐
│                     iOS (iPhone/iPad)                     │
│                                                          │
│  ┌──────────┐    ┌──────────────┐    ┌────────────────┐ │
│  │  UI App  │───▶│  gRPC Client │───▶│  Display remoto │ │
│  │ (Riverpod)│   │              │    │  (Windows/Linux) │ │
│  └──────────┘    └──────────────┘    └────────────────┘ │
│       │                                                  │
│       ▼                                                  │
│  ┌──────────┐                                           │
│  │ mDNS nsd │── descubre displays en LAN                 │
│  └──────────┘                                           │
└──────────────────────────────────────────────────────────┘
```

**Flujo:**
1. iOS descubre displays en la LAN vía `nsd` (mDNS).
2. Usuario selecciona un display.
3. iOS se conecta vía gRPC al servidor del display.
4. iOS envía comandos (cargar himno, next slide, etc.).
5. iOS **nunca** inicia su propio servidor gRPC.

### 2.2 Modo Display (NO disponible en iOS)

El modo display requiere:
- Servidor gRPC escuchando en background
- `window_manager` para fullscreen + always-on-top
- `desktop_multi_window` para segunda ventana
- `Process.start` para subproceso de proyección

Ninguno de estos está disponible en iOS. `app_initializer.dart` ya maneja esto correctamente (líneas 123-129) excluyendo iOS del branch display.

### 2.3 Implicaciones del Rol Cliente

| Componente | En iOS | Acción requerida |
|------------|--------|------------------|
| `AppInitializer._initDisplayServer()` | No se ejecuta | ❌ Ninguna (ya protegido) |
| `AppInitializer._initControllerDiscovery()` | Sí se ejecuta | ✅ Funciona (usa nsd) |
| `AppInitializer._initNsdDiscovery()` | Sí se ejecuta | ✅ Ya tiene guard `Platform.isIOS` |
| `receptor_binding.dart` / `grpcDisplayServerProvider` | Retorna null | ✅ Ya protegido |
| `window_service.dart` | Retorna `MobileWindowService` | ✅ Ya protegido |
| `window_providers.dart` | Retorna `MobileWindowService` | ✅ Ya protegido |
| `fullscreen_handler.dart` | Debe saltarse | ❌ **Requiere cambio** |

---

## 3. Archivos iOS Necesarios

### 3.1 Esquema de Archivos

La carpeta `ios/` actual contiene solo:
```
ios/
├── Flutter/
│   ├── ephemeral/           ← se regenera automáticamente
│   ├── flutter_export_environment.sh
│   └── Generated.xcconfig
└── Runner/
    ├── GeneratedPluginRegistrant.h
    └── GeneratedPluginRegistrant.m
```

**Archivos faltantes que hay que crear:**

```
ios/
├── Podfile                                    ← CREAR (con patch gRPC)
├── Runner/
│   ├── Info.plist                              ← CREAR
│   ├── AppDelegate.swift                       ← CREAR
│   ├── Runner-Bridging-Header.h                ← CREAR (opcional, necesario para C plugins)
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/
│           └── Contents.json                   ← CREAR
├── Runner.xcodeproj/
│   └── project.pbxproj                        ← REGENERAR con flutter create
└── Runner.xcworkspace/                         ← REGENERAR con flutter create
```

### 3.2 Podfile (con patch gRPC para Xcode 16+)

**Ruta:** `ios/Podfile`

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    # ─── Fixes para Xcode 16+ y gRPC ────────────────────────────────
    target.build_configurations.each do |config|
      # iOS 13.0 mínimo para todos los pods (Xcode 16+ requiere >= 12.0)
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'

      # Forzar Swift 5 (Xcode 16 por defecto usa Swift 6 strict mode)
      config.build_settings['SWIFT_VERSION'] = '5.0'

      # Permitir includes no-modulares en frameworks (necesario para gRPC/BoringSSL)
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'

      # Desactivar sandboxing de scripts de usuario (necesario para CocoaPods en Xcode 16)
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'

      # Definir GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS para protobuf
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1'
    end

    # Fix específico para gRPC-Core / BoringSSL-GRPC
    if target.name == 'gRPC-Core' || target.name == 'gRPC-C++' || target.name == 'BoringSSL-GRPC'
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'GRPC_CORE=1'
      end
    end

    # Fix para abseil (necesario con CocoaPods 1.16+)
    if target.name == 'abseil'
      target.build_configurations.each do |config|
        config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'gnu++14'
      end
    end
  end
end
```

**Justificación de configuraciones:**

| Configuración | Por qué es necesaria |
|---------------|---------------------|
| `platform :ios, '13.0'` | Xcode 16 dropped soporte iOS 11; plugins modernos requieren iOS 13+. |
| `IPHONEOS_DEPLOYMENT_TARGET = '13.0'` | Forzar a todos los pods a usar iOS 13.0 para evitar warnings de deployment target mismatch. |
| `SWIFT_VERSION = '5.0'` | Xcode 16 usa Swift 6 strict mode por defecto; muchos pods no están actualizados. |
| `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES = 'YES'` | Necesario para gRPC-Core/BoringSSL que usan includes no-modulares. |
| `ENABLE_USER_SCRIPT_SANDBOXING = 'NO'` | CocoaPods en Xcode 16 necesita esto para scripts post-install. |
| `GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1` | Necesario para que protobuf funcione correctamente con gRPC. |
| `GRPC_CORE=1` | Define específica para gRPC-Core en Xcode 16+. |
| `CLANG_CXX_LANGUAGE_STANDARD = 'gnu++14'` | Fix para abseil con CocoaPods 1.16+. |

### 3.3 Info.plist

**Ruta:** `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>HimnarioID</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>himnario_id_2</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UIViewControllerBasedStatusBarAppearance</key>
	<false/>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>

	<!-- ═══ PERMISOS DE RED (mDNS / Bonjour) ═══ -->
	<key>NSLocalNetworkUsageDescription</key>
	<string>HimnarioID necesita acceso a la red local para descubrir displays de proyección y controlarlos remotamente.</string>
	<key>NSBonjourServices</key>
	<array>
		<string>_himnario._tcp</string>
		<string>_dartVmService._tcp</string>
	</array>

	<!-- ═══ PERMISOS DE ARCHIVOS ═══ -->
	<key>NSPhotoLibraryUsageDescription</key>
	<string>HimnarioID necesita acceso a la galería para seleccionar imágenes de fondo para la proyección.</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>HimnarioID necesita permiso para guardar configuraciones e himnos en tu dispositivo.</string>

	<!-- ═══ PERMISOS DE AUDIO (wakelock_plus, audioplayers) ═══ -->
	<key>UIBackgroundModes</key>
	<array>
		<string>audio</string>
	</array>
	<key>NSMicrophoneUsageDescription</key>
	<string>HimnarioID necesita acceso al micrófono para funcionalidades de audio.</string>

	<!-- ═══ CONFIGURACIÓN DE RED ═══ -->
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
</dict>
</plist>
```

**Justificación de cada clave:**

| Clave | Propósito | Riesgo si falta |
|-------|-----------|-----------------|
| `NSLocalNetworkUsageDescription` | Permiso para mDNS discovery | Crash al iniciar nsd discovery |
| `NSBonjourServices` | Registrar tipo de servicio `_himnario._tcp` | No se descubren displays |
| `_dartVmService._tcp` | Debug de Flutter en iOS | (opcional, solo debug) |
| `NSPhotoLibraryUsageDescription` | Para `file_picker` al elegir fondos | File picker no puede acceder a fotos |
| `NSPhotoLibraryAddUsageDescription` | Guardar imágenes | No puede guardar configuraciones |
| `UIBackgroundModes: audio` | Reproducción de audio en background | Audio se pausa al minimizar app |
| `NSAppTransportSecurity` | Permitir gRPC (conexiones no-HTTP) | gRPC bloqueado por ATS |
| `UIViewControllerBasedStatusBarAppearance` | Control programático de status bar | SystemChrome.immersiveSticky no funciona |

### 3.4 AppDelegate.swift

**Ruta:** `ios/Runner/AppDelegate.swift`

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Nota:** SwiftUI AppDelegate es el estándar moderno de Flutter. Si se prefiere Objective-C, se puede usar `AppDelegate.m` + `AppDelegate.h` pero Swift es recomendado por ser el default de Flutter 3.x+.

### 3.5 Runner-Bridging-Header.h (condicional)

**Ruta:** `ios/Runner/Runner-Bridging-Header.h`

Este archivo solo es necesario si algún plugin nativo requiere headers Objective-C expuestos a Swift. Para el stack actual de HimnarioID 2.0, **no es estrictamente necesario** porque:

- `audioplayers_darwin` usa Swift
- `nsd_ios` usa Objective-C pero se registra automáticamente
- `sqflite_darwin` usa Swift
- `permission_handler_apple` usa Objective-C con registro automático

Sin embargo, se recomienda crearlo vacío por si futuros plugins lo requieren:

```objc
// Bridging Header for HimnarioID iOS
// Used to expose Objective-C headers to Swift code if needed.
```

Luego configurar en Xcode: `SWIFT_OBJC_BRIDGING_HEADER = $(PROJECT_DIR)/Runner/Runner-Bridging-Header.h`

### 3.6 Assets.xcassets / AppIcon

**Ruta:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`

```json
{
  "images": [
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    },
    {
      "size": "20x20",
      "idiom": "iphone",
      "filename": "Icon-App-20x20@3x.png",
      "scale": "3x"
    },
    {
      "size": "29x29",
      "idiom": "iphone",
      "filename": "Icon-App-29x29@2x.png",
      "scale": "2x"
    },
    {
      "size": "29x29",
      "idiom": "iphone",
      "filename": "Icon-App-29x29@3x.png",
      "scale": "3x"
    },
    {
      "size": "40x40",
      "idiom": "iphone",
      "filename": "Icon-App-40x40@2x.png",
      "scale": "2x"
    },
    {
      "size": "40x40",
      "idiom": "iphone",
      "filename": "Icon-App-40x40@3x.png",
      "scale": "3x"
    },
    {
      "size": "60x60",
      "idiom": "iphone",
      "filename": "Icon-App-60x60@2x.png",
      "scale": "2x"
    },
    {
      "size": "60x60",
      "idiom": "iphone",
      "filename": "Icon-App-60x60@3x.png",
      "scale": "3x"
    },
    {
      "size": "20x20",
      "idiom": "ipad",
      "filename": "Icon-App-20x20@1x.png",
      "scale": "1x"
    },
    {
      "size": "20x20",
      "idiom": "ipad",
      "filename": "Icon-App-20x20@2x.png",
      "scale": "2x"
    },
    {
      "size": "29x29",
      "idiom": "ipad",
      "filename": "Icon-App-29x29@1x.png",
      "scale": "1x"
    },
    {
      "size": "29x29",
      "idiom": "ipad",
      "filename": "Icon-App-29x29@2x.png",
      "scale": "2x"
    },
    {
      "size": "40x40",
      "idiom": "ipad",
      "filename": "Icon-App-40x40@1x.png",
      "scale": "1x"
    },
    {
      "size": "40x40",
      "idiom": "ipad",
      "filename": "Icon-App-40x40@2x.png",
      "scale": "2x"
    },
    {
      "size": "76x76",
      "idiom": "ipad",
      "filename": "Icon-App-76x76@1x.png",
      "scale": "1x"
    },
    {
      "size": "76x76",
      "idiom": "ipad",
      "filename": "Icon-App-76x76@2x.png",
      "scale": "2x"
    },
    {
      "size": "83.5x83.5",
      "idiom": "ipad",
      "filename": "Icon-App-83.5x83.5@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  }
}
```

**Nota:** Los archivos PNG de icono deben generarse desde `iconoMQ.png` (1024x1024) usando una herramienta como `appicon` o el generador de Xcode.

---

## 4. Estrategia de Regeneración de `ios/`

### 4.1 Método recomendado: `flutter create` sobre carpeta existente

**NO** borrar la carpeta `ios/` existente. El comando:

```bash
# Desde la raíz del proyecto
flutter create --platforms=ios --project-name=himnario_id_2 .
```

**Comportamiento:**
- `flutter create` **NO sobrescribe** archivos existentes si ya existen (es idempotente).
- Crea los archivos **faltantes**: `Podfile`, `Runner/Info.plist`, `Runner/AppDelegate.swift`, `Runner.xcodeproj/project.pbxproj`, `Runner.xcworkspace/`.
- **NO borra** los archivos existentes (`GeneratedPluginRegistrant.h/.m`, `Flutter/Generated.xcconfig`, etc.).
- **Sobrescribe** `Runner/Info.plist` si ya existe (pero no existe actualmente).
- **Sobrescribe** `Podfile` si ya existe (pero no existe actualmente).
- **NO toca** `lib/`, `pubspec.yaml`, ni código Dart.

### 4.2 Archivos que `flutter create` genera y que debemos personalizar

| Archivo generado | Acción post-creación |
|-----------------|---------------------|
| `ios/Podfile` | **Sobrescribir** con el contenido del §3.2 (patch gRPC) |
| `ios/Runner/Info.plist` | **Sobrescribir** con el contenido del §3.3 (permisos) |
| `ios/Runner/AppDelegate.swift` | Verificar que coincida con §3.4 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | Verificar que incluya todos los tamaños |
| `ios/Runner.xcodeproj/project.pbxproj` | **NO tocar** — contiene config de proyecto |

### 4.3 Procedimiento paso a paso

```bash
# 1. Backup de la carpeta ios/ actual
cp -r ios/ ios_backup_$(date +%Y%m%d)

# 2. Regenerar archivos faltantes (desde raíz del proyecto)
flutter create --platforms=ios --project-name=himnario_id_2 .

# 3. Sobrescribir Podfile con el nuestro (patch gRPC)
cp /ruta/a/nuestro/Podfile ios/Podfile

# 4. Sobrescribir Info.plist con permisos
cp /ruta/a/nuestro/Info.plist ios/Runner/Info.plist

# 5. Crear Bridging Header si es necesario
touch ios/Runner/Runner-Bridging-Header.h

# 6. Limpiar y regenerar pods (solo en macOS)
flutter clean
cd ios
pod deintegrate          # si hay Podfile.lock previo
pod install --repo-update
cd ..

# 7. Verificar que build analizer pase
flutter analyze
```

### 4.4 ¡Importante! Lo que `flutter create` NO genera

- **Certificados / Provisioning Profiles** — hay que configurarlos en Apple Developer Portal.
- **Bundle Identifier** — se define en Xcode o en `project.pbxproj`. Usar un identificador como `com.tuorganizacion.himnarioid`.
- **Iconos de app** — hay que generar los PNG desde `iconoMQ.png`.
- **GoogleService-Info.plist** — solo si se usa Firebase (no es el caso actualmente).

---

## 5. Adaptaciones de Código Dart

### 5.1 Resumen de archivos con `dart:io`

| Archivo | Uso de `dart:io` | ¿Requiere cambio para iOS? | Severidad |
|---------|------------------|---------------------------|-----------|
| `lib/bootstrap/app_initializer.dart` | `Platform` | ✅ No (ya protegido con try-catch) | — |
| `lib/presentation/dual_mode_wrapper/dual_mode_providers.dart` | `Platform` | ✅ No (ya protegido con try-catch) | — |
| `lib/core/database/database_helper.dart` | `Platform, File` | ✅ No (ya tiene `Platform.isIOS`) | — |
| `lib/core/window_manager/window_providers.dart` | `Platform` | ✅ No (ya protegido con try-catch) | — |
| `lib/core/window_manager/window_service.dart` | `Directory, Platform, Process` | ✅ No (nunca se instancia en iOS) | — |
| `lib/core/network/permission_service.dart` | `Platform` | ✅ No (retorna `true` para no-Android) | — |
| `lib/presentation/views_projection/display/receptor_binding.dart` | `Platform` | ✅ No (ya protegido con try-catch) | — |
| `lib/core/database/db_version_manager.dart` | `File, Directory` | ⚠️ **Revisar** | Baja |
| `lib/core/utils/file_storage_service.dart` | `File, Directory` | ⚠️ **Revisar** | Baja |
| `lib/core/utils/audio_file_service.dart` | `File, Directory` | ⚠️ **Revisar** | Baja |
| `lib/data/datasources/local/audio_local_datasource.dart` | `File` | ⚠️ **Revisar** | Baja |
| `lib/data/datasources/remote/grpc_display_server.dart` | `ServerSocket` | ✅ No (nunca se instancia en iOS) | — |
| `lib/presentation/views_projection/display/projection_app.dart` | `stdin` | ✅ No (solo en subproceso `--projection`) | — |
| `lib/presentation/views_projection/display/live_projection_screen.dart` | `Platform` | ✅ No (solo usa `dart:io` para Platform checks) | — |
| `lib/presentation/shared_widgets/control_sheets.dart` | `Platform` | ✅ No (solo usa `dart:io` para Platform checks) | — |
| `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart` | `Platform` | ✅ No (solo usa `dart:io` para Platform checks) | — |

### 5.2 Archivos que SÍ requieren cambios

#### Archivo 1: `fullscreen_handler.dart` — Import sin guardia

**Ruta:** `lib/presentation/shared_widgets/fullscreen_handler.dart`

**Problema:** `import 'package:window_manager/window_manager.dart';` sin Platform guard. En iOS, esto no crashea en tiempo de import (Dart resuelve imports estáticamente), pero `windowManager.isFullScreen()` y `windowManager.setFullScreen()` lanzarán `MissingPluginException`.

**Solución:** Envolver en Platform check + try-catch.

**Código actual (líneas 1-4):**
```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
```

**Código propuesto:**
```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
```

**Código actual (líneas 53-60):**
```dart
  Future<void> _toggleFullScreen() async {
    try {
      final isFullScreen = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!isFullScreen);
    } catch (_) {
      // Silencioso — window_manager no disponible en esta plataforma.
    }
  }
```

**Código propuesto:**
```dart
  Future<void> _toggleFullScreen() async {
    if (kIsWeb) return;
    try {
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        return; // window_manager solo disponible en desktop
      }
      final isFullScreen = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!isFullScreen);
    } catch (_) {
      // Silencioso — window_manager no disponible en esta plataforma.
    }
  }
```

También proteger el handler de teclado:

```dart
  void _registerHandler() {
    if (kIsWeb) return;
    try {
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        return; // F11 fullscreen handler solo en desktop
      }
    } catch (_) {
      return; // Platform no disponible
    }
    // ... resto igual ...
  }
```

#### Archivo 2: `app_initializer.dart` — Platform.isMacOS para gRPC

**Ruta:** `lib/bootstrap/app_initializer.dart`

**Problema:** Líneas 123-125: `_platform == TargetPlatform.macOS` — pero en iOS esto es correcto, no entra al branch display server.

✅ **No requiere cambio.** El flujo actual es correcto:
- iOS → `_initControllerDiscovery()` → inicia mDNS discovery
- desktop → `_initDisplayServer()` → inicia servidor gRPC

Sin embargo, podemos mejorar el logging:

**Cambio opcional (línea 229):**
```dart
    } else if (_platform == TargetPlatform.linux) {
      _log.info(
        'mDNS broadcast no disponible en Linux. '
        'Usa conexión manual con la IP de esta máquina.',
      );
    } else if (_platform == TargetPlatform.iOS) {
      _log.info(
        'iOS no funciona como servidor display. '
        'Modo controlador activo.',
      );
    }
```

#### Archivo 3: `permission_service.dart` — Permisos iOS para LAN

**Ruta:** `lib/core/network/permission_service.dart`

**Problema:** Solo maneja `Permission.nearbyWifiDevices` (Android 13+). En iOS, el permiso de red local se maneja via `NSLocalNetworkUsageDescription` en Info.plist (configuración declarativa). No se requiere solicitud runtime.

✅ **No requiere cambio.** Pero para completitud, podemos agregar un log:

**Código actual (líneas 20-26):**
```dart
  static Future<bool> requestNearbyWifiPermission() async {
    if (kIsWeb) return true;
    try {
      if (!Platform.isAndroid) return true;
    } catch (_) {
      return true;
    }
```

**Código propuesto (mejora informativa):**
```dart
  static Future<bool> requestNearbyWifiPermission() async {
    if (kIsWeb) return true;
    try {
      if (Platform.isIOS) {
        // En iOS el permiso de red local se concede automáticamente
        // al declarar NSLocalNetworkUsageDescription en Info.plist.
        // No se necesita solicitud runtime.
        return true;
      }
      if (!Platform.isAndroid) return true;
    } catch (_) {
      return true;
    }
```

#### Archivo 4: `database_helper.dart` — Path de base de datos en iOS Sandbox

**Ruta:** `lib/core/database/database_helper.dart`

**Problema:** En iOS, `getApplicationDocumentsDirectory()` retorna una ruta dentro del sandbox de la app. La base de datos existente en `assets/db/himnario_id.db` debe copiarse a esta ruta.

✅ **No requiere cambio.** El código actual ya usa `getApplicationDocumentsDirectory()` (línea 59) y maneja la copia desde assets. iOS sandbox no es un problema porque `path_provider` maneja la traducción de rutas.

Sin embargo, **un riesgo iOS específico**: iOS puede eliminar archivos en `applicationDocumentsDirectory` si el dispositivo tiene poco espacio (aunque es raro con SQLite). Considerar migrar a `getApplicationSupportDirectory()` en el futuro para datos críticos.

#### Archivo 5: `window_providers.dart` — Confirmación de MobileWindowService

**Ruta:** `lib/core/window_manager/window_providers.dart`

**Problema:** Líneas 22-26: No hay check explícito para iOS, pero el catch cubre el caso.

✅ **No requiere cambio.** El flujo es:
1. `Platform.isWindows || Platform.isLinux || Platform.isMacOS` → `SubprocessWindowService`
2. catch → falla y retorna `MobileWindowService()`
3. iOS entra en el catch y obtiene `MobileWindowService()` — correcto.

**Mejora opcional (agregar iOS a comentario):**
```dart
/// - Móvil (Android, iOS): [MobileWindowService] stub (no soportado)
```

#### Archivo 6: `main.dart` — window_manager.ensureInitialized() en iOS

**Ruta:** `lib/main.dart`

**Problema:** Líneas 88-94: Se llama a `windowManager.ensureInitialized()` dentro de try-catch, lo que es seguro. iOS lanzará `MissingPluginException` y el catch lo manejará.

✅ **No requiere cambio.** El try-catch ya protege contra `MissingPluginException`.

**Pero hay un problema sutil:** En iOS, `windowManager.ensureInitialized()` lanza una excepción **asíncrona**. La excepción se captura correctamente en el catch. Sin embargo, el import `package:window_manager/window_manager.dart` en `main.dart` línea 5 podría causar problemas de compilación si el plugin no declara soporte iOS en su `pubspec.yaml`.

**Verificación:** `window_manager` v0.5.1 declara en su `pubspec.yaml`:
```yaml
platforms:
  android: null
  ios: null
  linux: null
  macos: null
  windows: null
```

`ios: null` significa que window_manager **declara soporte iOS** pero no implementa nada. Esto es suficiente para que el import compile, pero el método `ensureInitialized()` lanzará `MissingPluginException` en runtime.

✅ **Esto es seguro.** El try-catch captura la excepción runtime.

#### Archivo 7: `projection_app.dart` — stdin en iOS

**Ruta:** `lib/presentation/views_projection/display/projection_app.dart`

**Problema:** Línea 3: `import 'dart:io' show stdin;`. El subproceso `--projection` nunca se ejecuta en iOS porque `SubprocessWindowService` solo se instancia en desktop. Sin embargo, el **import** es estático y compila en todas las plataformas.

✅ **No requiere cambio.** `dart:io` está disponible en iOS (no es web). El import compila. `stdin` existe en iOS (es una terminal). El método `_setupStdinListener` envuelve el acceso en try-catch (línea 65-73).

### 5.3 Lista completa de cambios requeridos (resumen ejecutivo)

| # | Archivo | Cambio | Prioridad |
|---|---------|--------|-----------|
| 1 | `lib/presentation/shared_widgets/fullscreen_handler.dart` | Agregar Platform guard a `_toggleFullScreen()` y `_registerHandler()` | 🔴 Alta |
| 2 | `lib/core/network/permission_service.dart` | Agregar `Platform.isIOS` check explícito (opcional, mejora) | 🟡 Media |
| 3 | `lib/bootstrap/app_initializer.dart` | Agregar logging para iOS (opcional) | 🟢 Baja |
| 4–16 | Resto de archivos | Sin cambios necesarios (todos tienen Platform guards) | ✅ Ninguno |

**Total: 1 cambio obligatorio, 2 opcionales.**

---

## 6. Estrategia de Build y CI/CD

### 6.1 Realidad: No podemos buildear iOS desde Linux

El build de iOS **requiere macOS con Xcode**. Esto es una limitación ineludible de Apple.

**Opciones:**

| Opción | Descripción | Costo | Recomendación |
|--------|-------------|-------|---------------|
| 🥇 **Mac física** | Mac mini o MacBook del equipo | $599+ | ✅ Ideal para desarrollo diario |
| 🥈 **Mac en la nube** | MacStadium, MacinCloud, GitHub Actions (macOS runner) | $30-100/mes | ✅ Para CI/CD |
| 🥉 **Hackintosh** | No recomendado | $0 | ❌ Inestable, viola EULA |
| ❌ **Cross-compile desde Linux** | No es posible | — | ❌ Técnicamente inviable |

### 6.2 GitHub Actions CI/CD para iOS

Crear `.github/workflows/build_ios.yml`:

```yaml
name: Build iOS

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Build version label'
        required: false
        default: 'latest'
  push:
    tags:
      - 'v*.*.*'

jobs:
  build_ios:
    runs-on: macos-latest  # ← Requiere runner macOS
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Get dependencies
        run: flutter pub get

      - name: Clean and regenerate iOS platform
        run: |
          rm -rf ios/Pods ios/Podfile.lock ios/Runner.xcworkspace
          flutter create --platforms=ios --project-name=himnario_id_2 .

      - name: Copy custom Podfile and Info.plist
        run: |
          cp .github/ios/Podfile ios/Podfile
          cp .github/ios/Info.plist ios/Runner/Info.plist

      - name: Install pods
        working-directory: ios
        run: pod install --repo-update

      - name: Build iOS release
        run: flutter build ios --release --no-codesign

      - name: Export IPA (requires signing)
        run: |
          flutter build ios --release
          # Requires: APPLE_ID, APP_TEAM_ID, APP_BUNDLE_ID, KEYCHAIN_PASSWORD
          # See: https://docs.flutter.dev/deployment/ios

      - name: Upload build artifact
        uses: actions/upload-artifact@v4
        with:
          name: HimnarioID-iOS-${{ github.event.inputs.version || github.ref_name }}
          path: build/ios/iphoneos/Runner.app
```

**Requisitos para CI/CD iOS:**
1. Apple Developer Account ($99/año)
2. Certificados de distribución en GitHub Secrets
3. Provisioning Profile en GitHub Secrets
4. ExportOptions.plist para `flutter build ipa`

### 6.3 Configuración de Provisioning Profile (desde código)

**Crear `ios/ExportOptions.plist` para exportación automática:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>TU_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.tuorganizacion.himnarioid</key>
        <string>HimnarioID App Store Profile</string>
    </dict>
</dict>
</plist>
```

Luego:
```bash
flutter build ipa --release --export-options-plist ios/ExportOptions.plist
```

---

## 7. Plan de Implementación Priorizado

### Fase 1: Regenerar carpeta `ios/` (Seguro, sin riesgo)

**Estimación:** 30 min  
**Ejecutable desde Linux:** ✅ Sí

```bash
# 1. Backup
cp -r ios/ ios_backup_$(date +%Y%m%d)

# 2. Regenerar
flutter create --platforms=ios --project-name=himnario_id_2 .

# 3. Confirmar archivos creados
ls -la ios/Podfile
ls -la ios/Runner/Info.plist
ls -la ios/Runner/AppDelegate.swift
ls -la ios/Runner.xcodeproj/project.pbxproj
```

**Criterio de éxito:** `flutter analyze` pasa sin errores.

### Fase 2: Adaptar código Dart (1 cambio obligatorio)

**Estimación:** 1 hora  
**Ejecutable desde Linux:** ✅ Sí

1. Modificar `lib/presentation/shared_widgets/fullscreen_handler.dart` (Platform guard).
2. (Opcional) Mejorar `lib/core/network/permission_service.dart`.
3. (Opcional) Mejorar logging en `lib/bootstrap/app_initializer.dart`.

**Criterio de éxito:** Todos los tests existentes pasan (20 unit + 28 integration).

### Fase 3: Crear archivos iOS de configuración

**Estimación:** 30 min  
**Ejecutable desde Linux:** ✅ Sí

1. Copiar **Podfile** (con patch gRPC) a `ios/Podfile`.
2. Copiar **Info.plist** (con permisos) a `ios/Runner/Info.plist`.
3. Crear `Runner-Bridging-Header.h` si es necesario.
4. Generar iconos de app (desde `iconoMQ.png`).

### Fase 4: Build y prueba en macOS (requiere entorno externo)

**Estimación:** 2-4 horas  
**Ejecutable desde macOS:** ✅ Sí (requiere máquina Mac)

```bash
# En macOS

# 1. Verificar ambiente
flutter doctor
# Debe mostrar: [✓] Xcode - develop for iOS and macOS

# 2. Limpiar y regenerar
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get

# 3. Instalar pods
cd ios
pod install --repo-update
cd ..

# 4. Build para simulator
flutter build ios --debug --no-codesign

# 5. Probar en simulador
flutter run -d 'iPhone 16'

# 6. Build para dispositivo (requiere signing)
flutter build ipa --release --export-options-plist ios/ExportOptions.plist
```

### Fase 5: CI/CD (opcional pero recomendado)

**Estimación:** 4 horas  
**Ejecutable desde:** GitHub (macOS runner)

1. Agregar secretos de Apple Developer a GitHub.
2. Crear `.github/workflows/build_ios.yml`.
3. Probar build manual via `workflow_dispatch`.

---

## 8. Riesgos y Mitigaciones

### 8.1 App Store Review

| Funcionalidad | Riesgo de Rechazo | Mitigación |
|---------------|-------------------|------------|
| **NSLocalNetworkUsageDescription** | Bajo — Apple aprueba si hay descripción clara | Usar texto descriptivo (ya incluido) |
| **NSAllowsArbitraryLoads** | Medio — Apple puede rechazar si no se justifica | Justificar: gRPC usa protocolo custom (no HTTP). Alternativa: habilitar solo para puerto 50051. |
| **UIBackgroundModes: audio** | Bajo — si la app reproduce audio | Asegurar que haya controls de reproducción visibles |
| **File picker (fotos)** | Bajo — uso legítimo para fondos | Describir en review notes |
| **mDNS discovery** | Bajo — Bonjour es Apple-native | Usar NSBonjourServices (ya incluido) |

### 8.2 Sandbox de iOS

| Restricción | Impacto | Mitigación |
|-------------|---------|------------|
| File system aislado | La BD debe estar en sandbox | Ya usamos `getApplicationDocumentsDirectory()` ✅ |
| Sin acceso a `/tmp/` compartido | No afecta (no lo usamos) | — |
| App kill por memoria | gRPC cliente consume poca memoria | Monitorear con `wakelock_plus` |
| iCloud backup de Documents | La BD se respalda en iCloud automáticamente | Opcional: marcar archivos DB como `NSURLIsExcludedFromBackupKey` |

**Código para excluir BD de backup de iCloud (opcional):**
```dart
import 'package:flutter/services.dart';

// En database_helper.dart, después de copiar la BD:
await _excludeFromBackup(dbPath);

Future<void> _excludeFromBackup(String path) async {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  // iOS: set resource value NSURLIsExcludedFromBackupKey
  // Implementar vía platform channel si es necesario
}
```

### 8.3 Red: gRPC en IPv6-Only Networks

Apple requiere soporte IPv6-only desde 2016. **gRPC soporta IPv6 nativamente.**

| Componente | IPv6 | Acción |
|------------|------|--------|
| gRPC cliente (Dart) | ✅ Soporte nativo | Ninguna |
| gRPC servidor | ✅ Soporte nativo | Ninguna |
| mDNS (nsd) | ✅ Soporta IPv6 via `IpLookupType.any` | Ya configurado (ver `nsd_discovery_service.dart` línea 31) |

**Riesgo mitigado.** El código actual ya usa `IpLookupType.any` que descubre direcciones IPv4 e IPv6.

### 8.4 Background Modes

| Modo | ¿Necesario? | Implementación |
|------|-------------|----------------|
| Audio | ✅ Sí (reproducir himnos en background) | Ya declarado en Info.plist: `UIBackgroundModes: audio` |
| gRPC (cliente) | ❌ No | No se necesita mantener conexión en background |
| mDNS discovery | ❌ No | Se redescubre al volver a foreground |

### 8.5 Costo de Developer Account

| Concepto | Costo | Notas |
|----------|-------|-------|
| Apple Developer Program | $99/año | Requerido para distribución en App Store |
| Certificados | Incluido | Hasta 100 dispositivos de prueba |
| TestFlight | Incluido | Hasta 10,000 testers internos |
| GitHub Actions (macOS runner) | $0.08/min (público) | ~$10-20/mes para builds semanales |

**Alternativa:** Usar sideloading gratuito (Free Apple Developer Account) para desarrollo, pero limitado a 7 días de validez y 3 apps.

### 8.6 Compatibilidad de `window_manager` en iOS

El plugin `window_manager` declara `ios: null` en su `pubspec.yaml`, lo que permite que el import compile pero lance `MissingPluginException` en runtime. Todos los accesos a `window_manager` en el código actual están envueltos en try-catch, **excepto** `fullscreen_handler.dart` (ver §5.2).

**Este es el único cambio obligatorio para evitar crashes.**

### 8.7 Compatibilidad de `nsd` en iOS

El plugin `nsd` v5.0.1 tiene soporte iOS completo via `nsd_ios`. Ya se registra correctamente en `GeneratedPluginRegistrant.m` (línea 62).

**Sin riesgo.** ✅

### 8.8 Compatibilidad de `sqflite` en iOS

`sapphire` v2.4.1 usa `sqflite_darwin` en iOS, que es un wrapper alrededor de `FMDB` (SQLite wrapper Objective-C). **Totalmente compatible.**

**Sin riesgo.** ✅

---

## Apéndice A: Lista de verificación pre-build iOS

- [ ] Backup de `ios/` realizado
- [ ] `flutter create --platforms=ios .` ejecutado
- [ ] `ios/Podfile` personalizado copiado (con patch gRPC)
- [ ] `ios/Runner/Info.plist` personalizado copiado (con permisos)
- [ ] `ios/Runner/Runner-Bridging-Header.h` creado
- [ ] Iconos de app generados en `Assets.xcassets`
- [ ] `ExportOptions.plist` configurado (para IPA)
- [ ] Bundle ID definido (ej: `com.organizacion.himnarioid`)
- [ ] `fullscreen_handler.dart` modificado con Platform guard
- [ ] `flutter analyze` pasa sin errores
- [ ] Todos los tests existentes pasan
- [ ] Apple Developer Account activa
- [ ] Certificados y Provisioning Profiles creados

## Apéndice B: Comandos rápidos

```bash
# Diagnóstico
flutter doctor
flutter analyze
flutter test

# Regenerar iOS
flutter create --platforms=ios .

# Build (simulator, debug)
flutter build ios --debug --no-codesign

# Build (dispositivo, release)
flutter build ipa --release --export-options-plist ios/ExportOptions.plist

# Run en simulador
flutter run -d 'iPhone 16'

# Limpieza completa iOS (en macOS)
cd ios
pod deintegrate
rm -rf Pods Podfile.lock Runner.xcworkspace
pod install --repo-update
cd ..
flutter clean
flutter pub get
```
