#!/usr/bin/env python3
"""
Script de migración: Himnario v1.0 (MariaDB) → Himnario v2.0 (SQLite)
Lee el dump SQL de la v1.0 y puebla una base SQLite con el esquema v2.0.
"""

import sqlite3
import re
import sys
import os

# ─── CONFIGURACIÓN ───────────────────────────────────────────────────────────

ORIGEN_SQL = "/home/melquisedec/Escritorio/Projects/Personales/himnario_1.0/Himnario.sql"
DESTINO_DB = "/home/melquisedec/Documentos/himnario_id.db"
SCHEMA_SQL = "/home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0/lib/core/database/schema.sql"

BATCH_SIZE = 50  # commits cada 50 himnos

# ─── MAPEO DE TIPOS ─────────────────────────────────────────────────────────

TIPO_MAP = {
    'verso': 'Estrofa',
    'coro': 'Coro',
    'puente': 'Puente',
}

# ─── PARSEO DEL SQL ORIGEN ──────────────────────────────────────────────────

def parse_himnos(content):
    """Extrae los INSERT INTO `himnos` y devuelve lista de dicts."""
    himnos = []
    # Buscar: INSERT INTO `himnos` ... VALUES (...) (...) ...
    pattern = r"INSERT INTO `himnos`\s*\([^)]+\)\s*VALUES\s*((?:\([^;]+?\)\s*,?\s*)+)\s*;"
    match = re.search(pattern, content, re.IGNORECASE | re.DOTALL)
    if not match:
        print("ERROR: No se encontraron datos de himnos en el archivo SQL.")
        return himnos

    values_block = match.group(1)
    # Extraer cada tupla (id, numero, titulo, creado_at)
    tuple_pattern = r"\((\d+),\s*(\d+),\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)'\)"
    for m in re.finditer(tuple_pattern, values_block):
        himnos.append({
            'id': int(m.group(1)),
            'numero': int(m.group(2)),
            'titulo': m.group(3).replace("''", "'"),
            'creado_at': m.group(4).replace("''", "'"),
        })
    return himnos


def parse_estrofas(content):
    """Extrae todos los INSERT INTO `estrofas` y devuelve lista de dicts.
    Usa un parser robusto que maneja comillas simples escapadas y
    contenido con comas, punto y coma, y saltos de línea.
    """
    estrofas = []
    # Encontrar cada bloque: desde "INSERT INTO `estrofas`" hasta el próximo
    # INSERT INTO o hasta el final del archivo
    blocks = list(re.finditer(
        r"INSERT INTO\s+`estrofas`\s*\([^)]+\)\s*VALUES\s*",
        content,
        re.IGNORECASE,
    ))

    for i, block_match in enumerate(blocks):
        # El valor comienza después de "VALUES"
        values_start = block_match.end()

        # El bloque termina antes del próximo INSERT INTO o al final
        if i + 1 < len(blocks):
            values_end = blocks[i + 1].start()
        else:
            values_end = len(content)

        values_text = content[values_start:values_end]

        # Ahora parsear tuplas individuales desde values_text
        # Cada tupla: (id, himno_id, 'tipo', orden, 'contenido')
        # Parseamos carácter por carácter para manejar comillas anidadas
        idx = 0
        while idx < len(values_text):
            # Saltar espacios y comas entre tuplas
            while idx < len(values_text) and values_text[idx] in ' \t\n\r,':
                idx += 1
            if idx >= len(values_text):
                break
            if values_text[idx] != '(':
                break

            # Encontrar el paréntesis de cierre, respetando strings entre comillas
            depth = 0
            in_string = False
            end_idx = idx
            while end_idx < len(values_text):
                ch = values_text[end_idx]
                if in_string:
                    if ch == '\\':
                        end_idx += 1  # skip escaped char
                    elif ch == "'":
                        # Verificar si es '' (escape SQL) o fin de string
                        if end_idx + 1 < len(values_text) and values_text[end_idx + 1] == "'":
                            end_idx += 1  # skip escaped quote
                        else:
                            in_string = False
                else:
                    if ch == "'":
                        in_string = True
                    elif ch == '(':
                        depth += 1
                    elif ch == ')':
                        depth -= 1
                        if depth == 0:
                            break
                end_idx += 1

            if depth != 0:
                # No se encontró cierre, avanzar y continuar
                idx += 1
                continue

            tuple_str = values_text[idx:end_idx + 1]

            # Extraer campos del tuple. Usar regex simple ya que tenemos
            # un solo tuple bien formado
            m = re.match(
                r"\((\d+),\s*(\d+),\s*'((?:[^']|'')*)',\s*(\d+),\s*'((?:[^']|'')*)'\)",
                tuple_str,
            )
            if m:
                estrofas.append({
                    'id_origen': int(m.group(1)),
                    'himno_id': int(m.group(2)),
                    'tipo': m.group(3).replace("''", "'"),
                    'orden': int(m.group(4)),
                    'contenido': m.group(5).replace("''", "'"),
                })
            idx = end_idx + 1

    return estrofas


