# Arquitectura de Presentación — HimnarioID 2.0

> **Proyecto analizado:** HimnarioID 2.0 (READ ONLY)
> **Fecha:** Junio 2026
> **Objetivo:** Documentar el funcionamiento exacto del modo presentación y control remoto para portar a MQ-App

---

## 1. Flujo de Usuario

### 1.1 Cómo iniciar presentación

El flujo completo es:

```
Usuario abre app → Navega al Dashboard → Ve botón "Presentar" → Toca "Presentar"
     ↓
Se abre ventana secundaria (subproceso) con argumento --projection
     ↓
isPresentingProvider = true → Aparece PresentControlBar en la ventana principal
     ↓
Usuario selecciona un himno → Se carga en liveControlProvider
     ↓
El himno se envía a la ventana de proyección vía JSON por stdin
     ↓
La ventana secundaria renderiza LiveProjectionScreen con el himno
```

### 1.2 Botón "Presentar" — Ubicación y comportamiento

**Archivo:** `lib/presentation/views_personal/dashboard/present_button.dart`

- **Widget:** `PresentButton` (FloatingActionButton.extended)
- **Posición:** En el Dashboard (pantalla principal), como FAB extendido
- **Condiciones para mostrar:** Siempre visible en el dashboard (no hay condicional de visibilidad)
- **Colores:**
  - Modo inactivo: fondo dorado `#CCA43B`, texto/icono negro `#1A1A1A`
  - Modo activo: fondo `errorContainer` (rojo), texto "Detener Presentación"
- **Iconos:** `screen_share` (inactivo) / `stop_screen_share` (activo)

**Al tocar "Presentar":**
1. Lee `windowServiceProvider` del Riverpod container
2. Llama `windowService.openProjectionWindow({'mode': 'local', 'source': 'dashboard'})`
3. Setea `isPresentingProvider.notifier.state = true`

**Al tocar "Detener Presentación":**
1. Llama `windowService.closeProjectionWindow()`
2. Setea `isPresentingProvider.notifier.state = false`

### 1.3 Controles disponibles

Cuando `isPresenting = true`, aparece **PresentControlBar** en la parte inferior de la ventana principal:

**Archivo:** `lib/presentation/views_projection/controller/present_control_bar.dart`

**Estructura de la barra (de arriba a abajo):**

1. **Header:**
   - Icono `music_note` + título del himno cargado
   - Botón "Salir" (cierra ventana de proyección, resetea estado)

2. **Navegación:**
   - Botón "Anterior" (`skip_previous`) — deshabilitado si no hay slide anterior
   - Indicador central: `displayLabel` + `índice / total`
   - Botón "Siguiente" (`skip_next`) — deshabilitado si no hay slide siguiente

3. **Funciones:**
   - **Brocha** (`brush`) → Abre `showBrushSheet()` — configuración visual
   - **Solfa** (`music_note`) → Abre `showSolfaSheet()` — panel de músico (transposición, acordes)
   - **Nota** (`audiotrack`) → Abre `showNoteSheet()` — pistas de audio
   - **Lupa** (`search`) → Abre `showSearchSheet()` — búsqueda de himnos

**Al navegar (prev/next):**
- Actualiza `liveControlProvider.notifier.nextSlide()` / `.prevSlide()` (estado local)
- Envía mensaje JSON al subproceso: `windowService.sendMessage({'type': 'NEXT_SLIDE'})`

### 1.4 Pantalla de Control en Vivo (LiveControlScreen)

**Archivo:** `lib/presentation/views_projection/controller/live_control_screen.dart`

Esta es una pantalla **completa** (no una barra) que se usa como alternativa al PresentControlBar. Tiene:

- **Preview Panel:** Muestra slide actual y siguiente lado a lado
- **Botón GIGANTE "SIGUIENTE"** (40% de la pantalla, flex:4)
- **Botón "Anterior"** (flex:2)
- **Accesos rápidos:**
  - "Ir al Coro" → busca primer coro en slides
  - "Ir al Inicio" → slide 0 (título)
  - "Apagar/Encender" → toggle blackout
