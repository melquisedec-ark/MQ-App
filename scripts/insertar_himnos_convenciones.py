#!/usr/bin/env python3
"""
=============================================================
Script: insertar_himnos_convenciones.py
Proyecto: HimnarioID 2.0
Descripción: Inserta 25 himnos de convenciones juveniles en la
             base de datos SQLite del HimnarioID.
=============================================================

Cambios que realiza:
  1. Backup de la BD original
  2. ALTER TABLE Himno ADD COLUMN evento TEXT
  3. PRAGMA user_version = 5 (salta de 3 a 5)
  4. Inserta 25 himnos tipo=3 (Convención) desde JSON
  5. Crea Version_Pais (pais_id=2) y Estrofas para cada himno
  6. Asigna categoria_id=3 (Evangelización) a cada himno
  7. Verifica los resultados

Uso:
  python3 scripts/insertar_himnos_convenciones.py
"""

import json
import os
import sqlite3
import shutil
import sys
from pathlib import Path

# ─── Rutas ───────────────────────────────────────────────────────────────────
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "assets" / "db" / "himnario_id.db"
BACKUP_PATH = PROJECT_ROOT / "assets" / "db" / "himnario_id.db.backup"
JSON_PATH = Path("/tmp/himnario_hymns.json")

# ─── Constantes ──────────────────────────────────────────────────────────────
PAIS_ID_EL_SALVADOR = 2
CATEGORIA_EVANGELIZACION = 3
TONALIDAD_DEFAULT = "C"
TIPO_CONVENCION = 3
USER_VERSION_NUEVA = 5

# ─── Colores para consola ────────────────────────────────────────────────────
VERDE = "\033[92m"
AMARILLO = "\033[93m"
ROJO = "\033[91m"
CYAN = "\033[96m"
RESET = "\033[0m"
NEGRITA = "\033[1m"


def log_ok(msg: str):
    print(f"  {VERDE}✓{RESET} {msg}")


def log_warn(msg: str):
    print(f"  {AMARILLO}⚠{RESET} {msg}")


def log_error(msg: str):
    print(f"  {ROJO}✗{RESET} {msg}")


def log_info(msg: str):
    print(f"  {CYAN}→{RESET} {msg}")


def log_title(msg: str):
    print(f"\n{NEGRITA}{msg}{RESET}")


# ─── Paso 0: Backup ──────────────────────────────────────────────────────────
def step_backup():
    log_title("[Paso 0] Creando backup de la base de datos...")
    if not DB_PATH.exists():
        log_error(f"Base de datos no encontrada: {DB_PATH}")
        sys.exit(1)

    try:
        shutil.copy2(str(DB_PATH), str(BACKUP_PATH))
        log_ok(f"Backup creado en: {BACKUP_PATH}")
    except OSError as e:
        log_error(f"Error al crear backup: {e}")
        sys.exit(1)


# ─── Paso 1: Agregar columna evento ─────────────────────────────────────────
def step_add_evento_column(conn: sqlite3.Connection):
    log_title("[Paso 1] Agregando columna 'evento' a la tabla Himno...")
    cur = conn.execute("PRAGMA table_info(Himno)")
    columnas = {row[1] for row in cur.fetchall()}

    if "evento" in columnas:
        log_warn("La columna 'evento' ya existe. Se omite ALTER TABLE.")
    else:
        conn.execute("ALTER TABLE Himno ADD COLUMN evento TEXT;")
        log_ok("Columna 'evento' agregada correctamente.")


# ─── Paso 2: Migrar user_version ────────────────────────────────────────────
def step_migrate_version(conn: sqlite3.Connection):
    log_title("[Paso 2] Migrando user_version de 3 → 5...")
    cur = conn.execute("PRAGMA user_version")
    old_ver = cur.fetchone()[0]
    log_info(f"user_version actual: {old_ver}")

    conn.execute(f"PRAGMA user_version = {USER_VERSION_NUEVA};")
    cur = conn.execute("PRAGMA user_version")
    new_ver = cur.fetchone()[0]
    log_ok(f"user_version migrada a: {new_ver}")


