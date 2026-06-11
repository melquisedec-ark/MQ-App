# Bugs y Fixes — Sesión Junio 2026

> Rama: `mq-app-init` | Versiones: v1.0.8 → v1.0.24

---

## 1. Presentación Bíblica — Bugs Críticos

### 1.1 Pantalla negra en modo Biblia
**Archivo**: `live_projection_screen.dart:64`
**Causa**: `if (liveState.isBlackout || liveState.hymn == null)` — en modo Biblia `hymn` es `null` intencionalmente, retornaba pantalla negra.
**Fix**: Verificar `hasContent` con `ProjectionModule.bible && slides.isNotEmpty`.

### 1.2 Receptor no detectaba contenido bíblico
**Archivo**: `receptor_binding.dart:85`
**Causa**: `hasContent` no verificaba `slides.isNotEmpty` para módulo bíblico.
**Fix**: Agregar `liveState.slides.isNotEmpty` al check.

### 1.3 `sendMessage` sin `await`
**Archivos**: `home_screen.dart`, `bible_reader_screen.dart`
**Causa**: `sendMessage()` es `Future<void>` pero se llamaba sin `await`, causando race conditions.
**Fix**: Agregar `await` a todas las llamadas.

---

## 2. Plataforma y Modo Presentación

### 2.1 Debug mode siempre retornaba `phone`
**Archivo**: `dual_mode_providers.dart:_detectInitialMode()`
**Causa**: `if (kReleaseMode)` — solo detectaba desktop en release.
**Fix**: Remover el guard `kReleaseMode`, detectar plataforma siempre.

### 2.2 Botón "Presentar" visible en celular
**Archivos**: `home_screen.dart` (biblia), `bible_reader_screen.dart`
**Causa**: No verificaban `isDesktopModeProvider`.
**Fix**: Agregar check con `Consumer` + `isDesktopModeProvider`.

### 2.3 `context.mounted` = false en FABs
**Archivos**: `home_screen.dart:737`, `bible_reader_screen.dart:226`
**Causa**: Al activar `isPresenting`, el Consumer oculta el FAB (`SizedBox.shrink`), desmontando el widget. El `context.mounted` en el callback async fallaba.
**Fix**: Remover el guard `context.mounted` para operaciones que no dependen del context (solo usan `ref`).

### 2.4 Overlay persistente de controles
**Archivo**: `app.dart`
**Causa**: `PresentControlBar` solo en himnario `home_screen.dart`.
**Fix**: Agregar `builder` a `MaterialApp.router` con `Stack` + `Positioned`. Overlay visible cuando `isPresenting || role == emitter`.

### 2.5 Overlay obstruía contenido
**Archivo**: `app.dart`
**Causa**: El overlay tapaba los últimos libros/capítulos.
**Fix**: Padding inferior de 200px al contenido cuando overlay visible.

---

## 3. Auto-Sync Biblia → Proyección

### 3.1 Cambio de capítulo no sincronizaba
**Archivo**: `bible_reader_screen.dart`
**Causa**: `_goNextChapter`/`_goPrevChapter` no llamaban a `_sendChapterToProjection`.
**Fix**: Agregar `currentBibleAnchorProvider` + `ref.listen` para detectar cambios de capítulo. Proactive sync en `initState`.

### 3.2 `copyWith` no limpiaba `hymn` en `loadBibleChapter`
**Archivo**: `live_control_providers.dart:249`
**Causa**: `state.copyWith(hymn: null)` → `hymn ?? this.hymn` = mantiene valor anterior.
**Fix**: Usar constructor `LiveControlState()` directamente (como `switchToModule`).

### 3.3 `_syncVerseToProjection` no funcionaba en emisor
**Archivos**: `bible_reader_screen.dart:194`, `bible_reader_screen.dart:261`
**Causa**: 
- Guard `liveState.module != bible` bloqueaba en emisor
- `if (!autoHist) return;` salía de TODO el listener (bug G3)
- `_syncVerseToRemoteDisplay` dentro del `if (slides.length)` (bug G7)
**Fix**: 
- Saltar guard de módulo en emisor
- `if (autoHist) { grabar }` en vez de `if (!autoHist) return`
- Mover `_syncVerseToRemoteDisplay` fuera del guard de slides

---

## 4. Apariencia de Proyección Bíblica

### 4.1 Fondo opaco tapaba el fondo de la Brocha
**Archivo**: `live_projection_screen.dart` (BibleTitleSlide, VerseSlide, BibleEndSlide)
**Causa**: `Container(color: theme.bg)` opaco cubría el fondo/imagen.
**Fix**: Remover los Containers. Usar `hymnAppearanceProvider` para color, fuente, bold.

### 4.2 Texto truncado en preview de referencias
**Archivo**: `cross_referencia.dart:188-192`
**Causa**: `fromMap` truncaba a 52 caracteres.
**Fix**: Guardar texto completo sin truncar.

### 4.3 Referencias expandibles
**Archivo**: `referencias_cruzadas_section.dart`
**Causa**: Preview siempre visible.
**Fix**: Solo cita por defecto. Tap expande preview. Tap en preview navega.

---

## 5. Grids Responsivos

### 5.1 Selector de libros — grid + orden vertical
**Archivo**: `book_selector_screen.dart`
**Causa**: Lista simple de 1 columna.
**Fix**: `_LibrosGrid` con `LayoutBuilder`, 5 columnas máx, orden por columnas (`_toColumnMajor`).