- **Botón de configuración** (tune) → abre sheet con fondo, fuente, transición, glass effect

**Cada botón envía comandos tanto localmente como por gRPC si hay conexión:**
```dart
_sendCommand(
  ref,
  () => ref.read(liveControlProvider.notifier).nextSlide(),  // local
  (repo) => repo.sendNextStanza(),                            // gRPC remoto
);
```

### 1.5 MinimalControlScreen (modo Emisor en móvil)

**Archivo:** `lib/presentation/views_projection/controller/minimal_control_screen.dart`

Panel de control para modo **Emisor** (móvil conectado a PC). Se abre al seleccionar un himno en `ConnectedDashboard`.

- Sin scroll de letra, solo controles de navegación
- Envía himno completo al display remoto vía `sendHymnContent()`
- Envía apariencia actual vía `sendSetAppearance()`
- Botones: Anterior, Siguiente, Brocha, Solfa, Nota, Lupa

---

## 2. Arquitectura Técnica

### 2.1 Multi-window (SubprocessWindowService)

**Archivo:** `lib/core/window_manager/window_service.dart`

El sistema usa **3 implementaciones** de `WindowService` según plataforma:

| Plataforma | Implementación | Mecanismo |
|---|---|---|
| Windows/Linux/macOS | `SubprocessWindowService` | `Process.start()` con `--projection` |
| Web | `WebWindowService` | `window.open()` + `BroadcastChannel` (TODO) |
| Móvil | `MobileWindowService` | Stub — no soportado |

**Provider:** `lib/core/window_manager/window_providers.dart`
```dart
final windowServiceProvider = Provider<WindowService>((ref) {
  if (kIsWeb) return WebWindowService();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
    return SubprocessWindowService();
  return MobileWindowService();
});
```

### 2.2 SubprocessWindowService — Cómo funciona

```
Proceso Principal (PC)                    Subproceso (--projection)
─────────────────────                    ──────────────────────────
Platform.resolvedExecutable              
  + ['--projection']                     
  → Process.start() ────────────────────→  Nueva instancia Flutter
                                          ProjectionApp()
                                          │
Proceso principal escribe:                Proyección lee de stdin:
stdin.write(jsonEncode(message) + '\n') ──→ stdin.transform(utf8).transform(LineSplitter)
                                          │
                                          Procesa mensajes:
                                          - LOAD_HYMN
                                          - NEXT_SLIDE
                                          - PREV_SLIDE
                                          - GO_TO_SLIDE
                                          - SET_CONFIG
                                          - SET_BACKGROUND
                                          - BLACKOUT
```

**Detalles clave:**
- El subproceso se lanza con `Platform.resolvedExecutable` + argumento `['--projection']`
- `workingDirectory: Directory.current.path`
- Comunicación **unidireccional**: padre → hijo vía stdin del hijo
- El hijo puede responder por stdout (parseado por el padre en `_messageController`)
- Al cerrar: `_projectionProcess!.kill()`

### 2.3 Protocolo JSON (stdin/stdout)

**Mensajes que el padre envía al hijo:**

| Tipo | Campos | Descripción |
|---|---|---|
| `LOAD_HYMN` | `himno_id`, `titulo`, `numero`, `tipo`, `estrofas[]` | Carga himno completo |
| `NEXT_SLIDE` | — | Avanza al siguiente slide |
| `PREV_SLIDE` | — | Retrocede al slide anterior |
| `GO_TO_SLIDE` | `index` (int) | Va a slide específico |
| `SET_CONFIG` | `textColor`, `chordColor`, `fontFamily`, `isBold`, `fontScale`, `projectionFontScale`, `showChords`, `cardOpacity`, `glassBlurSigma`, `glassEnabled`, `glassOverlayColor` | Actualiza apariencia |
| `SET_BACKGROUND` | `bgFondoId` (string) | Cambia fondo de pantalla |
| `BLACKOUT` | `enabled` (bool) | Activa/desactiva pantalla negra |

