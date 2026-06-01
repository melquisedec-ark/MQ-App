# Tareas Pendientes — HimnarioID 2.0

> **Fecha:** 25 de mayo de 2026 — 8ª revisión
> **Propósito:** Estado actual tras migrar a renderizador de acordes responsivo (Wrap), fix de anclaje y fractura de palabras, y correcciones de UI/UX.

---

## Resumen del Estado Actual

| Área | Estado | Notas |
|------|--------|-------|
| **Base de datos** | ✅ Funcional | 425 himnos (400 + 25 convenciones), SQLite **v4**, 13 tablas + `Himno_Busqueda` |
| **Home / Búsqueda** | ✅ Funcional | Búsqueda acento-insensible, filtros, scroll A-Z |
| **Búsqueda Android** | ✅ Optimizada | Debounce 400ms, N+1 eliminado, tabla pre-normalizada |
| **Detalle de himno** | ✅ Funcional | Acordes sobre texto con ResponsiveChordWidget (Wrap nativo + Stack por segmento) |
| **Acordes sobre texto** | ✅ Funcional | ChordParser + expandToWordSegments + ResponsiveChordWidget (Wrap nativo, sin CustomPainter, sin caché LRU) |
| **Toggle acordes (Solfa)** | ✅ Funcional | showChords persistente en DB, botón Solfa funcional |
| **Admin CRUD** | ✅ Funcional | Himnos, categorías, países, pistas, fondos. Backend Usuarios listo (UI removida) |
| **Admin directo** | ✅ Funcional | Icono de ajustes sin login forzoso |
| **CRUD Usuarios (backend)** | ✅ Implementado | Datasource, repository, use cases, providers. UI removida del panel (conservada para futuro) |
| **Audio** | ✅ Funcional | Descarga, reproducción, bottom player |
| **Brocha (apariencia)** | ✅ Mejorada | Auto-refresh (Consumer), fondos color/imagen, selector HSV, paleta 22 colores, opacidad tarjetas |
| **Brocha conectada** | ✅ Funcional | IPC SET_CONFIG a ventana de proyección |
| **Fondos de pantalla** | ✅ Funcional | Color + imagen (file_picker), CRUD completo |
| **Eliminación de fondos** | ✅ Funcional | Invalida brocha/vista himno + borra archivo físico |
| **Almacenamiento local de fondos** | ✅ Implementado | FileStorageService copia a `{appDocs}/himnario_id/fondos/` al seleccionar, solo borra copia local |
| **Limpieza de código muerto** | ✅ Completado | 310 líneas eliminadas, 32 archivos. Eliminados: FondoPantallaTipo.video, 3 directorios huérfanos, login_screen, barrel files, 6 providers deprecados |
| **Escalado proyección** | ✅ Funcional | `projectionFontScale` independiente (0.5–3.0). Slider visible en móvil emisor conectado |
| **Orden himnos Oficiales primero** | ✅ Implementado | `CASE WHEN` en SQL getter `_defaultOrderBy` |
| **Filtro Convención** | ✅ Implementado | Chip en HomeScreen + ConnectedDashboard |
| **Scroll proyección** | ✅ Funcional | Condicional, SingleChildScrollView si desborda |
| **Reflow acordes proyección** | ✅ Funcional | Wrap nativo con spacing:0.0 + alignment condicional. StanzaLayoutEngine eliminado. |
| **Flujo presentación slides** | ✅ Funcional | Title → Lyrics → Amen con etiquetas |
| **Ventana de proyección** | ✅ Funcional | SubprocessWindowService + IPC JSON |
| **Modo Dual PC/Celular** | ✅ Funcional | Switch debug, rutas, botón Presentar |
| **Conexión Emisor/Receptor** | ✅ Completa y funcional | gRPC server + mDNS broadcast/discovery + flujo completo: discover, handshake, watchStatus, comandos de navegación, apariencia y envío automático de himno |
| **gRPC** | ✅ Implementado | GrpcDisplayServer (335 líneas, 7 comandos, handshake, watchStatus streaming). GrpcControlDataSource con keepalive, heartbeat, auto-reconexión |
| **F11 fullscreen** | ✅ Implementado | FullscreenHandler en projection_app.dart + windowManager.ensureInitialized() en main.dart (iOS guard condicional) |
| **Fullscreen móvil** | ✅ Implementado | Botón fullscreen en transpose bar (visible solo en phone). GestureDetector + AnimatedSwitcher. FullscreenModeProvider con SystemChrome. |
| **Título ventana Windows "MQ App"** | ✅ Recuperado | `windows/runner/main.cpp:30` → `L"MQ App"` (revertido 22 mayo, re-implementado manualmente) |
| **Numeración estrofas presentación** | ✅ Recuperado | `_calcStanzaNumber()` en `live_projection_screen.dart` (revertido 22 mayo, re-implementado manualmente) |
| **Fondos de video** | ❌ Revertido | Crash irrecuperable en Linux (libmpv 0.41.0). Pendiente para futuro. |
| **DB auto-update desde assets** | ✅ Implementado | Rama `feature/db-auto-update`. Backup/restore de datos de usuario. |
| **APK Android (split-per-abi)** | ✅ Optimizado | APKs por arquitectura: arm64-v8a ~24MB, armeabi-v7a ~22MB, x86_64 ~26MB |
| **Ejecutable Windows** | ✅ Renombrado | `MQ_App.exe` (antes `himnario_id_2.exe`). Build en CI (GitHub Actions windows-latest) |
| **iOS (.ipa)** | ✅ Implementado | Build unsigned via CI (macos-latest). Podfile con gRPC-Core C++17 patch. AppDelegate.swift, Info.plist, Assets. Doc: `doc/guia-build-ios.md` |
| **Renderizado acordes (Wrap)** | ✅ Implementado | `responsive_chord_widget.dart` — Wrap nativo con Stack+Positioned por segmento. Sin Stack global, sin CustomPainter, sin caché LRU. |
| **expandToWordSegments** | ✅ Implementado | `chord_parser.dart` — divide texto palabra por palabra para que Wrap pueda cortar en cualquier espacio. |
| **Anclaje acordes corregido** | ✅ Implementado | `CrossAxisAlignment.start` en Column + `Positioned(left:0,top:0)` + dummy `Text(' ')` transparente. |
| **Gaps en palabras corregido** | ✅ Implementado | `spacing: 0.0` en Wrap. Sin `Padding(right:4)` en segmentos. |
| **Tests** | ✅ 294 tests | 263 unit/widget + 11 integración + 20 nuevos unit (~11 fallos conocidos). Chords: 45 tests (27 legacy + 8 stanza + 6 expandToWordSegments + 4 ChordSegment) |
| **APK Android** | ✅ Funcional | Build release con `--split-per-abi`. Script: `scripts/build_apk.sh`. JDK 17 obligatorio. |

