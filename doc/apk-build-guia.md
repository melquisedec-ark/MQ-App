# Guía de Build — APK Android (MQ App)

> **Propósito:** Documentar paso a paso cómo generar los APKs de la aplicación MQ App para distribución directa o subida a Google Play.
> **Última actualización:** 22 de mayo de 2026

---

## Requisitos

| Herramienta | Versión | Ruta |
|------------|---------|------|
| Java (JDK) | **17** (obligatorio) | `/home/melquisedec/jdk17` |
| Flutter | stable (último) | `which flutter` |
| Android SDK | API 35 | `/home/melquisedec/android-sdk` |

> ⚠️ **JDK 25 NO funciona** con Gradle 8.14. Usar exclusivamente JDK 17.

---

## 1. APKs divididos por arquitectura (recomendado)

Genera un APK independiente para cada tipo de procesador. Es la opción recomendada porque:

- **arm64-v8a** (~24MB) → 95% de celulares modernos
- **armeabi-v7a** (~22MB) → Celulares antiguos (2015-)
- **x86_64** (~26MB) → Tablets / Emuladores

```bash
# 1. Configurar JDK 17
export JAVA_HOME=/home/melquisedec/jdk17
export PATH=$JAVA_HOME/bin:$PATH

# 2. Ir al proyecto
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0

# 3. (Opcional) Limpiar build anterior
flutter clean

# 4. Obtener dependencias
flutter pub get

# 5. Construir APKs divididos
flutter build apk --release --split-per-abi
```

### Salida
```
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk   ← Para celular moderno (24MB)
├── app-armeabi-v7a-release.apk ← Para celular antiguo (22MB)
├── app-x86_64-release.apk      ← Para tablets/emuladores (26MB)
└── (sin app-release.apk cuando se usa --split-per-abi)
```

---

## 2. APK único (fat APK)

Genera un solo APK con todas las arquitecturas. Útil para pruebas rápidas o distribución manual.

```bash
export JAVA_HOME=/home/melquisedec/jdk17
export PATH=$JAVA_HOME/bin:$PATH

flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk (~65MB)
```

> ⚠️ Pesa ~65MB porque incluye las librerías nativas de las 3 arquitecturas.

---

## 3. App Bundle (para Google Play)

Formato recomendado por Google Play. Subes un solo `.aab` (~35MB) y Google genera y firma el APK óptimo para cada dispositivo.

```bash
export JAVA_HOME=/home/melquisedec/jdk17
export PATH=$JAVA_HOME/bin:$PATH

flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab (~35MB)
```

---

## 4. Script automatizado

Para builds frecuentes sin recordar los comandos:

```bash
# Hacer ejecutable (solo la primera vez)
chmod +x scripts/build_apk.sh

# Build con versión por defecto (la de pubspec.yaml)
./scripts/build_apk.sh

# Build con versión personalizada
./scripts/build_apk.sh 2.0.1
```

---

## 5. Build de depuración (debug)

Para pruebas durante el desarrollo:

```bash
export JAVA_HOME=/home/melquisedec/jdk17
export PATH=$JAVA_HOME/bin:$PATH

flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
```

---

## 6. Solución de problemas

| Problema | Causa | Solución |
|----------|-------|----------|
| `FAILURE: Build failed with an exception` | JDK incorrecto | Verificar `java -version` → debe ser 17 |
| `Android SDK not found` | `ANDROID_HOME` no configurado | `export ANDROID_HOME=/home/melquisedec/android-sdk` |
| `gradle: download...` lento | Primera vez con Gradle 8.x | Normal, tarda ~2 minutos descargando |

---

## 7. Referencia rápida

```bash
# Export obligatorio (JDK 17)
export JAVA_HOME=/home/melquisedec/jdk17
export PATH=$JAVA_HOME/bin:$PATH

# Split APK (recomendado)
flutter build apk --release --split-per-abi

# Fat APK
flutter build apk --release

# App Bundle
flutter build appbundle --release

# Debug
flutter build apk --debug
```