**Formato de estrofas en LOAD_HYMN:**
```json
{
  "type": "LOAD_HYMN",
  "himno_id": 42,
  "titulo": "Cuan Grande Es El",
  "numero": 42,
  "tipo": "oficial",
  "estrofas": [
    {
      "id": 1,
      "version_pais_id": 1,
      "tipo": "estrofa",
      "orden": 1,
      "contenido": "[C]Texto con acordes"
    }
  ]
}
```

### 2.4 Punto de entrada — main.dart

**Archivo:** `lib/main.dart`

```
main(args)
  ├─ args.contains('--projection')?
  │   ├─ SÍ → _startProjectionWindow()
  │   │   ├─ ProviderContainer()
  │   │   ├─ AppInitializer.initialize(container, skipNetwork: true)
  │   │   │   → NO inicia gRPC server, NO inicia mDNS
  │   │   └─ runApp(ProjectionApp())
  │   │       → ProjectionApp escucha stdin
  │   │       → Muestra LiveProjectionScreen o "Esperando proyección..."
  │   └─ (return)
  └─ NO → _startMainApp()
      ├─ AppInitializer.initialize(container)
      │   ├─ _initDatabase()
      │   ├─ _initPlatform()
      │   ├─ _initNetworkServices()
      │   │   ├─ Desktop → _initDisplayServer() → GrpcDisplayServer + mDNS broadcast
      │   │   └─ Móvil   → _initControllerDiscovery() → MdnsDiscovery
      │   └─ _initNsdDiscovery()
      └─ runApp(HimnarioApp())
```

**Importante:** El subproceso de proyección usa `skipNetwork: true`, lo que significa:
- NO inicia servidor gRPC
- NO inicia broadcast mDNS
- NO inicia discovery nsd
- Se comunica **exclusivamente** por stdin/stdout

### 2.5 ProjectionApp (ventana secundaria)

**Archivo:** `lib/presentation/views_projection/display/projection_app.dart`

- Widget raíz del subproceso
- Escucha stdin para recibir mensajes JSON
- Renderiza `LiveProjectionScreen` si hay himno, o "Esperando proyección..."
- Usa `FullscreenHandler` para manejo de pantalla completa
- Tema: `AppTheme.projectionTheme`
- Background: negro por defecto

**Manejo de mensajes:**
```dart
switch (message['type']) {
  case 'LOAD_HYMN':    → Construye Himno + Estrofas → notifier.loadHymn()
  case 'NEXT_SLIDE':   → notifier.nextSlide()
  case 'PREV_SLIDE':   → notifier.prevSlide()
  case 'GO_TO_SLIDE':  → notifier.goToSlide(index)
  case 'SET_CONFIG':   → Actualiza hymnAppearanceProvider
  case 'SET_BACKGROUND': → Carga FondoPantalla por ID
  case 'BLACKOUT':     → notifier.blackout() / toggleBlackout()
}
```

### 2.6 LiveProjectionScreen (renderizado)

**Archivo:** `lib/presentation/views_projection/display/live_projection_screen.dart`

Renderiza 3 tipos de slides:

| Tipo | Widget | Contenido |
|---|---|---|
| `TitleSlide` | `_TitleSlide` | Título enorme + número semitransparente, centrado |
| `LyricsSlide` | `_LyricsSlide` | Letra de estrofa con transición fade, progress dots, etiqueta de tipo |
| `AmenSlide` | `_AmenSlide` | "Amén" centrado, fuente enorme |

**Características:**
- Fondo: color sólido o imagen (desde `FondoPantalla`)
- Glassmorphism opcional (blur + overlay de color)
- Detección de desbordamiento vertical → scroll automático
- Soporte ChordPro con `ResponsiveChordWidget`
- Chip de conexión gRPC en esquina inferior derecha (verde=running, rojo=stopped)
- Blackout: pantalla completamente negra

### 2.7 ProjectionSlide (modelo)

**Archivo:** `lib/domain/entities/projection_slide.dart`

