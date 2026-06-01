#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# build_apk.sh — Construye APKs de MQ App con split-per-abi
# Uso:   ./scripts/build_apk.sh [version]
# Ej:    ./scripts/build_apk.sh 2.0.1
# ──────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# ── Leer versión ─────────────────────────────────────────────
PUBSPEC_VERSION="$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')"
VERSION="${1:-$PUBSPEC_VERSION}"
echo "=== Building MQ App APKs v${VERSION} ==="

# ── Verificar JDK 17 ────────────────────────────────────────
export JAVA_HOME="${JAVA_HOME:-/home/melquisedec/jdk17}"
if ! "$JAVA_HOME/bin/java" -version 2>&1 | grep -q 'version "17'; then
  echo "ERROR: Se requiere JDK 17. JAVA_HOME=$JAVA_HOME"
  exit 1
fi
echo "JDK: $("$JAVA_HOME/bin/java" -version 2>&1 | head -1)"

# ── Construir APKs ───────────────────────────────────────────
flutter clean
flutter pub get
flutter build apk --release --split-per-abi

# ── Renombrar ────────────────────────────────────────────────
OUT_DIR="build/app/outputs/flutter-apk"
echo ""
echo "=== Renombrando APKs ==="

declare -A ARCH_MAP=(
  ["arm64-v8a"]="arm64-v8a"
  ["armeabi-v7a"]="armeabi-v7a"
  ["x86_64"]="x86_64"
)

for arch in "${!ARCH_MAP[@]}"; do
  src="$OUT_DIR/app-${arch}-release.apk"
  dst="$OUT_DIR/mq-app-${ARCH_MAP[$arch]}-${VERSION}.apk"
  if [ -f "$src" ]; then
    cp "$src" "$dst"
    size=$(du -h "$dst" | cut -f1)
    echo "  ✅ $dst  (${size})"
  fi
done

# Registrar versión
echo "$VERSION" > "$OUT_DIR/version.txt"
echo ""
echo "=== ¡Listo! APKs en $OUT_DIR ==="
echo "  Para celular moderno: mq-app-arm64-v8a-${VERSION}.apk"
echo "  Para celular antiguo: mq-app-armeabi-v7a-${VERSION}.apk"
echo ""
echo "Tip: Si distribuyes por Google Play, usa App Bundle (.aab):"
echo "  flutter build appbundle --release"