---

## Evaluación de tablas restantes (21 mayo 2026)

@arqui evaluó las 3 tablas que faltaban (`Version_Pais`, `Arreglo_Musical`, `Himno_Categoria`) y determinó que **ninguna justifica un CRUD standalone**:

| Tabla | ¿CRUD Admin? | Motivo |
|-------|:------------:|--------|
| **Himno_Categoria** | ❌ | Ya gestionada desde `hymn_form_screen.dart` vía `CategoriaSelector` |
| **Version_Pais** | ❌ | Pertenece al contexto del himno. Mejora futura: multi-versión en formulario de himno |
| **Arreglo_Musical** | ❌ | Ya tiene capa de datos completa. UI pertenece al músico/usuario final, no al admin |

**El panel admin está completo con 4 tabs** (Categorías, Países, Pistas, Fondos).

---

## Prioridades

### 🔴 P0 — Bloqueante / Core

#### ✅ P0.1 — Acordes sobre el texto (COMPLETADO Y REFACTORIZADO)
**Archivos**: `chord_parser.dart`, `chord_segment.dart`, `responsive_chord_widget.dart`, `expandToWordSegments()`
**Estado**: ✅ Refactorizado completamente. Se eliminó el sistema legacy (chord_painter.dart, stanza_layout_engine.dart, chord_overlay_text.dart). Nuevo sistema: Wrap nativo + Stack por segmento + word-splitting.

