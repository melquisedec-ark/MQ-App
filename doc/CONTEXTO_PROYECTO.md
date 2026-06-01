# Contexto del Proyecto - HimnarioID 2.0

> **Última actualización:** 22 de mayo de 2026 — 8ª revisión

## Stack Tecnológico
- **Frontend**: Flutter (Dart)
- **Estado**: Riverpod
- **BD**: SQLite (sqflite en Android/iOS, sqflite_common_ffi en desktop)
- **Audio**: audioplayers + DeviceFileSource
- **Fuentes**: Google Fonts (Merriweather, Lora, Playfair Display, Cinzel)
- **Gestión de estado**: Riverpod (StateNotifier + FutureProvider)
- **Hosting**: GitHub Releases (para pistas de audio)

## Base de Datos (SQLite)
- Version actual: 6
- Tablas: Himno, Version_Pais, Pais, Estrofa, Categoria, Himno_Categoria, Usuario,
  Arreglo_Musical, Estrofa_Arreglo, Pista_Audio, Fondo_Pantalla, Configuracion,
  Historial_Reproduccion, **Himno_Busqueda**
- BD embebida en: `assets/db/himnario_id.db` (400 himnos precargados + 25 nuevos de convenciones)
- Migraciones: v1→v2→v3→v4→v5→v6
  - v4: `Himno_Busqueda` con texto pre-normalizado para búsqueda rápida en Android
  - v5: Columna `evento` en Himno (para registrar evento/semana del himno)
  - v6: Eliminado tipo `'video'` del CHECK constraint de Fondo_Pantalla (recreación de tabla)
- Scripts: `scripts/insertar_himnos_convenciones.py` — inserta 25 himnos desde PDF

## Estructura del Proyecto
```
lib/
├── core/
│   ├── database/          → database_helper.dart, schema.sql
│   ├── utils/             → chord_transposer, flag_utils, string_utils, stanza_layout_engine, audio_file_service, file_storage_service
│   ├── constants/         → musical_constants
│   ├── enums/             → estrofa_tipo, himno_tipo, fondo_pantalla_tipo, usuario_rol
│   ├── errors/            → auth_exception, exceptions, failures
│   ├── network/           → mdns_discovery, bonsoir_broadcast_service, bonsoir_service, permission_service, connection_state
│   ├── theme/             → app_theme
│   └── window_manager/    → window_service, window_providers, window_state
├── data/
│   ├── datasources/local/  → hymn, catalog, user, arreglo, audio
│   ├── datasources/remote/ → grpc_control_datasource, grpc_display_server
│   ├── models/             → himno, estrofa, categoria, usuario, version_pais, pista_audio, fondo_pantalla
│   ├── models/mappers/     → entidad ⇄ modelo
│   └── repositories/       → hymn, user, arreglo, audio, control, fondo
├── domain/
│   ├── entities/          → himno, estrofa, categoria, usuario, version_pais, pista_audio, fondo_pantalla
│   ├── repositories/      → interfaces
│   └── usecases/          → admin, auth, himno, arreglo, audio, control, transposicion
├── presentation/
│   ├── shared_widgets/    → hymn_card, control_sheets, fab_menu, search_bar, alphabet_index_bar
│   │   └── providers/     → appearance_provider, fondo_options_provider
│   ├── views_personal/
│   │   ├── dashboard/     → home_screen, connected_dashboard, present_button
│   │   ├── hymn_scroll/   → hymn_detail_screen, arrangement_editor_screen, fab_menu
│   │   └── providers/     → hymn, audio, transpose
│   ├── views_projection/
│   │   ├── controller/    → live_control, minimal_control, present_control_bar, discover_display_sheet
│   │   ├── display/       → live_projection, simple_projection, standby, projection_app, receptor_binding
│   │   └── providers/     → connection, live_control, discovery, presentation, projection
│   ├── views_admin/
│   │   ├── crud_hymns/    → hymn_form, hymn_list, stanza_block_editor, categoria_selector
│   │   ├── crud_catalogs/ → pais_tab, categoria_tab, pista_tab, fondo_tab, catalog_panel
│   │   └── providers/     → admin_providers, auth_providers
│   └── dual_mode_wrapper/ → himnario_dual_app, device_mode, device_switch, dual_mode_providers
├── bootstrap/             → app_initializer
└── main.dart
```

