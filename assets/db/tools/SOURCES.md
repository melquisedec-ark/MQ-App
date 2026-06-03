# Fuentes de datos — `biblia.db`

Este documento describe el origen de los datos insertados en
`assets/db/biblia.db` y cómo reemplazarlos o añadir nuevas versiones.

## Resumen (v1.0.1)

| Versión | Abreviatura | Versículos | Fuente                          | Estado           |
|---------|-------------|------------|---------------------------------|------------------|
| Reina Valera 1909 | RVR1909 | 31 102 | iglesia-nazaret (SQL, normalizado) | ✅ Completo        |

> ℹ️ **Sobre RV1569 (v1.0.1)**
>
> A partir de v1.0.1 (decisión D1), **RV1569 ya no se incluye** en
> `biblia.db`. Anteriormente era un placeholder con texto idéntico a
> RV1909 que duplicaba el tamaño del bundle sin valor para el usuario.
> El schema sigue siendo multi-versión (la tabla `version` y las FKs
> CASCADE se mantienen), por lo que re-añadir RV1569 u otras versiones
> es solo poblar de nuevo la tabla cuando se disponga de una fuente
> estructurada. Ver [Cómo añadir una nueva versión](#4-cómo-añadir-una-nueva-versión).

---

## 1. RV1909 — Fuente principal

**Repo upstream:** https://github.com/iglesianazaret/biblia-reina-valera-1909-base-datos-sql

**Copia local:** `assets/db/tools/source/rv1909/data.sql` (4.4 MB)

**Descripción:** Dump SQL MySQL con 2 tablas (`books` y `verses`) en formato
`INSERT INTO ... VALUES (...), (...), ...`. Datos ya normalizados:
- Corrección de erratas (`hjo → hijo`, `espíirtu → espíritu`).
- Actualización de acentuación según normativa RAE actual.
- 100% fiel al original (no se alteran palabras ni signos).

**Conteo:** 66 libros, 1 189 capítulos, **31 102 versículos**.

**Transformaciones aplicadas** (en `build_biblia_db.dart`, función
`_parseRv1909Sql`):

1. **Parseo de filas:** expresión regular
   `^\s*\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*` para extraer `(book_id,
   chapter, verse, ...)`.
2. **Extracción del texto:** se busca la primera comilla simple (`'`) y se
   itera hasta la última comilla simple válida, manejando escapes MySQL:
   `\'`, `''`, `\\`, `\n`, `\r`, `\t`, `\"`, `\0`.
3. **Mapeo de IDs:** el `book_id` del dump (1-66) ya coincide con el
   orden canónico, así que no se requiere renumeración.
4. **Inserción:** los versículos se insertan en lotes de 1 000 filas dentro
   de transacciones (`BEGIN`/`COMMIT`) para mantener la latencia baja y
   evitar memory bloat.

**Validación de la fuente:** 31 102 filas = exactamente lo esperado
según el plan del proyecto. Sin duplicados ni huecos.

---

## 2. (Eliminado en v1.0.1) RV1569 placeholder

### 2.1 Historial

En v1.0.0, `biblia.db` incluía dos versiones:
- **RV1909** (31 102 versículos, fuente iglesia-nazaret).
- **RV1569** (31 102 versículos, **placeholder** con texto idéntico a RV1909
  porque no existía una fuente estructurada de la "Biblia del Oso" de
  Casiodoro de Reina).

### 2.2 Búsqueda de fuente RV1569 (resultado: no disponible)

Se intentó obtener la "Biblia del Oso" (1569) de las siguientes fuentes:

| Fuente | Resultado |
|--------|-----------|
| `es.wikisource.org/wiki/Biblia_del_Oso` | Solo es un stub. El contenido real está en un PDF escaneado del Internet Archive, no transcrito a wikitext. |
| `es.wikisource.org/wiki/Categoría:Traducciones_de_Casiodoro_de_Reina` | Solo contiene 2 páginas stub (`Biblia del oso`, `Biblia Reina-Valera 1909`). No hay subpáginas con versículos. |
| `es.wikisource.org/w/api.php` (búsqueda `intitle:Biblia del Oso`) | 0 resultados. La Biblia del Oso NO está transcrita en Wikisource (a diferencia de la RV1909, que sí lo está). |
| `mrk214/bible-data-es-spa` | Tiene RVR1960, NVI, LBLA, NBLA, etc. — ninguna 1569. |
| `wldeh/bible-api` | Tiene `es-rv09` (RV1909) pero no `es-rv1569` ni equivalente. |
| `bibliadelososagradasescrituras1569.blogspot.com` | Transcripción de Russell Martin Stendal (1996, basada en el original de 1569), pero en PDF/imágenes, no estructurada. |
| `archive.org/details/BibliaElOso` | PDF escaneado, 1.4 GB. Sin transcripción accesible. |

**Conclusión:** No existe hoy una fuente estructurada de RV1569 que
podamos usar directamente. La única opción realista sería **scraping
página por página** del PDF en Internet Archive (proyecto de varias
semanas, fuera del alcance).

### 2.3 Decisión D1 (v1.0.1): eliminar placeholder

Criterios de la decisión:
- **Bundle size:** el placeholder duplicaba exactamente el texto de RV1909,
  inflando el APK en ~8 MB sin valor alguno para el usuario final.
- **Engaño al usuario:** seleccionar "RV1569" en la UI mostraba el texto de
  RV1909, lo que es semánticamente incorrecto (RV1909 ≠ RV1569).
- **Mantenimiento:** mantener un placeholder que requiere sync manual con
  la versión real añade deuda técnica sin beneficio.

Acción aplicada:
1. Backup preventivo: `SELECT * FROM nota WHERE version_id = 2` (resultado
   en v1.0.0 → 0 filas; no se creó archivo de backup).
2. `DELETE FROM version WHERE id = 2` (CASCADE borró 31 102 versículos, 66
   libros, 1 189 capítulos, y todas las notas/historial/favoritos de
   RV1569, que eran 0).
3. `INSERT INTO versiculo_fts(versiculo_fts) VALUES('optimize')` +
   `VACUUM` para reclaim de espacio (FTS5 mantenía segmentos del
   contenido borrado).
4. `PRAGMA user_version = 2` + `INSERT INTO schema_version` registrando
   la migración v2.
5. `biblia.db` final: **15.19 MB → 7.45 MB** (reducción del 51%).

### 2.4 Re-añadir RV1569 en el futuro

Si en el futuro se obtiene una fuente estructurada de RV1569, seguir
estos pasos (son análogos a añadir cualquier versión nueva, ver §4):

1. **Obtener la fuente** (SQL o JSON) y verificar que es coherente con el
   canon protestante de 66 libros.
2. **Modificar `build_biblia_db.dart`:**
   - Re-añadir el bloque `insertVersion('Reina Valera 1569', ...)` en
     `_insertVersions()`.
   - Implementar un parser de la nueva fuente (análogo a `_parseRv1909Sql`).
   - Si la fuente tiene diferencias estructurales (ej. deuterocanónicos),
     ampliar el modelo de datos.
3. **Añadir la fuente a `assets/db/tools/source/rv1569/`** con su
   `README.md` de atribución.
4. **Re-correr el build** y verificar validaciones.
5. **Commit** con mensaje
   `feat(db): add RV1569 with [fuente]`.

---

## 3. (Eliminado en v1.0.1) Reemplazo de RV1569 placeholder

Esta sección se elimina en v1.0.1. Cuando se re-añada RV1569, las
instrucciones detalladas estarán en §2.4 (arriba).

---

## 4. Cómo añadir una nueva versión (ej. NVI 1995)

El schema es multi-versión: la tabla `version` y las FKs CASCADE están
listas. Para añadir una nueva versión (e.g. Nueva Versión Internacional
1995) en el futuro:

1. **Obtener la fuente estructurada** (JSON o SQL).
2. **Convertirla al formato canónico** (ver `lib/books_canon.dart` para
   los IDs canónicos 1-66 y sus totales de capítulos).
3. **Modificar `build_biblia_db.dart`:**
   - Añadir un nuevo bloque en `_insertVersions()`.
   - Añadir un nuevo método (e.g. `_insertNviVersesFromJson()`) análogo
     a `_insertVerses()`.
4. **Añadir la fuente a `assets/db/tools/source/nvi1995/`** con su
   `README.md` de atribución.
5. **Re-correr el build:**
   ```bash
   dart run assets/db/tools/build_biblia_db.dart
   ```
6. **Validar que los conteos sean correctos** (ahora 11 validaciones
   automáticas en el script):
   - 2 versiones
   - 132 libros
   - 2 378 capítulos
   - ~62 204 versículos
7. **Commit y documentar** la nueva fuente en este `SOURCES.md`.

---

## 5. Licencia y atribución

- **RV1909:** Dominio público por antigüedad (>100 años). Atribución a
  la transcripción digital: iglesia-nazaret
  (https://github.com/iglesianazaret/biblia-reina-valera-1909-base-datos-sql).

---

## 6. Changelog

- **2026-06-02 (v1.0.1, decisión D1):**
  - **Eliminado RV1569 placeholder.** El bundle pasó de 15.19 MB a
    7.45 MB (-51%). Schema multi-versión intacto.
  - Verificación de backup: 0 notas, 0 favoritos, 0 historial en
    RV1569 (no se creó archivo de backup).
  - `biblia.db.user_version`: 1 → 2.
  - `biblia.db.build_script_version`: 1.0.0 → 1.0.1.
  - Validaciones del build: 12 → 11 (se eliminó el check de
    `RVR1569 = 31 102 versículos`).
- **2026-06-01 (v1.0.0, commit inicial):**
  - RV1909 poblado desde iglesia-nazaret SQL.
  - RV1569 poblado con placeholder (texto idéntico a RV1909).
  - Documentación de limitación y plan de reemplazo.