#### ✅ P0.2 — Transposición funcional con UI de acordes
**Archivos**: `transpose_providers.dart`, `chord_transposer.dart`
**Estado**: ✅ Completado

---

### 🟡 P1 — Alta prioridad

#### ✅ P1.1 — Probar flujo Presentar end-to-end en Linux
**Estado**: ✅ Probado

#### ✅ P1.2 — Reducir tamaño APK (split-per-abi)
**Archivos**: `android/`, comando build, `scripts/build_apk.sh`
**Descripción**: `--split-per-abi` para bajar de ~64MB a ~25MB por arquitectura. APKs renombrados como `mq-app-{arch}-{version}.apk`.
**Resultado**: arm64-v8a 24MB, armeabi-v7a 22MB, x86_64 26MB (antes 65.5MB fat).
**Script**: `scripts/build_apk.sh [version]` para builds futuros.
**Estado**: ✅ Completado 22 mayo 2026

---

### 🔵 P2 — Media prioridad

#### P2.1 — Tests unitarios básicos
**Archivos**: `test/`
**Descripción**: Tests para ChordTransposer, StringUtils, StanzaLayoutEngine. Priorizar lógica pura.
**Tiempo estimado**: ~3h

#### P2.2 — Refactor: sheets compartidos
**Archivos**: Extraer lógica a `shared_widgets/control_sheets.dart`
**Tiempo estimado**: ~1.5h

#### ✅ P2.3 — Limpieza de código muerto (COMPLETADO)
**Archivos**: Todo el proyecto
**Descripción**: Eliminado FondoPantallaTipo.video, 3 directorios huérfanos (state_management/, app_controller/, app_display/), login_screen.dart, barrel files, 6 providers deprecados, imports no usados.
**Resultado**: 310 líneas eliminadas, 32 archivos cambiados, 0 errores/warnings.
**Fecha**: 20 mayo 2026 — Rama `chore/limpieza-codigo-muerto` mergeada a main.

---

### 🔵 P2 — Media prioridad (actualizado)

#### P2.4 — Orden himnos Oficiales primero ✅ Completado

#### P2.5 — Filtro Convención ✅ Completado

#### P2.6 — CRUD Usuarios backend ✅ Completado (UI removida, lógica conservada)

#### ✅ P2.7 — Merge feature/renderizador-acordes-responsive → main
**Descripción**: Fusionado a main el 25 mayo 2026 (commit `e114994`). Incluye: Wrap responsivo, Stack+Positioned por segmento, expandToWordSegments, fix anclaje y fractura de palabras.

#### ✅ P1.3 — DB auto-update (desacoplado de sqflite onUpgrade)
**Archivos**: `lib/core/database/database_helper.dart`, `lib/core/database/db_version_manager.dart`, `lib/core/database/user_data_backup.dart`, `assets/db/db_version.json`, `assets/db/himnario_id.db`
**Descripción**: Mecanismo que compara `db_version.json` (manifiesto del asset) contra `db_version_applied.txt` (archivo marker local). Si `assetVersion > localVersion`: backup de datos de usuario → reemplazar .db completo → restore de datos → abrir BD con onCreate/onUpgrade.
**Arquitectura**: Dos capas ortogonales — SCHEMA_VERSION (migraciones estructurales) vs ASSET_VERSION (seed data).
**Rama**: `feature/db-auto-update`
**Estado**: ✅ Completado 22 mayo 2026 (commit `6db1c31`)