def normalize_contenido(text):
    """Normaliza los saltos de línea: \\r\\n (literal backslash-r-backslash-n) → newline real"""
    # El dump SQL usa \\r\\n como caracteres literales (backslash + r + backslash + n)
    # Reemplazar con newline real (ASCII 10)
    text = text.replace('\\r\\n', '\n').replace('\\r', '\n')
    # También manejar CR+LF reales por si acaso
    text = text.replace('\r\n', '\n').replace('\r', '\n')
    return text


# ─── APLICAR ESQUEMA ────────────────────────────────────────────────────────

def apply_schema(cursor):
    """Lee el archivo schema.sql y ejecuta cada sentencia."""
    with open(SCHEMA_SQL, 'r', encoding='utf-8') as f:
        schema_content = f.read()

    # Eliminar comentarios de una línea (-- ...)
    schema_content = re.sub(r'--.*$', '', schema_content, flags=re.MULTILINE)
    # Eliminar comentarios de bloque /* ... */
    schema_content = re.sub(r'/\*.*?\*/', '', schema_content, flags=re.DOTALL)

    # Separar por punto y coma y ejecutar cada sentencia no vacía
    statements = [s.strip() for s in schema_content.split(';') if s.strip()]
    for stmt in statements:
        try:
            cursor.execute(stmt)
        except sqlite3.Error as e:
            print(f"  ERROR al ejecutar: {stmt[:80]}... → {e}")
            raise
    print("  ✓ Esquema aplicado correctamente.")


