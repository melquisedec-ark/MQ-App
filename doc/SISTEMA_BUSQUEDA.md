# Sistema de Búsqueda

> **Archivo**: `lib/data/datasources/local/hymn_local_datasource.dart`
> **Utilidades**: `lib/core/utils/string_utils.dart`

## Arquitectura

La búsqueda usa una tabla plana `Himno_Busqueda` desacoplada de los datos principales, con textos pre-normalizados para búsqueda rápida:

```
Himno_Busqueda
├── himno_id INTEGER PRIMARY KEY (FK → Himno.id)
├── titulo_normalizado TEXT
└── contenido_normalizado TEXT
```

### Índices
- `idx_busqueda_titulo` — sobre `titulo_normalizado`
- `idx_busqueda_contenido` — sobre `contenido_normalizado`

## Normalización

Cada texto pasa por `normalizeForSearch()` en `string_utils.dart`:

```dart
String normalizeForSearch(String input) {
  // 1. Stripear acordes ChordPro ([G], [Am], etc.)
  input = stripChords(input);
  // 2. Minúsculas
  input = input.toLowerCase();
  // 3. Eliminar tildes y diacríticos
  input = replaceAccents(input);
  // 4. Eliminar caracteres no alfanuméricos (excepto espacios)
  input = input.replaceAll(RegExp(r'[^a-z0-9áéíóúñ\s]'), '');
  // 5. Colapsar espacios múltiples
  return input.replaceAll(RegExp(r'\s+'), ' ');
}
```

### stripChords()

Elimina notaciones de acordes ChordPro antes de cualquier otro procesamiento:

```dart
String stripChords(String text) {
  return text.replaceAll(RegExp(r'\[([A-G][#b]?m?(?:dim|aug|sus|add|M7|m7|7|9|6)?)\]'), '');
}
```

**Importante**: `stripChords()` debe ejecutarse ANTES de `toLowerCase()` porque su regex busca letras A-G mayúsculas.

## Inicialización del índice

`_doInitializeSearchIndex()` en `hymn_local_datasource.dart`:

1. `DELETE FROM Himno_Busqueda` (limpia todo)
2. Itera todos los himnos con sus estrofas
3. Para cada himno, construye:
   - `titulo_normalizado = normalizeForSearch(titulo_principal)`
   - `contenido_normalizado = normalizeForSearch(contenido de todas las estrofas)`
4. INSERT con `ConflictAlgorithm.replace`

### Migraciones de SCHEMA_VERSION

| Versión | Cambio |
|---------|--------|
| 4 | Creación de `Himno_Busqueda` |
| 7 | `DELETE FROM Himno_Busqueda` para forzar reindex con `stripChords()` |

El `DELETE` en la migración v7 es suficiente porque `_doInitializeSearchIndex()` se ejecuta automáticamente en el próximo `searchHymns()` si detecta la tabla vacía.

## Búsqueda

`searchHymns(searchTerm)`:

1. Normaliza el término con `normalizeForSearch()`
2. Si el índice está vacío, lo inicializa
3. Busca en `Himno_Busqueda` donde `titulo_normalizado` O `contenido_normalizado` contengan el término
4. JOIN con `Himno` y `Version_Pais` para devolver resultados completos

### Edge cases
- Búsqueda vacía → retorna todos los himnos activos
- Término con acordes ChordPro → los acordes se ignoran (no se incluyen en el contenido normalizado)
- Término con tildes → se comparan contra texto sin tildes (match "canción" con "cancion")
