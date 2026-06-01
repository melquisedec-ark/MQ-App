# TODO — Fase 2: Implementación del módulo Biblia

> **Inicio planificado:** post-1 jun 2026
> **Estimación:** 3-4 semanas de trabajo concentrado
> **Branch:** continuar en `mq-app-init` (sin merge a `main` hasta v1.0)
> **Aprobación de Fase 1:** ✅ @arqui (1 jun 2026)

Este checklist agrupa las tareas por área. Cada tarea es accionable
y representa ~4-8 horas de trabajo (algunas se pueden paralelizar entre
@dev, @back, @design).

---

## 1. Base de datos (3-4 días) — owner: @back + @dev

- [ ] **Poblar `biblia.db` con RV1909** — generar SQL INSERTs desde
      `https://github.com/iglesianazaret/biblia-reina-valera-1909-base-datos-sql`
      (~31 102 versículos, script en `assets/db/tools/build_biblia_db.dart`).
- [ ] **Poblar `biblia.db` con RV1569** — desde
      `https://es.wikisource.org/wiki/Biblia_del_Oso`, normalizar formato.
- [ ] **Validar FTS5 con datos reales** — verificar que `jose` matchea `José`
      en miles de versículos; medir latencia de búsqueda (target: <50 ms).
- [ ] **Validar triggers con datos reales** — casos válidos + inválidos,
      medir latencia del trigger (target: <1 ms).
- [ ] **Generar `biblia.db` final + medir tamaño** — confirmar 5-7 MB
      comprimida; decisión: bundlear o descarga on-demand.

## 2. Modelos de dominio (3-5 días) — owner: @dev

- [ ] **`BibliaVersion`** — Freezed model con `id`, `nombre`, `abreviatura`,
      `idioma`, `anioPublicacion`, `esDominioPublico`, `activa`.
- [ ] **`Libro`** — Freezed model con FK a `BibliaVersion`, `testamento` enum
      (AT/NT), `numero` canónico (1-66).
- [ ] **`Capitulo` + `Versiculo`** — Freezed models con `numero` + `texto`;
      `Versiculo` con referencia a libro+capítulo para búsquedas.
- [ ] **`Favorito`, `Nota`, `HistorialItem`** — modelos de usuario, con
      serialización a SQLite (sin JSON, mapeo directo a columnas).
- [ ] **Tests unitarios de modelos** — `fromMap`/`toMap` con casos borde
      (texto vacío, colores inválidos, fechas en epoch 0).

## 3. Repositorios (3-5 días) — owner: @dev

- [ ] **`BibliaRepository`** — métodos: `getVersiones()`, `getLibros(versionId)`,
      `getCapitulos(libroId)`, `getVersiculos(capituloId)`.
- [ ] **`BibliaSearchRepository`** — FTS5 search con `MATCH` parametrizado,
      filtros por versión, ranking por `rank`, paginación.
- [ ] **`FavoritosRepository`** — `add()`, `remove()`, `listByFecha()`,
      `isFavorito()`. Constraint `UNIQUE` se traduce a `INSERT OR IGNORE`.
- [ ] **`NotasRepository`** — `upsert()` (INSERT OR REPLACE), `delete()`,
      `listByColor()`, `listByFechaMod()`. Color validado client-side también.
- [ ] **`HistorialRepository`** — append automático al leer versículo;
      `getUltimaPosicion(versionId)`, podar a últimos 12 meses.
- [ ] **Tests de repositorios** — usar `sqflite_common_ffi` con DB in-memory
      + fixtures. Target: 80% coverage.

## 4. State management con Riverpod (2-3 días) — owner: @dev

- [ ] **`versionActualProvider`** — `StateProvider<BibliaVersion?>`,
      default: última versión activa desde `config.version_default`.
- [ ] **`libroSeleccionadoProvider` + `capituloSeleccionadoProvider`** —
      familia de providers; se invalidan al cambiar de versión.
- [ ] **`versiculoAleatorioProvider`** — `FutureProvider<Versiculo>` que se
      resuelve al abrir home, cache por sesión.
- [ ] **`modoEmisorProvider`** — `StateProvider<bool>` + vista activa
      (`COMPACT` / `PREVIEW`) persistida en `config`.
- [ ] **`favoritosProvider` + `notasProvider`** — `AsyncNotifierProvider`
      con invalidación tras mutaciones.

## 5. UI screens (5-7 días) — owner: @design + @dev

- [ ] **HomeScreen** — versículo aleatorio + 2 cards (Biblia / Himnario),
      siguiendo `doc/wireframes/01_home_screen.md`.
- [ ] **BibleModuleScreen** (book selector) — grid/lista de 66 libros
      con separador AT/NT, según `02_bible_module.md` §3.
- [ ] **ChapterGridScreen** — grid 2D de capítulos por libro (1-150),
      con badge "último leído" si hay historial.
- [ ] **BibleReaderScreen** — render de versículos, gesture swipe para
      navegar capítulos, long-press para favoritos/notas, quick switch
      de versión en app bar.