#### P1.4 — Limpiar CHECK constraints SQL (cosmético)
**Archivos**: `lib/core/database/database_helper.dart`
**Descripción**: Las constraints SQL aún mencionan `'video'` como tipo válido. Requiere migración de BD (v5) para limpiar. No urgente — mantiene compatibilidad hacia atrás.
**Tiempo estimado**: ~30min

### 🔵 P2 — Media prioridad

#### P2.8 — Etiqueta "Personal" en modo Convención (Punto 1)
**Archivos**: Vista de himno en modo personal, lógica de diferenciación de tipos
**Descripción**: Mostrar etiqueta visual "Personal" en himnos de tipo Convención cuando se usan en modo personal (fuera de la lista de Convención). Se perdió en el revert del 22 mayo.
**Tiempo estimado**: ~1h

#### P2.9 — Botones separados "Presentar" y "Conectar" (Punto 4)
**Archivos**: `connected_dashboard.dart`, `present_button.dart`, `discover_display_sheet.dart`
**Descripción**: Separar el botón único actual en dos botones independientes para presentar y conectar. Se perdió en el revert del 22 mayo.
**Tiempo estimado**: ~1h

### 🟢 P3 — Baja prioridad / Mejora continua

#### ✅ P3.1 — Servidor gRPC (bin/server.dart)
**Archivos**: `lib/data/datasources/remote/grpc_display_server.dart`, `lib/bootstrap/app_initializer.dart`
**Descripción**: Servidor gRPC creado e integrado. 335 líneas, implementa HymnControlServiceBase con 7 tipos de comando (NEXT, PREV, GO_TO_STANZA, GO_TO_CHORUS, BLACKOUT, CLEAR_BLACKOUT, JUMP_TO_HYMN, PING), handshake con versión de protocolo, y watchStatus streaming con ProviderContainer.
**Estado**: ✅ Completado

#### ✅ P3.2 — Modo Emisor completo (COMPLETADO)
**Archivos**: `connected_dashboard.dart`, `minimal_control_screen.dart`
**Estado**: ✅ Completado — flujo Emisor/Receptor funcional vía gRPC con discover, handshake, watchStatus, comandos de navegación, apariencia y envío automático de himno

#### ✅ P3.3 — Detección automática de plataforma (COMPLETADO)
**Archivos**: `app_initializer.dart`, `dual_mode_providers.dart`
**Estado**: ✅ Completado — detección por TargetPlatform en AppInitializer que decide iniciar servidor gRPC (desktop) o discovery mDNS (mobile)

#### P3.4 — Fondos de video (a futuro)
**Archivos**: Requiere re-implementar con soporte nativo de video
**Descripción**: Se intentó con `video_player_media_kit` + libmpv, pero libmpv 0.41.0 crashea en Linux con `assertion 'group_index >= 0'`. Esperar a que Ubuntu actualice libmpv o migrar a otro backend.
**Tiempo estimado**: ~5h (cuando sea viable)

#### P3.5 — Tests de widgets e integración
**Archivos**: `test/`
**Dependencias**: P2.1
**Tiempo estimado**: ~6h

---

## Dependencias entre tareas

```
✅ P1.2 Split APK ─── Completado 22 mayo
✅ P1.3 DB auto-update ─── Completado 22 mayo
✅ P1.5 Chord renderer refactor ─── Completado 25 mayo (rama feature/renderizador-acordes-responsive)
✅ P1.6 Fix anclaje + fractura + gaps ─── Completado 25 mayo
P1.4 CHECK SQL ─── migracion BD (v4→v5)
P2.8 Etiqueta Personal ─── sin dependencias
P2.9 Botones separados ─── sin dependencias
P2.1 Tests core ───→ P3.5 Tests widgets
```

## Novedades 22 mayo 2026 (7ª revisión)

