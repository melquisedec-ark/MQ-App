# RV1569 — Fuente NO disponible

Esta carpeta está **vacía** porque **no existe hoy una fuente estructurada
de la Biblia Reina-Valera 1569 (Casiodoro de Reina, "Biblia del Oso")**
que pueda usarse directamente en un script de build.

## Búsqueda realizada (Fase 2 — Jun 2026)

| Fuente | Resultado |
|--------|-----------|
| `es.wikisource.org` | Solo stub de la página "Biblia del Oso" — sin transcripción |
| `mrk214/bible-data-es-spa` | RVR1960, NVI, LBLA, NBLA — no hay 1569 |
| `wldeh/bible-api` | `es-rv09` (RV1909) — no hay 1569 |
| `bibliadelososagradasescrituras1569.blogspot.com` | Transcripción de Russell Stendal, pero en HTML no estructurado |
| `archive.org/details/BibliaElOso` | PDF escaneado de 1.4 GB, sin OCR/transcripción |

## Estado actual

`build_biblia_db.dart` inserta en `version_id=2` (RVR1569) el **mismo
texto** que en `version_id=1` (RVR1909) como placeholder, marcado en la
tabla `config` con `biblia.db.rv1569_status = placeholder_texto_identico_a_rv1909`.

## ¿Cómo aportar una fuente estructurada?

Si conoces o quieres generar una fuente estructurada (JSON, CSV o SQL
MySQL/PostgreSQL/SQLite) de la RV1569:

1. Crear subcarpeta con licencia, fuente y formato (ej. `source/rv1569/data.json`)
2. Añadir parser en `build_biblia_db.dart` análogo a `_parseRv1909Sql()`
3. Ver `../SOURCES.md` §3 para el script de reemplazo del placeholder
4. Actualizar `config.biblia.db.rv1569_status` a `completo` o `parcial`
5. Commit y actualizar `../SOURCES.md`

## Estructura esperada de la fuente

Cualquiera de estos formatos sirve:

### Opción A: JSON
```json
{
  "Génesis": {
    "1": {
      "1": "En el principio crió Dios los cielos y la tierra.",
      "2": "Y la tierra estaba sin forma y vacía..."
    }
  }
}
```

### Opción B: CSV
```csv
libro,capitulo,versiculo,texto
"Génesis",1,1,"En el principio crió Dios los cielos y la tierra."
"Génesis",1,2,"Y la tierra estaba sin forma y vacía..."
```

### Opción C: SQL (mismo formato que RV1909)
```sql
INSERT INTO `verses` (`book_id`, `chapter`, `verse`, `text`) VALUES
(1, 1, 1, 'En el principio crió Dios los cielos y la tierra.'),
(1, 1, 2, 'Y la tierra estaba sin forma y vacía...');
```

Los `book_id` deben coincidir con el orden canónico 1-66 (ver
`../../lib/books_canon.dart`).