```dart
sealed class ProjectionSlide {
  TitleSlide(himno: Himno)     // Slide 0: portada
  LyricsSlide(estrofa: Estrofa) // Slides 1..N-1: letra
  AmenSlide()                   // Slide N: cierre
}
```

**Flujo de slides:** `[TitleSlide, LyricsSlide(estrofa1), LyricsSlide(estrofa2), ..., AmenSlide]`

---

## 3. Control Remoto (gRPC + mDNS)

### 3.1 Descubrimiento de dispositivos

**Arquitectura dual según rol:**

| Rol | Plataforma | Mecanismo |
|---|---|---|
| **Display** (PC) | Windows | `MdnsBroadcastService` → publica `_himnario._tcp` vía `nsd` |
| **Display** (PC) | Linux | Solo gRPC server, **sin mDNS broadcast** (nsd no soporta Linux) |
| **Controlador** (móvil) | Android/iOS | `MdnsDiscovery` + `NsdDiscoveryService` → escanea `_himnario._tcp` |

**Servicio mDNS:**
- **Tipo:** `_himnario._tcp`
- **TXT Records:** `sessionId`, `displayName`
- **Puerto:** 50051 (default, con fallback hasta 50060)

**Archivos:**
- `lib/core/network/mdns_broadcast_service.dart` — Publica servicio (solo Windows)
- `lib/core/network/mdns_discovery.dart` — Descubre servicios (móvil)
- `lib/core/network/nsd_discovery_service.dart` — Wrapper de `nsd` package

**Limitación conocida:** `nsd` NO soporta Linux. En Linux el broadcast se omite y el usuario debe conectar manualmente por IP.

### 3.2 Handshake

**Archivo:** `lib/data/datasources/remote/grpc_control_datasource.dart`

Cuando el controlador se conecta a un display:

1. Crea `ClientChannel` con `ChannelCredentials.insecure()`
2. Crea `HymnControlClient`
3. Envía `HandshakeRequest`:
   ```protobuf
   client_name: "MQ App Controller"
   client_version: "2.0.0"
   protocol_version: 1
   ```
4. Recibe `HandshakeResponse`:
   ```protobuf
   accepted: true
   server_name: "MQ App Display"
   server_version: "2.0.0"
   display_name: "Display Principal"
   protocol_version: 1
   session_id: "<uuid>"
   ```
5. Si `accepted == false` → lanza `NetworkException`

### 3.3 Comandos disponibles (proto)

**Archivo:** `proto/hymn_control.proto`

**Servicio:** `HymnControl`

| RPC | Request → Response | Descripción |
|---|---|---|
| `SendCommand` | `CommandRequest` → `CommandResponse` | Envía comando de control |
| `GetStatus` | `Empty` → `DisplayStatus` | Obtiene estado actual |
| `WatchStatus` | `Empty` → `stream DisplayStatus` | Streaming de estado en tiempo real |
| `Handshake` | `HandshakeRequest` → `HandshakeResponse` | Handshake inicial |
| `SendHymnContent` | `HymnPayload` → `CommandResponse` | Envía himno completo |
| `GetAvailableBackgrounds` | `Empty` → `BackgroundList` | Lista fondos del PC |

**CommandType enum:**

| Valor | Descripción |
|---|---|
| `NEXT_STANZA` (0) | Avanzar estrofa |
| `PREV_STANZA` (1) | Retroceder estrofa |
| `GO_TO_CHORUS` (2) | Ir al coro |
| `GO_TO_STANZA` (3) | Ir a estrofa específica |
| `BLACKOUT` (4) | Pantalla negra |
| `CLEAR_BLACKOUT` (5) | Quitar pantalla negra |
| `SET_TRANSPOSITION` (6) | Cambiar transposición |
| `JUMP_TO_HYMN` (7) | Cargar himno por ID |
| `SET_BACKGROUND` (8) | Cambiar fondo |
| `SET_FONT_SIZE` (9) | Cambiar tamaño fuente |
| `PING` (10) | Keep-alive |
| `SET_APPEARANCE` (11) | Configurar apariencia completa |

