#!/usr/bin/env bash
# ===============================================================
# commit_all.sh — Commits organizados + push a origin/main
# Ejecutar: bash scripts/commit_all.sh
# ===============================================================
set -euo pipefail

REPO="/home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0"
cd "$REPO"

echo "=========================================="
echo " REPO: HimnarioID 2.0"
echo " RAMA: $(git branch --show-current)"
echo "=========================================="

# ─── 0. Mostrar estado actual ─────────────────────────────────
echo ""
echo "═══ PASO 0: ESTADO ACTUAL ═══"
git status
echo ""
echo "═══ DIFF STAT ═══"
git diff --stat

# ─── 1. COMMIT 0: Cambios pre-existentes ──────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo " COMMIT 0: sync — cambios pendientes de"
echo "           sesiones anteriores"
echo "══════════════════════════════════════════════"

# Estrategia: stage ALL changes, luego unstaged los archivos
# específicos de esta sesión (los commiteamos aparte).
git add --all

# Unstage los archivos que commitearemos en commits separados
git reset HEAD -- \
  lib/core/database/schema.sql \
  lib/core/database/database_helper.dart \
  scripts/migrate_v1_to_v2.py \
  scripts/commit_all.sh

# Mostrar qué se va a commitear
echo ""
echo "Archivos staged para COMMIT 0:"
git diff --cached --name-status
echo ""

# Preguntar antes de commitear
read -r -p "¿Proceder con COMMIT 0? (s/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
  git commit -m "sync: commit cambios pendientes de sesiones anteriores"
  echo "✓ COMMIT 0 realizado"
else
  echo "✗ COMMIT 0 omitido por el usuario"
  # Hacemos unstage
  git reset HEAD . 2>/dev/null || true
fi

# ─── 2. COMMIT 1: Schema + helper ─────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo " COMMIT 1: feat(db) — actualizar esquema"
echo "            SQLite y eliminar seed data"
echo "══════════════════════════════════════════════"

git add \
  lib/core/database/schema.sql \
  lib/core/database/database_helper.dart

echo ""
echo "Archivos staged para COMMIT 1:"
git diff --cached --name-status

read -r -p "¿Proceder con COMMIT 1? (s/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
  git commit -m "feat(db): actualizar esquema SQLite y eliminar seed data embebida"
  echo "✓ COMMIT 1 realizado"
else
  echo "✗ COMMIT 1 omitido por el usuario"
  git reset HEAD . 2>/dev/null || true
fi

# ─── 3. COMMIT 2: Script de migración ─────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo " COMMIT 2: feat(scripts) — agregar script de"
echo "            migración MariaDB v1 → SQLite v2"
echo "══════════════════════════════════════════════"

git add scripts/migrate_v1_to_v2.py

echo ""
echo "Archivos staged para COMMIT 2:"
git diff --cached --name-status

read -r -p "¿Proceder con COMMIT 2? (s/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
  git commit -m "feat(scripts): agregar script de migración de MariaDB v1 a SQLite v2"
  echo "✓ COMMIT 2 realizado"
else
  echo "✗ COMMIT 2 omitido por el usuario"
  git reset HEAD . 2>/dev/null || true
fi

# ─── 4. PUSH ──────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo " PUSH a origin/main"
echo "══════════════════════════════════════════════"

read -r -p "¿Hacer git push a origin/main? (s/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[Ss]$ ]]; then
  git push origin main
  echo "✓ Push realizado"
else
  echo "✗ Push omitido por el usuario"
fi

# ─── 5. RESUMEN FINAL ─────────────────────────────────────────
echo ""
echo "=========================================="
echo " RESUMEN FINAL"
echo "=========================================="
git log --oneline -5
echo ""
echo "Hecho."