## Rama activa
- **`feature/db-auto-update`** — Mecanismo de auto-actualización de base de datos desde assets (desacoplado de sqflite `onUpgrade`, con archivo manifiesto `db_version.json`)
- **`main`** (commit `f9077af`) — Rama estable con las 3 funcionalidades recuperadas (ventana Windows, orden estrofas, F11)

## Características implementadas
- Modo personal: búsqueda, filtros (tipo, A-Z, Z-A, categoría), scroll alfabético
- Acordes sobre el texto (ChordParser + ChordPainter con caché LRU + ChordOverlayText)
- Toggle global de acordes (`showChords` persistente en DB, botón Solfa funcional)
- Transposición de tonos con tonalidad detectada del primer acorde
- Brocha: tamaño fuente, color letra, color acordes, fondos color/imagen desde BD, selector de fuente, negritas
- Brocha conectada: cambios de apariencia se sincronizan vía IPC a ventana de proyección
- Brocha auto-refresh (Consumer + invalidate de fondosActivosProvider)
- Paleta de 22 colores rápidos + selector HSV libre para fondos en admin
- Opacidad configurable de tarjetas de estrofa (cardOpacity slider)
- Escalado independiente de fuente en modo proyección (`projectionFontScale`)
- Proyección con scroll condicional (auto-fit eliminado, SingleChildScrollView si texto no cabe)
- Reflow de acordes en proyección (StanzaLayoutEngine.processStanza para contenido ChordPro)
- Padding horizontal reducido en proyección: 80px → 40px (50 %)
- Pistas de audio: reproducción local, barra de progreso, seek, pausa/reanudar
- Panel admin: CRUD himnos, categorías, países, fondos (color/imagen), pistas
- Admin directo (icono de ajustes en lugar de candado + login)
- Al eliminar fondo: se refresca la brocha/vista del himno, se borra la copia local (nunca el original)
- Fondos de imagen se copian automáticamente a `{appDocs}/himnario_id/fondos/` al seleccionarlos (FileStorageService)
- Limpieza de código muerto: eliminados FondoPantallaTipo.video, 3 directorios huérfanos, login_screen, barrel files, 6 providers deprecados
- Filtros A-Z, Z-A por título (inteligente: ignora acentos y puntuación)
- Scroll alfabético lateral (tipo Xiaomi)
- Búsqueda inteligente (en estrofas, ranking por relevancia, tabla pre-normalizada)
- Búsqueda optimizada para Android (debounce 400ms, eliminado N+1, tabla `Himno_Busqueda`)
- Flujo de presentación por slides: Title → Lyrics → Amen
- Labels de estrofa en proyección: "Estrofa 1", "Coro", "Puente 2", etc.
- Modo proyección con ventana secundaria (SubprocessWindowService + IPC JSON)
- Conexión Emisor/Receptor vía mDNS + gRPC (infraestructura completa)
  - Servidor gRPC funcional (GrpcDisplayServer) en lib/data/datasources/remote/
  - Broadcast mDNS vía Bonsoir (BonsoirBroadcastService) en lib/core/network/
  - Descubrimiento mDNS (MdnsDiscovery) en lib/core/network/
  - Orquestación centralizada en AppInitializer (initNetworkServices)
  - Try/catch en cada capa con logs informativos y degradación graceful
  - Detección automática de plataforma: desktop → servidor gRPC (+ broadcast), móvil → discovery