# ─── MIGRACIÓN PRINCIPAL ────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("MIGRACIÓN: Himnario v1.0 → Himnario v2.0")
    print("=" * 60)

    # ── 1. Leer archivo SQL origen ──────────────────────────────────────────
    print("\n[1] Leyendo archivo SQL origen...")
    if not os.path.exists(ORIGEN_SQL):
        print(f"  ERROR: No se encuentra {ORIGEN_SQL}")
        sys.exit(1)

    with open(ORIGEN_SQL, 'r', encoding='utf-8') as f:
        content = f.read()
    print(f"  ✓ Archivo leído ({len(content)} bytes).")

    # ── 2. Parsear datos ────────────────────────────────────────────────────
    print("\n[2] Parseando datos...")
    himnos = parse_himnos(content)
    print(f"  ✓ {len(himnos)} himnos extraídos.")

    estrofas = parse_estrofas(content)
    print(f"  ✓ {len(estrofas)} estrofas extraídas (de 8 bloques INSERT).")

    # Verificar himnos sin estrofas
    himnos_con_estrofas = set(e['himno_id'] for e in estrofas)
    himnos_sin_estrofas = [h for h in himnos if h['id'] not in himnos_con_estrofas]
    print(f"  ℹ  {len(himnos_sin_estrofas)} himnos sin estrofas: "
          f"{[h['id'] for h in himnos_sin_estrofas[:10]]}{'...' if len(himnos_sin_estrofas) > 10 else ''}")

    # ── 3. Crear/sobrescribir base de datos SQLite ──────────────────────────
    print(f"\n[3] Creando base de datos SQLite en: {DESTINO_DB}")
    if os.path.exists(DESTINO_DB):
        os.remove(DESTINO_DB)
        print("  ✓ Base anterior eliminada.")

    conn = sqlite3.connect(DESTINO_DB)
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.execute("PRAGMA journal_mode = WAL;")
    cursor = conn.cursor()
    print("  ✓ Conexión establecida.")

    # ── 4. Aplicar esquema ──────────────────────────────────────────────────
    print("\n[4] Aplicando esquema...")
    apply_schema(cursor)
    conn.execute("PRAGMA user_version = 2;")
    conn.commit()

    # ── 5. Insertar datos ───────────────────────────────────────────────────
    print("\n[5] Insertando datos...")

    # 5a. País por defecto
    cursor.execute("INSERT INTO Pais (id, nombre, codigo) VALUES (1, 'El Salvador', 'SV');")
    print("  ✓ País "El Salvador" insertado con ID 1.")

    # 5b. Categoría
    cursor.execute("INSERT INTO Categoria (id, nombre) VALUES (1, 'Himnario Oficial El Salvador');")
    print("  ✓ Categoría insertada.")

    # 5c. Usuario administrador por defecto
    import hashlib
    admin_hash = hashlib.sha256('admin123'.encode('utf-8')).hexdigest()
    cursor.execute(
        "INSERT INTO Usuario (id, username, password_hash, nombre, rol) VALUES (1, ?, ?, ?, 'Admin')",
        ('admin', admin_hash, 'Administrador')
    )
    print("  ✓ Usuario admin creado (admin / admin123).")

    total_insertados = 0
    total_errores = 0
    total_estrofas_insertadas = 0

    # 5d-5g. Por cada himno
    for idx, himno in enumerate(himnos):
        himno_id = himno['id']
        try:
            # d) Insertar Himno
            cursor.execute(
                "INSERT INTO Himno (id, titulo_principal, numero_oficial, tipo, activo, fecha_creacion) "
                "VALUES (?, ?, ?, 1, 1, ?)",
                (himno_id, himno['titulo'], himno['numero'], himno['creado_at'])
            )

            # e) Insertar Version_Pais (una por himno, 'El Salvador' con pais_id=1)
            cursor.execute(
                "INSERT INTO Version_Pais (himno_id, pais_id, tonalidad_original, activo) "
                "VALUES (?, 1, 'C', 1)",
                (himno_id,)
            )
            version_pais_id = cursor.lastrowid

            # f) Insertar Estrofas (si existen para este himno)
            estrofas_himno = [e for e in estrofas if e['himno_id'] == himno_id]
            estrofas_himno.sort(key=lambda e: e['orden'])
            for est in estrofas_himno:
                tipo_normalizado = TIPO_MAP.get(est['tipo'], 'Estrofa')
                contenido_normalizado = normalize_contenido(est['contenido'])
                cursor.execute(
                    "INSERT INTO Estrofa (version_pais_id, tipo, orden, contenido) "
                    "VALUES (?, ?, ?, ?)",
                    (version_pais_id, tipo_normalizado, est['orden'], contenido_normalizado)
                )
                total_estrofas_insertadas += 1

            # g) Insertar Himno_Categoria
            cursor.execute(
                "INSERT INTO Himno_Categoria (himno_id, categoria_id) VALUES (?, 1)",
                (himno_id,)
            )

            total_insertados += 1

        except sqlite3.Error as e:
            print(f"  ✗ Error insertando himno id={himno_id} ('{himno['titulo']}'): {e}")
            total_errores += 1
            conn.rollback()
            continue

        # Commit por lotes
        if (idx + 1) % BATCH_SIZE == 0:
            conn.commit()
            print(f"  ℹ  Progreso: {idx + 1}/{len(himnos)} himnos insertados...")

    # Commit final
    conn.commit()

    print(f"\n  ✓ Migración completada:")
    print(f"    - Himnos insertados: {total_insertados}")
    print(f"    - Estrofas insertadas: {total_estrofas_insertadas}")
    print(f"    - Errores: {total_errores}")

    # ── 6. Validaciones post-migración ──────────────────────────────────────
    print("\n[6] Validaciones post-migración:")
    print("-" * 50)

    validaciones = [
        ("Total Himnos", "SELECT COUNT(*) FROM Himno"),
        ("Total Estrofas", "SELECT COUNT(*) FROM Estrofa"),
        ("Total Version_Pais", "SELECT COUNT(*) FROM Version_Pais"),
        ("Total Categorias", "SELECT COUNT(*) FROM Categoria"),
        ("Total HC Asignaciones", "SELECT COUNT(*) FROM Himno_Categoria"),
        ("Himnos sin estrofas", """
            SELECT COUNT(*) FROM Himno h
            WHERE NOT EXISTS (
                SELECT 1 FROM Version_Pais vp
                JOIN Estrofa e ON e.version_pais_id = vp.id
                WHERE vp.himno_id = h.id
            )
        """),
        ("Himnos sin Version_Pais", """
            SELECT COUNT(*) FROM Himno h
            WHERE NOT EXISTS (
                SELECT 1 FROM Version_Pais vp WHERE vp.himno_id = h.id
            )
        """),
        ("VP con pais_id != 1", """
            SELECT COUNT(*) FROM Himno h
            JOIN Version_Pais vp ON vp.himno_id = h.id
            WHERE vp.pais_id != 1
        """),
        ("Himnos sin VP", """
            SELECT COUNT(*) FROM Himno h
            LEFT JOIN Version_Pais vp ON vp.himno_id = h.id
            WHERE vp.id IS NULL
        """),
    ]

    for nombre, query in validaciones:
        cursor.execute(query)
        result = cursor.fetchone()[0]
        status = "✓" if result == 0 or "sin" not in nombre.lower() or "Total" in nombre else "⚠"
        print(f"  {status} {nombre}: {result}")

    # Mostrar muestra de datos
    print("\n  Muestra - primeros 5 himnos:")
    cursor.execute(
        "SELECT id, titulo_principal, numero_oficial FROM Himno ORDER BY id LIMIT 5"
    )
    for row in cursor.fetchall():
        print(f"    {row[0]}: [{row[2]}] {row[1]}")

    print("\n  Muestra - últimos 5 himnos:")
    cursor.execute(
        "SELECT id, titulo_principal, numero_oficial FROM Himno ORDER BY id DESC LIMIT 5"
    )
    for row in cursor.fetchall():
        print(f"    {row[0]}: [{row[2]}] {row[1]}")

    # ── 7. Cerrar ───────────────────────────────────────────────────────────
    conn.close()
    print(f"\n{'=' * 60}")
    print("MIGRACIÓN FINALIZADA")
    print(f"Base de datos: {DESTINO_DB}")
    print(f"{'=' * 60}")

    if total_errores > 0:
        print(f"\n⚠  ADVERTENCIA: {total_errores} himnos no pudieron ser insertados.")
        sys.exit(1)


if __name__ == '__main__':
    main()
