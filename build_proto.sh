#!/bin/bash
# build_proto.sh — Genera los stubs Dart para gRPC a partir de los archivos .proto
# Uso: ./build_proto.sh

PROTO_DIR="proto"
OUT_DIR="lib/proto/generated"

echo "🧹 Limpiando directorio de salida..."
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "🔨 Generando stubs Dart desde protocol buffers..."
protoc --dart_out=grpc:"$OUT_DIR" \
  -I"$PROTO_DIR" \
  "$PROTO_DIR"/*.proto

if [ $? -eq 0 ]; then
  echo "✅ Stubs gRPC generados exitosamente en $OUT_DIR"
  echo "📂 Archivos generados:"
  ls -la "$OUT_DIR"
else
  echo "❌ Error generando stubs gRPC"
  exit 1
fi