# ─── Paso 3: Insertar himnos ─────────────────────────────────────────────────
def step_insert_hymns(conn: sqlite3.Connection):
    log_title("[Paso 3] Insertando 25 himnos de convenciones...")

    if not JSON_PATH.exists():
        log_error(f"Archivo JSON no encontrado: {JSON_PATH}")
        sys.exit(1)

    with open(JSON_PATH, "r", encoding="utf-8") as f:
        himnos_data = json.load(f)

    if len(himnos_data) != 25:
        log_warn(f"Se esperaban 25 himnos, pero se encontraron {len(himnos_data)}")

    insertados = 0
    for idx, himno in enumerate(himnos_data, start=1):
        titulo = himno["titulo"]
        evento = himno["evento"]
        estrofas = himno["estrofas"]

        # Iniciar transacción por cada himno
        conn.execute("BEGIN TRANSACTION")
        try:
            # 3a. Insertar en Himno
            cursor = conn.execute(
                """
                INSERT INTO Himno (titulo_principal, numero_oficial, tipo, activo, evento)
                VALUES (?, ?, ?, 1, ?)
                """,
                (titulo, None, TIPO_CONVENCION, evento),
            )
            himno_id = cursor.lastrowid

            # 3b. Insertar en Version_Pais
            cursor = conn.execute(
                """
                INSERT INTO Version_Pais (himno_id, pais_id, tonalidad_original, activo)
                VALUES (?, ?, ?, 1)
                """,
                (himno_id, PAIS_ID_EL_SALVADOR, TONALIDAD_DEFAULT),
            )
            version_pais_id = cursor.lastrowid

            # 3c. Insertar estrofas
            for estrofa in estrofas:
                conn.execute(
                    """
                    INSERT INTO Estrofa (version_pais_id, tipo, orden, contenido)
                    VALUES (?, ?, ?, ?)
                    """,
                    (version_pais_id, estrofa["tipo"], estrofa["orden"], estrofa["contenido"]),
                )

            conn.execute("COMMIT")
            insertados += 1
            log_ok(f"  [{idx:02d}/25] '{titulo}' (evento: {evento}) → himno_id={himno_id}")

        except sqlite3.Error as e:
            conn.execute("ROLLBACK")
            log_error(f"  [{idx:02d}/25] Error insertando '{titulo}': {e}")
            raise

    log_ok(f"Total himnos insertados: {insertados}")


# ─── Paso 4: Asignar categoría ───────────────────────────────────────────────
def step_assign_category(conn: sqlite3.Connection):
    log_title("[Paso 4] Asignando categoría Evangelización (id=3)...")

    # Obtener IDs de los himnos tipo=3 recién insertados
    cur = conn.execute(
        "SELECT id FROM Himno WHERE tipo = ? AND evento IS NOT NULL ORDER BY id",
        (TIPO_CONVENCION,),
    )
    himnos_ids = [row[0] for row in cur.fetchall()]

    if not himnos_ids:
        log_warn("No se encontraron himnos tipo=3 para asignar categoría.")
        return

    conn.execute("BEGIN TRANSACTION")
    try:
        for hid in himnos_ids:
            conn.execute(
                "INSERT OR IGNORE INTO Himno_Categoria (himno_id, categoria_id) VALUES (?, ?)",
                (hid, CATEGORIA_EVANGELIZACION),
            )
    except sqlite3.Error as e:
        conn.rollback()
        log_error(f"Error asignando categorías: {e}")
        raise

    cur = conn.execute(
        """
        SELECT COUNT(*) FROM Himno_Categoria hc
        INNER JOIN Himno h ON h.id = hc.himno_id
        WHERE h.tipo = ? AND hc.categoria_id = ?
        """,
        (TIPO_CONVENCION, CATEGORIA_EVANGELIZACION),
    )
    total_cat = cur.fetchone()[0]
    log_ok(f"Categoría Evangelización asignada a {total_cat} himnos.")