- [ ] **SearchScreen** — input con debounce 400 ms (patrón ya usado en
      HimnarioID 2.0), resultados highlighteados, scroll-to-verse.
- [ ] **NotasScreen + FavoritosScreen** — listas cronológicas con filtros
      de color (notas), swipe-to-delete.
- [ ] **EmitterScreen** con toggle COMPACT/PREVIEW — implementación del
      wireframe `03_emitter_views.md`, integración con gRPC.
- [ ] **Notas color picker sheet** — bottom sheet con 4 opciones
      (amarillo/verde/azul/ninguno) + text field.

## 6. gRPC (2-3 días) — owner: @dev + @back

- [ ] **Extender `.proto` con comandos Biblia** — `NextVerse`,
      `PrevVerse`, `GoToVerse(version, libro, cap, num)`,
      `SwitchToBible(versionId)`, `SetEmitterViewMode(COMPACT|PREVIEW)`.
- [ ] **Actualizar `WatchStatus` stream** — incluir `textoAdyacente` y
      `previewText` para que el emisor muestre preview sin pedir extra.
- [ ] **Regenerar stubs Dart** — `bash build_proto.sh` (ya existe en
      repo), verificar compatibilidad Windows.
- [ ] **Tests gRPC** — mocks de `ClientChannel`, validar serialización
      de los nuevos mensajes.

## 7. Configuración (1-2 días) — owner: @dev

- [ ] **Pantalla de Settings** — versión por defecto, font size,
      toggle "versículo aleatorio al abrir", reset de caché.
- [ ] **Migración de settings himnario → tabla `config`** — mover
      claves existentes de HimnarioID 2.0 (si usaba otra tabla) a
      `config` para centralizar.
- [ ] **Export/Import de datos** — generar ZIP con `mqapp.db` +
      `biblia.db` para backup; Settings → "Exportar backup".

## 8. Testing (3-5 días) — owner: @dev + @qa

- [ ] **Arreglar 35 test failures pre-existentes** de
      `projection_actions_test.dart` (de la fase HimnarioID 2.0). No
      introducidos por Fase 1 pero bloquean release.
- [ ] **Tests de repositorios Biblia** — `BibliaRepository`,
      `BibliaSearchRepository` (FTS5 con tildes), `NotasRepository`
      (color CHECK constraint), `FavoritosRepository`.
- [ ] **Tests de providers Riverpod** — override de repos con mocks,
      verificar invalidación de cache al cambiar versión.
- [ ] **Tests de UI (golden tests + widget tests)** — Bible reader,
      emitter COMPACT/PREVIEW, nota sheet.
- [ ] **Smoke tests cross-platform** — script de CI que valida
      `flutter build apk`, `flutter build ios --no-codesign`,
      `flutter build windows`, `flutter build linux`, `flutter build macos`.

---

## ⚠️ Decisión pendiente del usuario

> 🟡 **BLOQUEANTE LEVE** — afecta wireframe `02_bible_module.md` y la
> navegación global.

- [ ] **PREGUNTAR AL USUARIO: ¿Bottom navigation en v1.0 o v1.1?**
      - **v1.0 (recomendado):** bottom nav con tabs (Inicio / Biblia /
        Himnario / Notas / Favoritos / Historial). Pros: descubrible.
        Contras: API consumption.
      - **v1.1 (minimalista):** drawer lateral con las mismas opciones.
        Pros: más espacio para contenido. Contras: menos descubrible.
      - Bloquea: routing de `02_bible_module.md` si afecta entry point.
      - Decisor final: @user.

---

## Dependencias y riesgos

- **Bloqueante fuerte:** #1 (DB poblada) — nada de UI ni búsqueda funciona
  sin datos reales.
- **Bloqueante medio:** #5 (UI Bible reader) — bloquea tests E2E.
- **No-bloqueante:** #8 (tests pre-existentes) — se pueden ir arreglando en
  paralelo a la implementación de Biblia.
- **Riesgo:** la decisión del bottom nav (#9) puede requerir rework del
  routing de HimnarioID 2.0. Resolver ANTES de empezar #5.

---

## Checklist de cierre de Fase 2 (gating para Fase 3)

Antes de declarar Fase 2 cerrada, todos estos deben estar ✅:

- [ ] `flutter analyze` 0 errores
- [ ] `flutter test` 100% verde
- [ ] `flutter build apk` produce APK < 30 MB (split per ABI)
- [ ] Smoke tests cross-platform verdes
- [ ] Documentación de Fase 2 creada (`PHASE_2_REPORT.md`)
- [ ] Decisión de bottom nav tomada y aplicada
- [ ] Bundle size de `biblia.db` validado (5-7 MB)
- [ ] FTS5 con tildes validado en dispositivo real
- [ ] Triggers de validación validados con datos reales

---

*Checklist creado por @documentador el 1 de junio de 2026*
*Aprobado por @arqui — Fase 2 UNLOCKED*
*Para preguntas, contactar a @dev (implementación) o @arqui (arquitectura)*