- **✅ P1.3 DB auto-update**: Implementado en rama `feature/db-auto-update`. Dos capas de versionado ortogonales. Backup/restore de datos de usuario (7 tablas). Pantalla informativa con logo y spinner. 20 tests unitarios nuevos.
- **✅ P1.2 Split APK**: Build con `--split-per-abi` genera APKs de ~24MB. Script `scripts/build_apk.sh` para automatizar.
- **✅ Ejecutable Windows**: Renombrado a `MQ_App.exe`. Modificados: `windows/CMakeLists.txt` (BINARY_NAME), `Runner.rc` (InternalName), CI artifact name.
- **📄 implementacion.md**: Reporte detallado movido a `doc/`.
- **🧹 Limpieza raíz**: Solo `README.md` y `PropuestaInterfaz.md` en raíz. Reportes antiguos eliminados. Documentos movidos a `doc/`.

## Novedades 25 mayo 2026 (8ª revisión)

- **✅ Renderizador de acordes responsivo (Wrap)**: Reemplazo completo del sistema Stack+Positioned global por Wrap nativo. Creado `ChordSegment` (inmutable), `ResponsiveChordWidget`, y función `parseChordProStanza()`. Soporte para acordes con paréntesis como `[C#m7(b5)]`. Eliminados: `chord_painter.dart`, `stanza_layout_engine.dart`, `chord_overlay_text.dart` (~350 líneas legacy).
- **✅ Fix anclaje de acordes**: `CrossAxisAlignment.start` en Column interna para que el acorde se alinee con la primera letra del fragmento. `height: 1.1` en estilos para acercar acorde a letra.
- **✅ Fix fractura de palabras**: `spacing: 0.0` en Wrap + eliminación de `Padding(right: 4)`. Los acordes ya no inyectan espacios a mitad de palabra.
- **✅ Fix Caja Ancha (Stack+Positioned)**: El acorde flota dentro de un `Stack(clipBehavior: Clip.none)` + `Positioned(left:0, top:0)` + dummy `Text(' ')` transparente. El ancho de la columna lo dicta la letra, no el acorde.
- **✅ Fix Efecto Ladrillo (expandToWordSegments)**: Nueva función `expandToWordSegments()` que divide el texto palabra por palabra. Wrap puede cortar líneas en cualquier espacio. No modifica `parseChordProLine` (backward compatible). 6 tests nuevos.
- **✅ Fullscreen móvil**: Botón fullscreen en barra de transposición (visible solo en phone). `FullscreenModeProvider` con `SystemChrome`. `AnimatedSwitcher` para transición suave. `PopScope` para gesto atrás.
- **✅ iOS support**: Podfile con gRPC-Core C++17 patch. AppDelegate.swift, Info.plist, Assets. CI pipeline (macos-latest) genera .ipa unsigned (~16MB). Guía en `doc/guia-build-ios.md`. Build verificado 3 veces.
- **✅ 45 tests de acordes**: 27 legacy + 8 stanza + 6 expandToWordSegments + 4 ChordSegment model. Todos pasando.
- **📄 ac.md**: Reporte de revisión de @arqui sobre el renderizador de acordes responsivo.
- **📄 correcciones.md**: Bug report y resolución de Caja Ancha + Efecto Ladrillo.
- **📄 obs.md**: Bug report y resolución de desalineación y fractura de palabras.
- **🔨 APK reconstruido 3 veces**: Con cada fix incremental. Build limpio desde `rm -rf build .dart_tool`.

---

## Incidentes