### 3.4 GrpcDisplayServer (lado del display)

**Archivo:** `lib/data/datasources/remote/grpc_display_server.dart`

**Configuración:**
- Puerto: 50051 (con retry hasta 50060)
- Escucha en `0.0.0.0` (todas las interfaces)
- Keep-alive: ping cada 10s, max 3 bad pings

**Callbacks configurados por AppInitializer:**
- `onCommand` → Actualiza `liveControlProvider` en el display
- `onJumpToHymn` → Carga himno desde DB por ID
- `onClientConnected` → Setea `isClientConnectedProvider = true`
- `onLoadHymnContent` → Carga himno desde payload completo

**Sincronización con subproceso:**
Cuando un comando llega por gRPC, el server también sincroniza con la ventana de proyección:
- `_syncAppearanceToSubprocess()` → Envía `SET_CONFIG` por stdin
- `_syncBackgroundToSubprocess()` → Envía `SET_BACKGROUND` por stdin

### 3.5 ConnectionNotifier (lado del controlador)

**Archivo:** `lib/presentation/views_projection/providers/connection_providers.dart`

Maneja la conexión del controlador al display:

- **Heartbeat:** Ping cada 15 segundos
- **Reconexión:** Backoff exponencial (1s, 2s, 4s, 8s, 16s), máximo 5 intentos
- **Estados:** `Disconnected` → `Connecting` → `Connected(device)` o `ConnectionError`
- **WatchStatus:** StreamProvider que emite `DisplayStatus` en tiempo real

### 3.6 Sincronización de estado

**Flujo completo de un comando remoto:**

```
Móvil (Controlador)                    PC (Display)                    Subproceso (Proyección)
─────────────────                      ────────────                    ───────────────────────
1. Usuario toca "Siguiente"
2. liveControlProvider.notifier.nextSlide()
3. controlDataSource.sendNextStanza() ──→ gRPC SendCommand(NEXT_STANZA)
                                         │
                                         ├─ GrpcDisplayServer.sendCommand()
                                         │  → _dispatch(state.copyWith(currentSlideIndex + 1))
                                         │  → onCommand callback → liveControlProvider actualizado
                                         │
                                         └─ watchStatus stream emite nuevo DisplayStatus
                                             → Móvil recibe actualización
```

**Flujo de carga de himno remoto:**

```
Móvil                                    PC                            Subproceso
─────                                    ──                            ──────────
1. Usuario selecciona himno
2. Construye HymnPayload
3. sendHymnContent(payload) ─────────→ gRPC SendHymnContent
                                        │
                                        ├─ onLoadHymnContent callback
                                        │  → liveControlProvider.notifier.loadHymn()
                                        │
                                        └─ (subproceso NO recibe nada directo)
                                            El subproceso solo recibe LOAD_HYMN
                                            cuando el control local lo envía
```

**Nota importante:** El subproceso de proyección NO recibe comandos gRPC directamente. Solo recibe mensajes JSON por stdin del proceso padre. El `GrpcDisplayServer` sincroniza apariencia y fondo al subproceso, pero la navegación de slides se maneja directamente en el `liveControlProvider` del proceso principal.

---

## 4. Providers Riverpod

### 4.1 Grafo de dependencias