- Build Android funcional (APK release 65.5MB con JDK 17)
- 25 himnos adicionales de convenciones/campamentos insertados desde script Python
- **F11 fullscreen**: Handler global para alternar pantalla completa en desktop (`FullscreenHandler`)
- **Slider tamaño letra proyección visible en móvil**: Condición `isDesktopModeProvider || isConnectedProvider` en `control_sheets.dart`
- **Orden himnos Oficiales primero**: `CASE WHEN h.tipo = 1 THEN 0 ELSE 1 END` en `_defaultOrderBy` del datasource — 0 hardcodes de `h.numero_oficial ASC` fuera del getter
- **Filtro Convención**: Chip en HomeScreen + ConnectedDashboard para filtrar por `HimnoTipo.convencion`
- **CRUD Usuarios backend**: CatalogLocalDataSource (4 métodos SQL), AdminRepository (interfaz + impl), manage_usuarios.dart (4 use cases), admin_providers.dart (5 providers Riverpod). UI removida del panel admin (se conserva lógica para futuro)
- **Título ventana Windows**: `windows/runner/main.cpp` → `L"MQ App"` como título de la ventana principal
- **Numeración correcta de estrofas en proyección**: `_calcStanzaNumber()` en `live_projection_screen.dart` — cuenta solo slides no-coro para etiquetas "Estrofa 1, Coro, Estrofa 2..."
- **F11 en modo proyección**: `FullscreenHandler` envuelve `MaterialApp` en `projection_app.dart` + `windowManager.ensureInitialized()` temprano en `main.dart` para modo `--projection`

## Estado de Tests
- **Unit + Widget**: 263 tests
- **Integración**: 11 tests (~11 fallan por NOT NULL en tabla Pais)
- **Total**: 274 tests (~11 fallos conocidos)
- **`dart analyze lib/`**: 0 errors, 0 warnings (27 info de estilo pre-existentes)

## Plataformas Soportadas
- **Linux** (desarrollo principal) ✅
- **Android** (APK release, requiere JDK 17) ✅
- **Windows** (no probado)
- **macOS/iOS** (no probado)

## Pistas de Audio
- Alojadas en: GitHub Releases (`v1.0-audio`)
- URL base: `https://github.com/moy385/HimnarioID_2.0/releases/download/v1.0-audio/`
- Pendiente: implementar descarga desde la app

## Ramas Mergeadas a main
- `feature/pc-modo-personal` — Adaptación de UI para desktop
- `feature/fase4-subprocess-window` — Ventana de proyección secundaria
- `feature/brocha-conectada` — Sincronización IPC de apariencia
- `feature/escalado-proyeccion` — Font scale independiente en proyección
- `feature/flujo-presentacion-slides` — Slides Title→Lyrics→Amen
- `feature/busqueda-android-tabla-plana` — Tabla pre-normalizada para Android
- `feature/proyeccion-estrofa-visibilidad` — Stack overlay + labels en proyección
- `feature/acordes-sobre-texto` — ChordParser + ChordPainter + ChordOverlayText con caché LRU
- `feature/acordes-toggle-global` — Toggle showChords persistente, botón Solfa funcional
- `feature/proyeccion-auto-fit` — Scroll condicional en proyección
- `feature/proyeccion-line-breaking` — Reflow de acordes con StanzaLayoutEngine
- `feature/settings-panel-sin-login` — Admin directo (icono de ajustes sin login forzoso)
- `feature/agregar-himnos-convenciones` — 25 himnos de convenciones + mejoras brocha + fondos + fix delete
- `feature/copiar-fondos-a-local-storage` — FileStorageService, copia de fondos a directorio local de la app
- `chore/limpieza-codigo-muerto` — 310 líneas eliminadas, 32 archivos. Limpieza post-revert de video
- `feature/flujo-emisor-receptor` — Conexión gRPC Emisor/Receptor + mDNS + envío automático de himno, comandos SET_BACKGROUND/SET_FONT_SIZE, F11 fullscreen, slider proyección en móvil emisor conectado
- `feature/orden-filtros-admin-crud` — Orden himnos Oficiales primero, filtro Convención, CRUD Usuarios backend
- `feature/peticiones-mayo-2026` — Cambios solicitados mayo 2026 (revertidos parcialmente: ventana Windows, orden estrofas, F11 recuperados en commit `f9077af`; DB auto-update, etiqueta Personal, botones separados revertidos permanentemente)

## DB Auto-Update (implementado 22 mayo 2026)
- **Arquitectura**: Dos capas de versionado ortogonales:
  - **SCHEMA_VERSION** (constante 6 en `DatabaseHelper`) → migraciones estructurales vía `onUpgrade`
  - **ASSET_VERSION** (`assets/db/db_version.json`) → reemplazo completo de seed data