### DB auto-update (22 mayo 2026)
1. **Revert total a `f666da8`**: El mecanismo de DB auto-update (que comparaba `_assetDbVersion` contra `user_version`) falló porque acopló el número de versión al `version:` de sqflite `openDatabase`, causando que `onUpgrade` se ejecutara siempre.
2. **3 de 6 cambios recuperados manualmente**: Se re-implementaron Punto 2 (ventana), Punto 3 (estrofas), Punto 5 (F11). No se recuperaron Punto 1 (etiqueta Personal) ni Punto 4 (botones separados).
3. **Nueva rama**: `feature/db-auto-update` creada desde `main` (commit `f9077af`) para rediseñar el mecanismo con enfoque desacoplado.
4. **APK release reconstruido** desde `main` (commit `f9077af`). Windows CI disparado desde main (run #26287517141).

### Regresiones en obs.md (25 mayo 2026)
1. El código propuesto en `obs.md` tenía **5 regresiones**: `_LineBreakPlaceholder(lineSpacing: 10.0)` hardcodeado, `chordStyle?.copyWith(height: 1.1)` sin fallback, `lyricStyle?.copyWith` (nombre incorrecto), `runSpacing: 10.0` hardcodeado, y falta de `TextAlign.right`. Todas corregidas por @arqui antes de implementar.
2. @curie detectó que el split directo sobre `parseChordProLine` perdía segmentos vacíos. Solución: función separada `expandToWordSegments` que preserva el API de `parseChordProLine`.

## Notas importantes

1. **Brocha mejorada**: Consumer reemplazó StatefulBuilder, fondos se refrescan automáticamente tras crear/editar/eliminar. Selector HSV + paleta 22 colores.
2. **Eliminación de fondos**: Al borrar un fondo, se invalida `fondosActivosProvider` (brocha + vista himno se actualizan). `DeleteFondoUseCase` usa `FileStorageService.deleteIfAppFile()` que solo borra si está dentro del directorio app.
3. **Fondos copiados a directorio local**: `FileStorageService` en `lib/core/utils/`. Al seleccionar imagen con file_picker, se copia a `{appDocs}/himnario_id/fondos/` con nombre único. Al eliminar el fondo, solo se borra la copia local, nunca el original del usuario.
4. **Fondos de video REVERTIDOS**: Se implementó con `video_player_media_kit` pero se descartó por crash en Linux. Todo el código fue revertido. La rama `main` está limpia.
5. **Limpieza de código muerto completada**: 310 líneas eliminadas, 32 archivos. Se eliminaron `FondoPantallaTipo.video`, 3 directorios huérfanos, `login_screen.dart`, barrel files, y 6 providers deprecados.
6. **~294 tests existentes**: ~11 fallos conocidos (widget tests con asunciones de plataforma).
7. **APK release**: Split-per-abi: arm64-v8a 24MB, armeabi-v7a 22MB, x86_64 26MB.
8. **JDK 17 obligatorio** para build Android (JDK 25 no compatible con Gradle 8.14). Ubicación: `/home/melquisedec/jdk17`.
9. **Infraestructura de red completada**: Servidor gRPC (GrpcDisplayServer, 335 líneas, 7 comandos), broadcast mDNS (BonsoirBroadcastService), descubrimiento (MdnsDiscovery + BonsoirService), detección de plataforma, y orquestación centralizada en AppInitializer con try/catch en cada capa.
10. **Broadcast mDNS**: Limitado a Windows y Linux (Bonsoir no está disponible en macOS en Flutter desktop). En móvil se usa discovery Bonsoir para encontrar displays.
11. **Chord rendering**: Sistema legacy (ChordOverlayText + ChordPainter + StanzaLayoutEngine) ELIMINADO. Nuevo sistema: `ResponsiveChordWidget` (Wrap nativo + Stack por segmento) + `expandToWordSegments()` (word-level parsing). 45 tests de acordes.
12. **iOS build**: Solo posible en macOS (GitHub Actions macos-latest). Genera .ipa unsigned (~16MB) para sideloading. Podfile requiere parche gRPC-Core C++17 para Xcode 16+.
13. **Renderizado responsivo**: Wrap nativo con `spacing:0.0` + `runSpacing:lineSpacing`. Alignment condicional según `textAlign`. Acordes flotan en Stack sin afectar layout. Palabras se dividen individualmente para wrapping fluido.
14. **Regla de no copiar ciegamente `obs.md`**: El código propuesto en los reports de bug debe ser evaluado por @arqui antes de implementar — las soluciones propuestas por el usuario pueden contener regresiones.

---

*Documento actualizado por @orquestador — 20 de mayo de 2026 (4ª revisión)*