```
windowServiceProvider ──────────────────→ Provider<WindowService>
isPresentingProvider ───────────────────→ StateProvider<bool> (false)

liveControlProvider ────────────────────→ StateNotifierProvider<LiveControlNotifier, LiveControlState>
  ├─ hymn: Himno?
  ├─ slides: List<ProjectionSlide>
  ├─ currentSlideIndex: int
  ├─ isBlackout: bool
  └─ versionPaisId: int?

currentSlideProvider ───────────────────→ Provider<ProjectionSlide?> (deriva de liveControlProvider)
isBlackoutProvider ─────────────────────→ StateProvider<bool> (false)

projectionConfigProvider ───────────────→ StateNotifierProvider<ProjectionConfigNotifier, ProjectionConfig>
  ├─ background: ProjectionBackground
  ├─ fontSize: ProjectionFontSize
  ├─ transitionSpeed: double
  └─ fondoSeleccionado: FondoPantalla?

hymnAppearanceProvider ─────────────────→ StateNotifierProvider (texto, acordes, fuente, glass, fondo)

connectionStateProvider ────────────────→ StateNotifierProvider<ConnectionNotifier, ConnectionState>
isConnectedProvider ────────────────────→ Provider<bool> (deriva de connectionStateProvider)
connectionRoleProvider ─────────────────→ StateProvider<ConnectionRole>
controlDataSourceProvider ──────────────→ Provider<GrpcControlDataSource>
controlRepositoryProvider ──────────────→ Provider<ControlRepository>

grpcDisplayServerProvider ──────────────→ Provider<GrpcDisplayServer?> (null en web/móvil)
receptorInfoProvider ───────────────────→ Provider<ReceptorInfo> (deriva de grpcDisplayServerProvider)
isClientConnectedProvider ──────────────→ StateProvider<bool>

displayScannerProvider ─────────────────→ FutureProvider<List<DiscoveredDisplay>> (escaneo nsd)
liveDisplayStatusProvider ──────────────→ StreamProvider<DisplayStatus?> (watchStatus gRPC)
```

### 4.2 Estado compartido

**LiveControlState** es el estado central compartido entre:
- Ventana principal (PresentControlBar / LiveControlScreen)
- Ventana de proyección (LiveProjectionScreen) — copia vía JSON
- Controlador remoto — copia vía gRPC WatchStatus

**Sincronización en 3 direcciones:**

1. **Local → Subproceso:** `windowService.sendMessage()` (JSON por stdin)
2. **Local → Remoto:** `controlDataSource.sendCommand()` (gRPC)
3. **Remoto → Local:** `onCommand` callback en `GrpcDisplayServer` → actualiza `liveControlProvider`

---

## 5. Diferencias con MQ-App

### 5.1 Qué se portó correctamente

MQ-App tiene los mismos archivos estructurales:

| Archivo | HimnarioID 2.0 | MQ-App | Estado |
|---|---|---|---|
| `present_button.dart` | ✅ | ✅ | Portado |
| `present_control_bar.dart` | ✅ | ✅ | Portado |
| `presentation_providers.dart` | ✅ | ✅ | Portado |
| `projection_app.dart` | ✅ | ✅ | Portado |
| `live_projection_screen.dart` | ✅ | ✅ | Portado |
| `live_control_screen.dart` | ✅ | ✅ | Portado |
| `minimal_control_screen.dart` | ✅ | ✅ | Portado |
| `live_control_providers.dart` | ✅ | ✅ | Portado |
| `projection_providers.dart` | ✅ | ✅ | Portado |
| `window_service.dart` | ✅ | ✅ | Portado |
| `window_providers.dart` | ✅ | ✅ | Portado |
| `grpc_display_server.dart` | ✅ | ✅ | Portado |
| `grpc_control_datasource.dart` | ✅ | ✅ | Portado |
| `control_repository.dart` | ✅ | ✅ | Portado |
| `control_repository_impl.dart` | ✅ | ✅ | Portado |
| `hymn_control.proto` | ✅ | ✅ | Portado |
| `projection_slide.dart` | ✅ | ✅ | Portado |
| `control_sheets.dart` | ✅ | ✅ | Portado |

### 5.2 Qué falta o está roto

**Archivos que NO existen en MQ-App (faltan):**

| Archivo | Rol | Impacto |
|---|---|---|
| `receptor_binding.dart` | Conecta gRPC server con providers en modo display | **CRÍTICO** — sin esto el servidor gRPC no está bindeado a los providers |
| `mdns_broadcast_service.dart` | Publica servicio mDNS en Windows | Alto — sin discovery automático en Windows |
| `mdns_discovery.dart` | Descubre displays en móvil | Alto — sin discovery en móvil |
| `nsd_discovery_service.dart` | Wrapper de nsd package | Alto — sin discovery en Android/iOS |
| `connection_providers.dart` | ConnectionNotifier, displayScannerProvider | **CRÍTICO** — sin esto no hay gestión de conexión |
| `app_initializer.dart` | Inicializa gRPC server, mDNS, DB | **CRÍTICO** — sin esto no se inicia el servidor |