# ─── Paso 5: Verificación ────────────────────────────────────────────────────
def step_verify(conn: sqlite3.Connection):
    log_title("[Paso 5] Verificando resultados...")

    checks = {}

    cur = conn.execute("SELECT COUNT(*) FROM Himno WHERE tipo = ?", (TIPO_CONVENCION,))
    checks["himnos_tipo3"] = cur.fetchone()[0]

    cur = conn.execute("SELECT COUNT(*) FROM Version_Pais")
    checks["version_pais_total"] = cur.fetchone()[0]

    cur = conn.execute("SELECT COUNT(*) FROM Estrofa")
    checks["estrofas_total"] = cur.fetchone()[0]

    cur = conn.execute(
        """
        SELECT COUNT(*) FROM Himno_Categoria hc
        INNER JOIN Himno h ON h.id = hc.himno_id
        WHERE h.tipo = ? AND hc.categoria_id = ?
        """,
        (TIPO_CONVENCION, CATEGORIA_EVANGELIZACION),
    )
    checks["himnos_con_categoria"] = cur.fetchone()[0]

    cur = conn.execute("PRAGMA user_version")
    checks["user_version"] = cur.fetchone()[0]

    print()
    print(f"  {'Verificación':<30} {'Esperado':<15} {'Actual':<15} {'Estado':<10}")
    print(f"  {'-'*70}")

    # Check 1: Himnos tipo=3 deben ser 25
    var_checks = [
        ("Himnos tipo=3", 25, checks["himnos_tipo3"]),
        ("Version_Pais total", 425, checks["version_pais_total"]),
        ("User version", 5, checks["user_version"]),
    ]

    all_ok = True
    for name, expected, actual in var_checks:
        ok = actual >= expected if name == "Version_Pais total" else actual == expected
        # For Version_Pais we check >= because autoincrement might have gaps
        if name == "Version_Pais total":
            ok = actual >= expected
        else:
            ok = actual == expected

        status = f"{VERDE}PASA{RESET}" if ok else f"{ROJO}FALLA{RESET}"
        print(f"  {name:<30} {expected:<15} {actual:<15} {status}")
        if not ok:
            all_ok = False

    # Check 2: Estrofas deben haber aumentado
    estrofas_esperadas_min = 2513 + (25 * 3)  # al menos 3 estrofas por himno
    ok_estrofas = checks["estrofas_total"] >= estrofas_esperadas_min
    status_estrofas = f"{VERDE}PASA{RESET}" if ok_estrofas else f"{ROJO}FALLA{RESET}"
    print(f"  {'Estrofas (≥' + str(estrofas_esperadas_min) + ')':<30} {'≥' + str(estrofas_esperadas_min):<15} {checks['estrofas_total']:<15} {status_estrofas}")
    if not ok_estrofas:
        all_ok = False

    # Check 3: Categoría
    ok_cat = checks["himnos_con_categoria"] >= 25
    status_cat = f"{VERDE}PASA{RESET}" if ok_cat else f"{ROJO}FALLA{RESET}"
    print(f"  {'Himnos con cat=3 (≥25)':<30} {'≥25':<15} {checks['himnos_con_categoria']:<15} {status_cat}")
    if not ok_cat:
        all_ok = False

    print()
    if all_ok:
        print(f"  {VERDE}{NEGRITA}✓ TODAS LAS VERIFICACIONES PASARON{RESET}")
    else:
        print(f"  {ROJO}{NEGRITA}✗ ALGUNAS VERIFICACIONES FALLARON{RESET}")

    return all_ok


# ─── Main ─────────────────────────────────────────────────────────────────────
def main():
    print(f"{NEGRITA}{'='*70}{RESET}")
    print(f"{NEGRITA}  HimnarioID 2.0 — Inserción de Himnos de Convenciones{RESET}")
    print(f"{NEGRITA}{'='*70}{RESET}")
    print()
    log_info(f"Base de datos: {DB_PATH}")
    log_info(f"Backup:        {BACKUP_PATH}")
    log_info(f"Datos JSON:    {JSON_PATH}")
    print()

    # Paso 0: Backup
    step_backup()

    # Conectar a la BD
    conn = sqlite3.connect(str(DB_PATH))
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.execute("PRAGMA journal_mode = WAL;")

    try:
        # Paso 1
        step_add_evento_column(conn)

        # Paso 2
        step_migrate_version(conn)

        # Paso 3
        step_insert_hymns(conn)

        # Paso 4
        step_assign_category(conn)

        # Confirmar cambios pendientes
        conn.commit()

        # Paso 5
        all_ok = step_verify(conn)

        print()
        if all_ok:
            log_ok("Migración completada exitosamente.")
        else:
            log_warn("Migración completada con algunas advertencias.")

    except (sqlite3.Error, json.JSONDecodeError, OSError) as e:
        conn.rollback()
        log_error(f"Error durante la migración: {e}")
        log_info("Todos los cambios fueron revertidos.")
        log_info(f"El backup está disponible en: {BACKUP_PATH}")
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