### 5.2 Grid de capítulos — compacto
**Archivo**: `chapter_grid_screen.dart`
**Causa**: 5 columnas fijas.
**Fix**: `SliverGridDelegateWithMaxCrossAxisExtent(52px)`, auto-calculado.

### 5.3 RangeError en `_toColumnMajor` con NT 5 columnas
**Causa**: Algoritmo asumía todas las columnas con mismo número de filas.
**Fix**: Calcular `colStarts` y `colCounts` para cada columna.

---

## 6. Modo Emisor

### 6.1 Controles minimalistas en desktop
**Archivos**: `connected_dashboard.dart`, `app.dart`
**Causa**: Desktop emisor mostraba `MinimalControlScreen` (viejo, sin Biblia).
**Fix**: Desktop usa overlay `PresentControlBar`. `isPresenting = true` al conectar.

### 6.2 Comandos no enviados por gRPC
**Archivos**: `present_control_bar.dart`, `bible_reader_screen.dart`
**Causa**: Navegación solo enviaba a `WindowService`, no a gRPC.
**Fix**: `_sendNavCommand` + `_sendChapterToRemoteDisplay` + `_syncVerseToRemoteDisplay`.

### 6.3 Tap en versículo sin efecto en emisor
**Decisión**: El usuario prefiere que no haga nada (ni focus, ni counter) en modo emisor.
**Fix**: `if (connectionRoleProvider == emitter) return;` en `onTap`.

---

## 7. Receptor gRPC

### 7.1 Receptor no mostraba LiveProjectionScreen
**Archivo**: `grpc_display_server.dart:_updateLiveControlFromBibleState`
**Causa**: Usaba `.then()` fire-and-forget, `liveControlProvider` no se actualizaba a tiempo.
**Fix**: Convertir a `async/await`. Todos los callers usan `await`.

### 7.2 GO_TO_VERSE recargaba capítulo completo siempre
**Archivo**: `grpc_display_server.dart:_handleGoToVerse`
**Causa**: Siempre cargaba `LOAD_VERSE` aunque fuera mismo capítulo.
**Fix**: Si `mismoCapitulo && yaTieneBiblia`, solo `GO_TO_SLIDE`.

---

## 8. Slides Bíblicos — Simplificación

### 8.1 Eliminar "Fin del capítulo"
**Archivo**: `live_control_providers.dart:_buildBibleSlides`
**Fix**: Remover `BibleEndSlide` de la lista.

### 8.2 Eliminar portada (BibleTitleSlide)
**Archivo**: `live_control_providers.dart:_buildBibleSlides`
**Fix**: Solo versículos: `[v1, v2, ..., vN]`. `goToVerse(1)` → `currentSlideIndex = 0`.

### 8.3 Counter 1-indexed
**Archivo**: `projection_slide.dart`, `present_control_bar.dart`
**Fix**: `displayNumber` en `VerseSlide`. Control usa `displayNumber` en vez de `currentSlideIndex + 1`.

---

## 9. UX Conexión Emisor

### 9.1 Sheet muy pequeña
**Archivo**: `discover_display_sheet.dart:188`
**Fix**: `initialChildSize: 0.85`, `minChildSize: 0.5`.

### 9.2 Auto-scan sin presionar botón
**Archivo**: `discover_display_sheet.dart:70`
**Causa**: `initState` llamaba `_startAutoRefresh()`.
**Fix**: Solo inicia al seleccionar "Soy Emisor" o al presionar "Buscar".

### 9.3 Foco robado al escribir IP
**Archivo**: `discover_display_sheet.dart:95`
**Causa**: Timer invalidaba `displayScannerProvider` cada 10s, reconstruyendo el árbol.
**Fix**: Guard `_manualIpFocusNode.hasFocus` antes de invalidar.

---

## 10. Varios

### 10.1 Historial FIFO 50 + botón borrar
**Archivo**: `historial_repository.dart`, `settings_screen.dart`

### 10.2 Eliminar "Modo de vista del emisor"
**Archivo**: `settings_screen.dart:_EmitterViewModeTile`

### 10.3 F11 pantalla completa
**Archivo**: `main.dart`
**Fix**: `FullscreenHandler` envuelve `MqApp`.

### 10.4 Broadcast mDNS en Linux
**Archivo**: `app_initializer.dart:212`
**Fix**: Habilitar broadcast también en `TargetPlatform.linux`.

### 10.5 Navegación desde botones del control
**Archivo**: `present_control_bar.dart`
**Fix**: `appRouter.go('/biblia')` y `appRouter.go('/himnario')`.

---

## Lecciones Aprendidas

1. **`copyWith` con nullable**: `hymn ?? this.hymn` no permite `null` explícito. Usar constructor directo.
2. **`context.mounted` en FABs**: Si un Consumer oculta el FAB al cambiar estado, el `onPressed` async pierde el context.
3. **`try/catch` no captura errores async**: Usar `.catchError()` para Futures fire-and-forget.
4. **`ref.listen` guards**: Un `return` en el medio del callback sale de todo el listener, no solo del bloque.
5. **gRPC + WindowService dual**: En modo emisor hay que enviar comandos por ambos canales.
6. **`GoRouter.of(context)` desde overlay**: No funciona porque el overlay está fuera del Navigator. Usar `appRouter` global.
7. **`.then()` en el receptor**: `liveControlProvider` debe actualizarse antes de que el `receptorDisplayProvider` evalúe. Usar `await`.
8. **Grid column-major**: El `GridView` ordena por filas. Para orden por columnas, reorganizar la lista.