**Posibles problemas a verificar en MQ-App:**

1. **`main.dart`**: ¿Tiene la bifurcación `--projection`? ¿Llama `AppInitializer` con `skipNetwork`?
2. **`GrpcDisplayServer`**: ¿Tiene los callbacks `onCommand`, `onJumpToHymn`, `onClientConnected`, `onLoadHymnContent` configurados?
3. **`LiveProjectionScreen`**: ¿Importa y usa `receptor_binding.dart` para `receptorInfoProvider`?
4. **`PresentControlBar`**: ¿Envía mensajes al subproceso correctamente? ¿Los mensajes coinciden con el protocolo JSON?
5. **`control_sheets.dart`**: ¿La función `_syncAppearanceToProjection()` envía tanto al subproceso como por gRPC?

### 5.3 Qué se debe corregir

**Prioridad ALTA:**
1. Verificar que `main.dart` de MQ-App tenga la lógica `--projection` idéntica
2. Verificar que `AppInitializer` exista y configure el `GrpcDisplayServer` con callbacks
3. Verificar que `receptor_binding.dart` exista y conecte el server gRPC
4. Verificar que `connection_providers.dart` exista con `ConnectionNotifier`

**Prioridad MEDIA:**
5. Verificar que los servicios mDNS/nsd estén presentes para discovery
6. Verificar que `_syncAppearanceToProjection()` sincronice en ambas direcciones
7. Verificar que `LiveProjectionScreen` tenga el chip de conexión gRPC

**Prioridad BAJA:**
8. Verificar que `StandbyScreen` exista (mencionado en `receptor_binding.dart`)
9. Verificar que `FullscreenHandler` exista como widget compartido

---

## 6. Archivos Clave

### 6.1 Entrada y bootstrap

| Archivo | Rol |
|---|---|
| `lib/main.dart` | Punto de entrada. Bifurca entre modo principal y modo proyección (`--projection`) |
| `lib/bootstrap/app_initializer.dart` | Inicializa DB, plataforma, gRPC server, mDNS. Configura callbacks del servidor |
| `lib/bootstrap/app_container.dart` | Configura el ProviderContainer global |

### 6.2 Ventana y multi-window

| Archivo | Rol |
|---|---|
| `lib/core/window_manager/window_service.dart` | Interfaz `WindowService` + 4 implementaciones (Desktop, Subprocess, Web, Mobile) |
| `lib/core/window_manager/window_providers.dart` | Provider que selecciona implementación según plataforma |
| `lib/core/window_manager/window_state.dart` | Modelo `WindowEvent` y tipos de evento |

### 6.3 Presentación (UI)

| Archivo | Rol |
|---|---|
| `lib/presentation/views_personal/dashboard/present_button.dart` | Botón FAB "Presentar"/"Detener" en el dashboard |
| `lib/presentation/views_projection/controller/present_control_bar.dart` | Barra inferior con navegación y funciones (modo desktop) |
| `lib/presentation/views_projection/controller/live_control_screen.dart` | Pantalla completa de control con preview y botones grandes |
| `lib/presentation/views_projection/controller/minimal_control_screen.dart` | Panel minimalista para modo Emisor (móvil) |
| `lib/presentation/views_projection/display/projection_app.dart` | App raíz del subproceso — escucha stdin, renderiza slides |
| `lib/presentation/views_projection/display/live_projection_screen.dart` | Renderiza TitleSlide, LyricsSlide, AmenSlide con fondos y glass |
| `lib/presentation/views_projection/display/receptor_binding.dart` | Conecta gRPC server con providers, determina qué pantalla mostrar |
| `lib/presentation/shared_widgets/control_sheets.dart` | Sheets: Brocha (visual), Nota (audio), Solfa (músico), Lupa (búsqueda) |