- **Nuevos archivos**: `db_version_manager.dart`, `user_data_backup.dart`, `db_update_screen.dart`
- **Flujo**: Backup de datos de usuario (7 tablas) → reemplazar .db desde assets → restore → abrir BD
- **Rama**: `feature/db-auto-update` (commit `6db1c31`)
- **Reporte detallado**: `doc/implementacion.md`

## Cambios en builds (22 mayo 2026)
- **APK Android**: Build con `--split-per-abi` genera APKs separados por arquitectura (~24MB c/u). Script: `scripts/build_apk.sh`.
- **Ejecutable Windows**: Renombrado de `himnario_id_2.exe` a `MQ_App.exe` (`windows/CMakeLists.txt` BINARY_NAME).

## Pantalla completa inmersiva en móvil (22 mayo 2026)
- **Nuevo**: Botón `Icons.fullscreen` ⛶ en la barra inferior del detalle de himno (solo modo personal en móvil).
- **Funcionamiento**: Al pulsar, activa `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` que oculta la barra de estado, la barra de navegación del sistema, el AppBar, la barra inferior de controles y el FAB. El himno se muestra a pantalla completa con el fondo seleccionado por el usuario.
- **Salida**: Doble tap en cualquier parte del himno restaura la UI normal. También funciona el gesto de "atrás" de Android (PopScope).
- **Provider**: `FullscreenModeNotifier` en `lib/presentation/providers/fullscreen_mode_provider.dart` (StateNotifier con Riverpod).
- **Edge cases cubiertos**:
  - Al minimizar la app o recibir llamada: `WidgetsBindingObserver` restaura la UI automáticamente.
  - Al navegar fuera de la pantalla: `dispose()` del State restaura SystemChrome.
  - Al hacer dispose del provider: `dispose()` de `FullscreenModeNotifier` restaura SystemChrome.
  - Solo visible en móvil (no en desktop, que ya tiene su propio fullscreen vía F11).
  - No disponible en web (try-catch en SystemChrome).
- **Animación**: `AnimatedSwitcher` con duración 300ms y curvas easeIn/easeOut.
- **Archivos**: `lib/presentation/providers/fullscreen_mode_provider.dart` (nuevo, 52 líneas), `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart` (modificado).

## Notas técnicas importantes
- **Fondos de video**: Se intentó implementar con `video_player_media_kit` / `media_kit` + libmpv, pero se descartó por crash irrecuperable en Linux (assertion `group_index >= 0` en libmpv 0.41.0). Todo el código de video fue revertido. Pendiente para cuando Ubuntu actualice libmpv.
- **File Picker**: Los archivos de fondo (imagen) se seleccionan con `file_picker`. Se copian automáticamente a `{appDocs}/himnario_id/fondos/` con nombre único. Al eliminar un fondo, `FileStorageService.deleteIfAppFile()` solo borra si está dentro del directorio app, nunca el archivo original del usuario.
- **Riverpod caching**: Los `FutureProvider` cachean su resultado hasta invalidación explícita. Es crítico invalidar `fondosActivosProvider` tras crear/editar/eliminar fondos.
- **Limpieza de código muerto (20 mayo 2026)**: Se eliminaron `FondoPantallaTipo.video`, 3 directorios huérfanos (`state_management/`, `app_controller/`, `app_display/`), `login_screen.dart`, barrel files (`views_admin.dart`, `views_personal.dart`, `views_projection.dart`), y 6 providers deprecados de `live_control_providers.dart`. Total: 310 líneas, 32 archivos.
- **Infraestructura de red (20 mayo 2026)**: Se implementó `GrpcDisplayServer` (servidor gRPC completo con 7 comandos, handshake y watchStatus streaming), `BonsoirBroadcastService` (publicación mDNS), detección de plataforma con TargetPlatform, y orquestación centralizada en `AppInitializer`. Desktop → gRPC + broadcast. Móvil → discovery Bonsoir. Try/catch con degradación graceful en cada capa.
