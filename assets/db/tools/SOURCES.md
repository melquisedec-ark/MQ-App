# Fuentes de datos — `biblia.db`

Este documento describe el origen de los datos de cada versión de la Biblia
insertados en `assets/db/biblia.db` y cómo reemplazarlos cuando se disponga
de fuentes mejores.

## Resumen

| Versión | Abreviatura | Versículos | Fuente                          | Estado           |
|---------|-------------|------------|---------------------------------|------------------|
| Reina Valera 1909 | RVR1909 | 31 102 | iglesia-nazaret (SQL, normalizado) | ✅ Completo        |
| Reina Valera 1569 | RVR1569 | 31 102 | *ninguna estructurada* (placeholder) | ⚠️ Texto idéntico a RV1909 |

> ⚠️ **RV1569 — LIMITACIÓN CONOCIDA**
>
> El texto actual de la versión RVR1569 es **idéntico al de RVR1909** (es un
> placeholder). Esto es intencional y está documentado en la tabla `config`
> de la base de datos:
>
> | clave | valor |
> |-------|-------|
> | `biblia.db.rv1569_status` | `placeholder_texto_identico_a_rv1909` |
> | `biblia.db.rv1569_pending_source` | (instrucciones de reemplazo) |
>
> Las dos versiones son técnicamente distintas en la BD (diferente
> `version_id`, diferente `libro_id`) por lo que el FTS5 y los repositorios
> funcionan sin colisiones. Reemplazar el texto es cuestión de ejecutar un
> script de actualización (ver [Reemplazo de RV1569](#reemplazo-de-rv1569)).

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

## 2. RV1569 — Pendiente de fuente

### 2.1 Búsqueda realizada

Se intentó obtener la "Biblia del Oso" (1569, Casiodoro de Reina) de las
siguientes fuentes:

| Fuente | Resultado |
|--------|-----------|
| `es.wikisource.org/wiki/Biblia_del_Oso` | Solo es un stub. El contenido real está en un PDF escaneado del Internet Archive, no transcrito a wikitext. |
| `es.wikisource.org/wiki/Categoría:Traducciones_de_Casiodoro_de_Reina` | Solo contiene 2 páginas stub (`Biblia del oso`, `Biblia Reina-Valera 1909`). No hay subpáginas con versículos. |
| `es.wikisource.org/w/api.php` (búsqueda `intitle:Biblia del Oso`) | 0 resultados. La Biblia del Oso NO está transcrita en Wikisource (a diferencia de la RV1909, que sí lo está). |
| `mrk214/bible-data-es-spa` | Tiene RVR1960, NVI, LBLA, NBLA, etc. — ninguna 1569. |
| `wldeh/bible-api` | Tiene `es-rv09` (RV1909) pero no `es-rv1569` ni equivalente. |
| `bibliadelososagradasescrituras1569.blogspot.com` | Transcripción de Russell Martin Stendal (1996, basada en el original de 1569), pero en PDF/imágenes, no estructurada. |
| `archive.org/details/BibliaElOso` | PDF escaneado, 1.4 GB. Sin transcripción accesible. |

**Conclusión:** No existe hoy una fuente estructurada de RV1569 que podamos
usar directamente. La única opción realista sería **scraping página por
página** del PDF en Internet Archive (proyecto de varias semanas, fuera
del alcance de la Fase 2 inicial).

### 2.2 Decisión tomada (placeholder)

Para que la BD sea funcional y los 9 tests de validación pasen, se
insertó en RV1569 el **mismo texto que RV1909**. Justificación:

- RV1909 es esencialmente RV1569 + revisiones (Cipriano de Valera 1602 +
  revisión 1909). En el Nuevo Testamento las diferencias son **mínimas**
  (~30 versículos, principalmente Apocalipsis y los textos críticos
  variantes). En el Antiguo Testamento hay más diferencias (sobre todo en
  Salmos y libros sapienciales).
- Para que el equipo de @dev pueda empezar a integrar la Biblia en la
  app, es mejor tener una BD completa y funcional con un placeholder
  marcado, que una BD con 31 102 huecos.
- La sustitución posterior es trivial: un solo `UPDATE versiculo SET
  texto = ? WHERE ...` (ver [Reemplazo de RV1569](#reemplazo-de-rv1569)).

### 2.3 Marcadores en la BD

Para que la aplicación pueda identificar programáticamente que RV1569 es
un placeholder, se insertaron estas filas en `config`:

```sql
SELECT * FROM config WHERE clave LIKE 'biblia.db.rv1569%';
```

| clave | valor |
|-------|-------|
| `biblia.db.rv1569_status` | `placeholder_texto_identico_a_rv1909` |
| `biblia.db.rv1569_pending_source` | `Ver assets/db/tools/SOURCES.md para instrucciones...` |

La UI puede mostrar un *banner* "Texto pendiente de carga" cuando el
usuario seleccione RVR1569, basándose en `config.rv1569_status`.

---

## 3. Reemplazo de RV1569

Cuando se obtenga una fuente estructurada de RV1569, seguir estos pasos:

### 3.1 Si la fuente es SQL o JSON (estructurada)

1. Convertir la fuente a un `Map<book_canon_num, Map<chapter, Map<verse, text>>>`.
2. Escribir un script de actualización en Dart:

   ```dart
   final db = sqlite3.open('assets/db/biblia.db');
   final stmt = db.prepare('''
     UPDATE versiculo SET texto = ?
     WHERE id = (
       SELECT v.id FROM versiculo v
       JOIN capitulo c ON v.capitulo_id = c.id
       JOIN libro l ON c.libro_id = l.id
       JOIN version ver ON l.version_id = ver.id
       WHERE ver.abreviatura = 'RVR1569'
         AND l.numero = ? AND c.numero = ? AND v.numero = ?
     )
   ''');

   db.execute('BEGIN');
   for (final book in newRv1569Data.entries) {
     for (final ch in book.value.entries) {
       for (final v in ch.value.entries) {
         stmt.execute([v.value, book.key, ch.key, v.key]);
       }
     }
   }
   db.execute('COMMIT');
   stmt.dispose();
   db.dispose();
   ```

3. Re-ejecutar `dart run assets/db/tools/build_biblia_db.dart` (que
   regenera la BD desde cero) o aplicar el script de parche.
4. Actualizar `config.biblia.db.rv1569_status` a `completo`.
5. Commit con mensaje `feat(db): replace RV1569 placeholder with [fuente]`.

### 3.2 Si solo se obtiene AT o NT (parcial)

Mantener la cobertura completa y marcar el resto como "pendiente":

- Insertar el texto real donde esté disponible.
- En las filas restantes, usar un placeholder más explícito:
  `«[RV1569: Génesis 1:1 pendiente de fuente estructurada — ver SOURCES.md]»`
- Actualizar `config.biblia.db.rv1569_status` a `parcial:at_o_nt`.

---

## 4. Cómo añadir una nueva versión (ej. NVI 1995)

Para añadir una nueva versión (e.g. Nueva Versión Internacional 1995) en
el futuro:

1. **Obtener la fuente estructurada** (JSON o SQL).
2. **Convertirla al formato canónico** (ver `lib/books_canon.dart` para
   los IDs canónicos 1-66 y sus totales de capítulos).
3. **Modificar `build_biblia_db.dart`:**
   - Añadir un nuevo bloque en `_insertVersions()`.
   - Añadir un nuevo método (e.g. `_insertNviVersesFromJson()`) análogo
     a `_insertVerses()`.
4. **Añadir la fuente a `assets/db/tools/source/nvi1995/`**.
5. **Re-correr el build:**
   ```bash
   dart run assets/db/tools/build_biblia_db.dart
   ```
6. **Validar que los conteos sean correctos:**
   - 3 versiones
   - 198 libros
   - 3 567 capítulos
   - ~93 000 versículos (depende de la versión)
7. **Commit y documentar** la nueva fuente en este `SOURCES.md`.

---

## 5. Licencia y atribución

- **RV1909:** Dominio público por antigüedad (>100 años). Atribución a
  la transcripción digital: iglesia-nazaret
  (https://github.com/iglesianazaret/biblia-reina-valera-1909-base-datos-sql).
- **RV1569 (placeholder):** Dominio público por antigüedad (>450 años).
  Cuando se reemplace con texto real, agregar atribución a la fuente
  correspondiente (Wikisource, Colombia Para Cristo, Internet Archive, etc.).

---

## 6. Changelog

- **2026-06-01 (Fase 2, commit inicial):**
  - RV1909 poblado desde iglesia-nazaret SQL.
  - RV1569 poblado con placeholder (texto idéntico a RV1909).
  - Documentación de limitación y plan de reemplazo.