### 6.4 Providers

| Archivo | Rol |
|---|---|
| `lib/presentation/views_projection/providers/presentation_providers.dart` | `isPresentingProvider` (StateProvider<bool>) |
| `lib/presentation/views_projection/providers/live_control_providers.dart` | `liveControlProvider` (StateNotifier), `LiveControlState`, `LiveControlNotifier` |
| `lib/presentation/views_projection/providers/projection_providers.dart` | `projectionConfigProvider`, `fondoRepositoryProvider`, enums de config |
| `lib/presentation/views_projection/providers/connection_providers.dart` | `connectionStateProvider`, `ConnectionNotifier`, `displayScannerProvider`, `liveDisplayStatusProvider` |
| `lib/presentation/shared_widgets/providers/appearance_provider.dart` | `hymnAppearanceProvider` — colores, fuentes, glass, fondo |

### 6.5 Red (gRPC + mDNS)

| Archivo | Rol |
|---|---|
| `lib/data/datasources/remote/grpc_display_server.dart` | Servidor gRPC — recibe comandos, actualiza estado, sincroniza con subproceso |
| `lib/data/datasources/remote/grpc_control_datasource.dart` | Cliente gRPC — conecta, envía comandos, watchStatus stream |
| `lib/data/repositories/control_repository_impl.dart` | Repositorio — traduce exceptions a failures |
| `lib/domain/repositories/control_repository.dart` | Interfaz abstracta del repositorio |
| `lib/core/network/mdns_broadcast_service.dart` | Publica `_himnario._tcp` en Windows |
| `lib/core/network/mdns_discovery.dart` | Descubre displays en móvil |
| `lib/core/network/nsd_discovery_service.dart` | Wrapper del package `nsd` para discovery |

### 6.6 Protocolo

| Archivo | Rol |
|---|---|
| `proto/hymn_control.proto` | Definición protobuf: servicio, mensajes, enums |
| `lib/proto/generated/hymn_control.pbgrpc.dart` | Código generado: stubs gRPC |
| `lib/proto/generated/hymn_control.pb.dart` | Código generado: mensajes |

### 6.7 Dominio

| Archivo | Rol |
|---|---|
| `lib/domain/entities/projection_slide.dart` | Sealed class: TitleSlide, LyricsSlide, AmenSlide |
| `lib/domain/entities/himno.dart` | Entidad Himno |
| `lib/domain/entities/estrofa.dart` | Entidad Estrofa |
| `lib/domain/entities/fondo_pantalla.dart` | Entidad FondoPantalla |

---

## 7. Resumen de Patrones Clave

### Patrón 1: Dual Communication
El sistema usa **dos canales de comunicación simultáneos**:
- **stdin/stdout** (JSON) → Para comunicación padre-hijo (ventana principal → ventana de proyección)
- **gRPC** (protobuf) → Para comunicación entre dispositivos (móvil → PC)

### Patrón 2: State Synchronization
El estado de `LiveControlState` se sincroniza en 3 direcciones:
1. Local (Riverpod StateNotifier)
2. Subproceso (JSON por stdin)
3. Remoto (gRPC commands + watchStatus stream)

### Patrón 3: Platform-Specific Window Service
La implementación de `WindowService` se selecciona en runtime según la plataforma, permitiendo que el mismo código funcione en desktop, web y móvil.

### Patrón 4: Callback-Based Server
El `GrpcDisplayServer` no accede directamente a los providers. Usa callbacks (`onCommand`, `onJumpToHymn`, etc.) que son configurados por `AppInitializer` con acceso al `ProviderContainer`.

### Patrón 5: Skip Network for Subprocess
El subproceso de proyección se inicializa con `skipNetwork: true` para evitar:
- Iniciar un segundo servidor gRPC (conflicto de puerto)
- Iniciar mDNS broadcast duplicado
- Consumo innecesario de recursos
