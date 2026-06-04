# Changelog

Todas las versiones notables de MQ-App. Formato basado en [Keep a Changelog](https://keepachangelog.com/).

---

## [1.0.8] — 2026-06-04

### Added
- **📺 Modo pantalla completa para lectura de Biblia**
  - Nuevo botón en bottom bar (fila de acción, junto a Config): `Icons.fullscreen_rounded`
  - Oculta AppBar, barra de progreso y bottom bar
  - Usa `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` para ocultar status/nav bars
  - Reutiliza `fullscreenModeProvider` del himnario (mismo patrón)
  - Salir: botón `fullscreen_exit_rounded`, botón atrás del sistema, o swipe desde el borde

### Changed
- **🔍 Búsqueda sin límite (50 → 5,000 resultados)**
  - `biblia_search_repository.dart`: `limit = 50` → `maxResults = 5000`
  - Ahora muestra TODAS las coincidencias (antes solo 50)
  - Warning UI cuando hay ≥500 resultados: "considera una búsqueda más específica"

---

## [1.0.7] — 2026-06-04

### Fixed
- **⭐ Indicador de favorito en modo verso**
  - Ahora muestra `Icon(Icons.star_rounded)` dorado junto al número del versículo cuando está marcado como favorito
  - Usa `favoritosStreamProvider` para verificar en tiempo real
- **📖 Libro y capítulo reflejan favoritos (no historial)**
  - `_LibroTile`: cambiado icono de `bookmark_rounded` (historial) → `star_rounded` dorado (favoritos)
  - `_ChapterCell`: highlight priority — favorito (primary color) > última lectura (primaryContainer)
  - Al desmarcar todos los favoritos de un capítulo, el capítulo deja de estar resaltado
  - Al desmarcar todos los favoritos de un libro, el icono desaparece

### Added
- **3 nuevos derived providers** (`favoritos_provider.dart`):
  - `_favoritosPorLibroYCapituloProvider`: `Map<int, Set<int>>` (libroId → capítulos con favoritos)
  - `favoritosPorLibroProvider`: `Set<int>` de libros con favoritos
  - `favoritosPorCapituloProvider(libroId)`: `Set<int>` de capítulos con favoritos

---

## [1.0.6] — 2026-06-04

### Fixed
- **📖 Resultados de búsqueda ordenados Génesis→Apocalipsis**
  - Tab "Versículos": cambiado `ORDER BY rank` → `ORDER BY l.numero ASC, c.numero ASC, v.numero ASC`
  - Tab "Referencias": añadido `JOIN libro`, orden canónico por libro/capítulo/versículo
  - Cross-references en modo versículo: orden canónico (antes por votos)
  - `getByFromVerse`, `getByFromVerseWithPreview`, `getByToVerse` actualizados

### Added
- **🌑 Tema "Dark" (negro puro AMOLED)**
  - Fondo `#000000`, texto `#E8E8E8`
  - 6 temas totales: Papel, Sepia, Noche, **Dark**, Azul noche, Alto contraste
- **🔤 Escala de fuente extendida hasta 4.0x** (antes 1.5x)
  - Slider: 32 divisiones (0.8 → 4.0, paso 0.1)
  - Valores existentes preservados (sin migración)

---

## [1.0.5] — 2026-06-04

### Added
- **🎨 5 temas predefinidos para lectura de Biblia** (reemplaza color picker)
  - Papel (default): fondo cálido `#FAFAFA`, texto suave `#2D2D2D`
  - Sepia: `#F5E6C8` / `#5C4033` — reduce fatiga visual
  - Noche: `#1A1A1A` / `#E8E8E8` — OLED black
  - Azul noche: `#1E293B` / `#CBD5E1` — oscuridad suave
  - Alto contraste: `#FFFFFF` / `#000000` — accesibilidad
  - Enum `ReadingTheme` con `backgroundColor` + `textColor`
  - Persistencia en config table (`biblia.reading_theme`)
  - Migración automática desde `biblia.text_color` antiguo
- **👆👆 Double-tap → toggle favorito** en versículo
  - Verse mode: ya existía `onDoubleTap`, agregado haptic feedback
  - Chapter mode: `GestureDetector` wrapper en `_SwipeableVerseCard`
  - `HapticFeedback.mediumImpact()` al togglear
  - Botón ⭐ eliminado del bottom bar
- **👆 Long-press → NoteEditorModal** directo
  - Verse mode: abre editor de nota sin menú intermedio
  - Chapter mode: `onLongPress` pasado a través de `_SwipeableVerseCard` → `VerseCard`
  - ~500ms threshold (default Flutter)
- **📱 Bottom bar en 2 filas**
  - Fila 1 (navegación): Anterior | Verso | Número | Siguiente | Capítulo | Tabla
  - Divider
  - Fila 2 (acción): Nota (accesibilidad) | Configuración

### Tests
- +11 tests nuevos (628 total, 0 fallos)
- Tests de temas (enum, state, persistencia, migración)

---

## [1.0.4] — 2026-06-04

### Fixed
- **🐛 Navegación de cross-references: botón atrás no volvía al versículo de origen** (P0)
  - Causa: los StateProviders globales (`currentLibroIdProvider`, `currentCapituloProvider`, `currentVersiculoNumeroProvider`) se mutaban al navegar con `pushNamed`, corrompiendo el estado de la pantalla original en el stack
  - Fix: save/restore de 5 providers en bloque `try/finally` alrededor de `pushNamed`
  - Afecta: `referencias_cruzadas_section.dart`

### Added
- **📖 Preview de texto en cross-references** (P1)
  - Nuevo modelo `CrossReferenciaConPreview` con campo `previewTexto` (truncado ~52 chars + ellipsis)
  - Nuevo método `getByFromVerseWithPreview` en repositorio con LEFT JOIN a versículo para obtener texto
  - Nuevo provider `crossReferenciasConPreviewProvider`
  - UI: cada referencia muestra las primeras ~2 líneas del texto del versículo en itálica
  - LEFT JOIN: refs a versículos inexistentes muestran sin preview (no crash)
- **👆 Swipe-to-reveal en chapter mode** (P2)
  - `Dismissible` envuelve cada `VerseCard` en chapter mode
  - Swipe izquierda → flecha indicadora → al soltar cambia a verse mode para ese versículo
  - Versículos sin refs: swipe snap-back (sin acción)
  - Botón de modo en bottom bar se actualiza automáticamente

### Tests
- +15 tests nuevos (617 total, 0 fallos)
- Tests de navegación (nav history, triple-navigate)
- Tests de preview (modelo, repositorio, LEFT JOIN)
- Tests de swipe (con refs, sin refs, dirección)

---

## [1.0.3] — 2026-06-04

### Added
- **Sistema de Cross-References bíblicas (C1-C9)** ⭐
  - 340,000 referencias bíblicas de openbible.info vía scrollmapper/bible_databases (CC-BY 4.0 / MIT)
  - Nueva tabla `cross_referencia` con FKs a libro (cross-versión, no FK a versiculo.id)
  - 3 índices optimizados (from, to, votos) + 4 triggers de validación de FK
  - Modelo Dart `CrossReferencia` con `Equatable`, `fromMap/toMap/copyWith`
  - Repositorio con `getByFromVerse`, `getByToVerse`, `countByFromVerse`, `getCountsByFromVerseBatch`
  - Providers: `crossReferenciasProvider`, `crossReferenciasCountProvider`, `crossRefCountsProvider` (batch), `crossReferenciasResueltasProvider` (con resolución de nombres)
  - UI en **verse mode**: sección `🔗 N referencias` ANTES de la sección de nota
  - UI en **chapter mode**: icono `🔗` debajo del número del versículo cuando tiene refs
  - **Navegación con query param `?v=N`**: tap en una ref abre el reader en ese versículo
  - **Stack de navegación**: atrás desde una ref vuelve al versículo de origen (pushNamed, NO replace)
  - **Búsqueda de refs**: nueva tab "Referencias" en SearchScreen (busca versículos que CITAN a uno dado)
  - Atribuciones en AboutScreen + LICENSE file
- **Botones inline en chapter mode (A4)** ⭐
  - Versículos favoritos muestran ⭐ debajo del número
  - Indicador de nota (dot color) ahora más visible (14dp)
  - Icono de cross-refs (link) cuando aplica
- **Preview de nota en verse mode (B1+A5)** 🐛
  - Bug fix: el usuario ahora SÍ ve y edita notas en verse mode (preview inline con Card tinted)
  - Botón "Editar" explícito en el card de preview
  - Color de la nota como tint del card
- **Toggle de modo lectura en bottom bar (A1+A2)**
  - Eliminado del AppBar, trasladado al bottom bar (más accesible)
- **ReadingSettingsSheet simplificado (A3)**
  - Toggle de modo lectura eliminado del sheet (ya está en bottom bar)
- **Bottom bar consolidado a 1 fila densa (D1)**
  - 7 IconButton compactos (toggle view mode, skip_prev, chevron_left, verse_num, chevron_right, skip_next, settings)

### Changed
- `pubspec.yaml`: `1.0.2+2` → `1.0.3+3`
- `assets/db/biblia_version.json`: `version: 2` → `version: 3` (nueva tabla cross_referencia)
- `lib/core/database/bible_database_helper.dart`: `SCHEMA_VERSION: 1` → `2` (migración 004)
- `_loadFromDb()` de `ReaderViewModeNotifier` ahora respeta flag `_hydrated` (race condition fix)
- Bottom bar: 2 filas → 1 fila densa
- Indicadores de favorito/nota/refs en chapter mode son **always-visible** (no solo en focus)

### Fixed
- **Bug crítico**: Race condition en `ReaderViewModeNotifier` — si el usuario cambia el modo antes de que `_loadFromDb` complete, el cambio se sobrescribe
- **Bug de UX**: Nota no visible/editable en verse mode (B1) — ahora con preview inline
- Docstring obsoleto en `BibleSchemaVersion` (formato JSON actualizado)
- Docstring incorrecto en `libro.dart` (AT: 1..46 → 1..39)
- Debug `print` y `debugPrint` leftovers en 2 tests
- `db_version.json` de himnario bumped sin justificación (revertido)

### Stats
- 12 commits (Fase 1+2+3 + C1-C9 + auditoría)
- 602/602 tests pasando (514 baseline + 88 nuevos)
- 0 errores en flutter analyze
- Bundle size: +27MB (de 7.45MB a ~34-35MB por las 340k cross-references)
- Aceptado por el usuario

---

## [1.0.2] — 2026-06-03

### Sesión de feedback post-v1.0.1 — 10 observaciones del usuario

### Fixed
- **O2**: Himnario home — botón de configuración reemplazado por flecha de retroceso; card "Administrar Himnario" eliminada
- **O4**: FAB de cambio de tema en Biblia alineado a la misma altura que el FAB del himnario (SafeArea removido)
- **O6a**: Modo de vista del lector bíblico ahora persiste en BD — al cerrar y reabrir la app, se mantiene el modo seleccionado
- **O6b/O10**: Auto-scroll al seleccionar resultado de búsqueda — fuerza modo capítulo y usa el scroll programático existente
- **O7**: Notas — modal puede abrir notas existentes para edición (recibe `existingNote` como parámetro); indicador visual agrandado a 14×14 con color de nota; badge "Tiene nota" en modo verso
- **O7 bug fix**: `ref.read(notaColorDefaultProvider)` ahora se llama DENTRO del listener, no capturado del build scope (evita usar el valor inicial `ninguno` antes de que el provider cargue de BD)
- **O8**: Eliminado menú de tres puntitos redundante del AppBar del Bible Reader (su función la cubre el toggle de modo de lectura adyacente)

### Added
- **O1**: About screen — enlaces habilitados a página oficial (https://melquisedec-ark.github.io) y comunidad WhatsApp; licencia MIT con subtítulo explicativo
- **O3 ⭐**: Glassmorphism restaurado COMPLETO — `glass_container.dart` portado desde HimnarioID_2.0, `BackdropFilter` restaurado en `hymn_detail_screen.dart`, `GlassContainer` en `live_projection_screen.dart`. El himnario queda IDÉNTICO a HimnarioID_2.0
- **O5**: Selector de versículo en `ChapterGridScreen` — TextField numérico con botones +/- para elegir versículo individual antes de entrar al reader
- **O9 ⭐**: Botón de ajustes de lectura reemplaza al icono de dado aleatorio. Nuevo `bibleAppearanceProvider` INDEPENDIENTE con 4 campos (fontScale, fontFamily, textColor, lineHeight). Nuevo `ReadingSettingsSheet` con 5 controles (slider tamaño letra, fuente, color texto, slider interlineado, modo lectura). Aplicación en vivo de los cambios
- **O9 ⭐**: Default del modo de vista cambiado de `verse` a `chapter` (modo scrollable, solicitado por el usuario)
- 4 nuevas claves en `BibliaConfigKeys`: `biblia.reader_view_mode`, `biblia.font_scale`, `biblia.font_family`, `biblia.text_color`, `biblia.line_height`
- Wireframe 08 (`08_reading_settings.md`) — Documentación del nuevo bottom sheet de ajustes

### Changed
- Versión en `pubspec.yaml`: `1.0.0+1` → `1.0.2+2`
- `readerViewModeProvider` migrado de `StateProvider` a `StateNotifierProvider<ReaderViewModeNotifier, BibleReaderViewMode>` (sigue patrón de `ThemeModeNotifier`)
- Style guide wireframe 05 §2 — actualizado de "ELIMINADO" a "RESTAURADO en v1.0.2"
- 7 tests actualizados para reflejar los cambios de UI (títulos "Agregar nota" en lugar de "Nota", "Capítulo X" en chapter mode, etc.)

### Architecture
- `bibleAppearanceProvider` (nuevo, 153 líneas) — INDEPENDIENTE de `hymnAppearanceProvider` (Clean Architecture entre features)
- `ReadingSettingsSheet` (nuevo, 411 líneas) — bottom sheet modal con 5 controles
- `glass_container.dart` (nuevo, port desde HimnarioID_2.0) — widget reutilizable con `BackdropFilter` + `ImageFilter.blur` + `ClipRRect`

### Stats
- 12 commits (1 por observación + docs)
- 514/514 tests pasando
- Branch: `mq-app-init` (push a `origin` exitoso)

---

## [1.0.1] — 2026-06-02

### Fixed
- **B1**: Note editor now respects default color from `notaColorDefaultProvider` (note_editor_modal.dart)
- **B2**: Bible reader respects `autoHistorialProvider` toggle — history only records when enabled
- **B3**: Consolidated duplicate `themeModeProvider` (was in both biblia_config_provider and shared_widgets/providers) — single source in `biblia_config_provider.dart`, consumed correctly in `main.dart`
- **B4**: Added `hymn-detail` GoRoute to app_router.dart — hymn detail navigation now works correctly
- **B5**: Centralized `showAppSnackBar` helper in `lib/core/ui/app_snackbar.dart` — 3s auto-dismiss, anti-stacking, 4 types (info/success/warning/error)
- **D13**: Theme mode persistence verified — no more duplicate providers causing state conflicts

### Added
- **D1**: Removed RV1569 placeholder from biblia.db (saved 7.74MB, -51% DB size)
- **D2**: Consolidated theme mode provider architecture
- **D3**: FAB theme toggle (sun/moon) on home screens using existing `ThemeModeToggleButton`
- **D5**: Centralized `AppSnackBar` helper — eliminates duplicated snackbar code across 14+ files
- **D6**: Bible Reader chapter view with `scrollable_positioned_list` — verse↔chapter toggle
- **D7**: About screen with PackageInfo, repo URL, social placeholders (WhatsApp, official page)
- **D8**: AdminHimnario screen with Himnos + Catálogos TabBar
- **D10**: Bible reader history tracking respects auto-historial toggle
- **D11**: Hymn detail route properly configured in GoRouter
- **D12**: Deleted dead `MqDualApp` code (122 lines, never used from main.dart)
- **D14**: Removed all glassmorphism from the app (was causing performance issues)
- CONTROL folder for project tracking (PENDIENTE.md, CORRECCIONES.md, DECISIONES.md, BITACORA.md, RESUMEN.md)
- Wireframe 06 (About Screen) and Wireframe 07 (Admin Himnario)

### Changed
- DB version bumped from 1 to 2 (safety backup, DELETE CASCADE, VACUUM, FTS5 optimize)
- Bundle size: AAB 60MB → 55.5MB, APK 72MB → 71.6MB
- 514 tests passing (was 476)

### Removed
- RV1569 placeholder from biblia.db (no structured source available)
- Glassmorphism from entire UI
- Dead `MqDualApp` class
- Duplicate `themeModeProvider` in shared_widgets/providers

---

## [1.0.0] — 2026-06-02 (Initial Release)

### Added
- Bible module with RV1909 (31,102 verses)
- Full-text search (FTS5) with debounce
- Book selector with 5 tabs: AT / NT / Favoritos / Notas / Historial
- Chapter grid screen with random chapter button
- Bible reader screen with verse interaction
- Note editor modal with color system (yellow/green/blue/none)
- Settings screen with config table integration
- Emitter view mode toggle (compact/preview)
- Home screen with random verse display
- GoRouter routing with 8 routes
- gRPC Bible command handlers and client providers
- Dark/Light theme mode with persistence
- SQLite 3.46+ bundled via FFI
- 476 unit/widget tests
- Signed AAB + APK builds
- GitHub Release v1.0.0

### Architecture
- Clean Architecture (data/domain/presentation)
- Riverpod 2.x for state management
- go_router for navigation
- gRPC for LAN communication
- SQLite + FTS5 for local database
- mDNS for service discovery

---

## [Unreleased]

### Planned for v1.1
- Bottom navigation bar (Home/Bible/Hymnal/Settings)
- Hymnal favorites and notes (parity with Bible)
- Bible sharing (copy verse text)
- Presentation mode for Bible (PC)
- Windows .exe build (GitHub Actions or Windows machine)
- RV1569 replacement (when structured source available)
- More Bible versions (architecture supports multi-version)
