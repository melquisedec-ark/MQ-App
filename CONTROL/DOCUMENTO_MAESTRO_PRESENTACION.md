# DOCUMENTO MAESTRO — Sistema de Presentación MQ-App

> **Fecha:** 2026-06-06
> **Commit:** 34e208f (mq-app-init branch)
> **Estado:** Presentación himnario FUNCIONA | Presentación biblia NO FUNCIONA
> **Tests:** 772/772 passing

---

## 1. RESUMEN EJECUTIVO

### Qué funciona ✅
- **Himnario → Presentar**: Botón FAB en pantalla principal del himnario abre ventana secundaria, carga himno, proyecta estrofas
- **Controles de presentación**: PresentControlBar con navegación (Anterior/Siguiente), Brocha, Solfa, Nota, Lupa
- **Control remoto gRPC**: Celular → PC funciona para himnos (NEXT_STANZA, PREV_STANZA, etc.)
- **Cambio de módulo**: Botón en PresentControlBar cambia entre Biblia/Himnario

### Qué NO funciona ❌
- **Biblia → Presentar**: Botón FAB en home bíblico abre ventana pero NO proyecta versículos
- **Biblia Reader → Presentar**: Botón en AppBar abre ventana pero NO proyecta versículos
- **Biblia Reader → Enviar**: Botón Enviar dice "enviando" pero NO cambia la ventana receptora
- **Navegación bíblica durante presentación**: Cambiar versículo NO sincroniza con proyección

---

## 2. ARQUITECTURA DEL SISTEMA DE PRESENTACIÓN

### 2.1 Componentes principales

```
┌──────────────────────────────────────────────────────────────────┐
│                        MQ-App (Proceso Principal)                │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │  UI Screens     │  │  Providers       │  │  gRPC Server   │  │
│  │  (Home, Reader) │  │  (Riverpod)      │  │  (puerto 50051)│  │
│  └────────┬────────┘  └────────┬─────────┘  └───────┬────────┘  │
│           │                    │                     │           │
│           ▼                    ▼                     ▼           │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              WindowService (SubprocessWindowService)         │ │
│  │  - Abre proceso hijo con --projection                       │ │
│  │  - Envía JSON por stdin del hijo                            │ │
│  │  - Recibe respuestas por stdout del hijo                    │ │
│  └─────────────────────────────┬───────────────────────────────┘ │
└────────────────────────────────┼─────────────────────────────────┘
                                 │ stdin/stdout (JSON)
                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│              Subproceso de Proyección (--projection)             │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │
│  │  ProjectionApp  │  │  LiveProjection  │  │  skipNetwork:  │  │
│  │  (escucha stdin)│  │  Screen          │  │  true          │  │
│  └─────────────────┘  └──────────────────┘  └────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Protocolo JSON (stdin/stdout)

| Mensaje | Campos | Descripción |
|---|---|---|
| `LOAD_HYMN` | `himno_id`, `titulo`, `estrofas[]` | Carga himno completo |
| `LOAD_VERSE` | `libroNombre`, `capitulo`, `versiculos[string]` | Carga capítulo bíblico |
| `NEXT_SLIDE` | — | Avanza al siguiente slide |
| `PREV_SLIDE` | — | Retrocede al slide anterior |
| `GO_TO_SLIDE` | `index` (int) | Va a slide específico |
| `SET_CONFIG` | `textColor`, `fontScale`, `glassEnabled`, etc. | Actualiza apariencia |
| `SET_BACKGROUND` | `bgFondoId` | Cambia fondo |
| `BLACKOUT` | `enabled` (bool) | Pantalla negra |
| `SWITCH_MODULE` | `module` ('hymnal'/'bible') | Cambia módulo activo |

### 2.3 Comandos gRPC (celular → PC)

| Comando | Proto | Handler en servidor |
|---|---|---|
| NEXT_STANZA | `CommandType.NEXT_STANZA` | `sendCommand()` → `_dispatch(nextSlide)` |
| PREV_STANZA | `CommandType.PREV_STANZA` | `sendCommand()` → `_dispatch(prevSlide)` |
| NEXT_VERSE | `CommandType.NEXT_VERSE` | `_handleNextVerse()` |
| PREV_VERSE | `CommandType.PREV_VERSE` | `_handlePrevVerse()` |
| GO_TO_VERSE | `CommandType.GO_TO_VERSE` | `_handleGoToVerse()` |
| SWITCH_TO_BIBLE | `CommandType.SWITCH_TO_BIBLE` | `_handleSwitchToBible()` |

---

## 3. ARCHIVOS CLAVE

### 3.1 Ventana y Multi-window

| Archivo | Rol | Estado |
|---|---|---|
| `lib/core/window_manager/window_service.dart` | Interfaz `WindowService` + `SubprocessWindowService` | ✅ Funciona |
| `lib/core/window_manager/window_providers.dart` | Provider que selecciona implementación por plataforma | ✅ Funciona |

### 3.2 Presentación UI

| Archivo | Rol | Estado |
|---|---|---|
| `lib/presentation/views_projection/controller/present_control_bar.dart` | Barra inferior con navegación y funciones | ✅ Funciona (himnario) |
| `lib/presentation/views_projection/controller/live_control_screen.dart` | Pantalla completa de control (alternativa) | ✅ Funciona |
| `lib/presentation/views_projection/display/projection_app.dart` | App raíz del subproceso — escucha stdin | ✅ Funciona |
| `lib/presentation/views_projection/display/live_projection_screen.dart` | Renderiza slides (Title, Lyrics, Amen, Bible) | ✅ Funciona |
| `lib/presentation/views_projection/display/receptor_binding.dart` | Determina qué pantalla mostrar | ✅ Funciona |

### 3.3 Providers de Presentación

| Archivo | Rol | Estado |
|---|---|---|
| `lib/presentation/views_projection/providers/presentation_providers.dart` | `isPresentingProvider`, `ProjectionModule` enum | ✅ Funciona |
| `lib/presentation/views_projection/providers/live_control_providers.dart` | `liveControlProvider`, `LiveControlState`, `LiveControlNotifier` | ✅ Funciona |
| `lib/presentation/views_projection/providers/bible_appearance_provider.dart` | Apariencia bíblica en receptor | ✅ Funciona |
| `lib/presentation/views_projection/providers/projection_actions.dart` | `projectHymn()`, `projectBibleChapter()` | ⚠️ Parcial |

### 3.4 gRPC Server

| Archivo | Rol | Estado |
|---|---|---|
| `lib/data/datasources/remote/grpc_display_server.dart` | Servidor gRPC — recibe comandos, actualiza estado | ⚠️ Parcial |
| `lib/data/datasources/remote/grpc_control_datasource.dart` | Cliente gRPC — conecta, envía comandos | ✅ Funciona |

### 3.5 Pantallas Bíblicas

| Archivo | Rol | Estado |
|---|---|---|
| `lib/features/biblia/presentation/screens/home_screen.dart` | Pantalla principal (hub) — tiene FAB Presentar | ❌ No proyecta |
| `lib/features/biblia/presentation/screens/bible_reader_screen.dart` | Modo lectura — tiene botón Presentar + Enviar | ❌ No proyecta |

---

## 4. FLUJO DE PROYECCIÓN — HIMNARIO (FUNCIONA)

```
1. Usuario toca FAB "Presentar" en HomeScreen del himnario
2. PresentButton._togglePresentation():
   a. windowService.openProjectionWindow({'mode': 'local', 'source': 'dashboard'})
   b. isPresentingProvider = true
3. Se abre subproceso con --projection → ProjectionApp()
4. Usuario selecciona un himno en la lista
5. HomeScreen._selectHymnForProjection():
   a. projectHymn(ref, himno) → obtiene estrofas del repo
   b. liveControlProvider.notifier.loadHymn(himno, estrofas)
   c. windowService.sendMessage({'type': 'LOAD_HYMN', ...})
6. Subproceso recibe LOAD_HYMN por stdin:
   a. Construye Himno + Estrofas
   b. notifier.loadHymn() → crea slides (TitleSlide + LyricsSlides + AmenSlide)
   c. LiveProjectionScreen renderiza el primer slide
7. Usuario toca "Siguiente" en PresentControlBar:
   a. liveControlProvider.notifier.nextSlide()
   b. windowService.sendMessage({'type': 'NEXT_SLIDE'})
8. Subproceso recibe NEXT_SLIDE → notifier.nextSlide() → renderiza siguiente slide
```

---

## 5. FLUJO DE PROYECCIÓN — BIBLIA (NO FUNCIONA)

### 5.1 Lo que DEBERÍA pasar

```
1. Usuario toca FAB "Presentar" en home_screen.dart (Biblia)
2. _PresentFAB.onPressed():
   a. windowService.openProjectionWindow({'mode': 'local', 'source': 'bible_home'})
   b. isPresentingProvider = true
   c. Esperar 800ms
   d. _projectRandomVerse(ref):
      - Obtener versículo aleatorio del provider
      - Resolver libro, capítulo desde repo
      - Obtener todos los versículos del capítulo
      - liveControlProvider.notifier.loadBibleChapter(...)
      - windowService.sendMessage({'type': 'LOAD_VERSE', ...})
3. Subproceso recibe LOAD_VERSE por stdin:
   a. _handleLoadVerse() → notifier.loadBibleChapter(...)
   b. Crea slides (BibleTitleSlide + VerseSlides + BibleEndSlide)
   c. LiveProjectionScreen renderiza el primer slide
```

### 5.2 Lo que ACTUALMENTE pasa (DEBUG NEEDED)

```
1. Usuario toca FAB "Presentar" → ventana se abre ✅
2. Se espera 800ms ✅
3. _projectRandomVerse() se ejecuta:
   - ¿Obtiene el versículo aleatorio? → VERIFICAR
   - ¿Resuelve el libro? → VERIFICAR
   - ¿Obtiene los versículos? → VERIFICAR
   - ¿Llama a loadBibleChapter? → VERIFICAR
   - ¿Envía LOAD_VERSE al subprocess? → VERIFICAR
4. Subproceso:
   - ¿Recibe LOAD_VERSE por stdin? → VERIFICAR
   - ¿_handleLoadVerse() existe en projection_app.dart? → VERIFICAR
   - ¿notifier.loadBibleChapter() crea los slides? → VERIFICAR
   - ¿LiveProjectionScreen renderiza? → VERIFICAR
```

### 5.3 Lo mismo para BibleReaderScreen

```
1. Usuario toca icono Presentar en AppBar
2. Espera 800ms
3. _projectCurrentChapter():
   - Obtiene libroId, capitulo de los providers
   - Resuelve libro desde repo
   - Obtiene versículos del capítulo
   - liveControlProvider.notifier.loadBibleChapter(...)
   - windowService.sendMessage({'type': 'LOAD_VERSE', ...})
4. Listener de versículo:
   - Cuando cambia versículo → _syncVerseToProjection()
   - Envía GO_TO_SLIDE al subprocess
```

---

## 6. PROTOCOLO JSON EN projection_app.dart

### 6.1 Handlers actuales

Leer `lib/presentation/views_projection/display/projection_app.dart` y verificar que existen:

```dart
switch (message['type']) {
  case 'LOAD_HYMN':    _handleLoadHymn(notifier, message);  // ✅ Existe
  case 'LOAD_VERSE':   _handleLoadVerse(notifier, message); // ¿Existe?
  case 'NEXT_SLIDE':   notifier.nextSlide();                // ✅ Existe
  case 'PREV_SLIDE':   notifier.prevSlide();                // ✅ Existe
  case 'GO_TO_SLIDE':  notifier.goToSlide(message['index']);// ¿Existe?
  case 'SET_CONFIG':   _handleSetConfig(message);           // ✅ Existe
  case 'SET_BACKGROUND': _handleSetBackground(...);         // ✅ Existe
  case 'BLACKOUT':     ...                                  // ✅ Existe
  case 'SWITCH_MODULE': _handleSwitchModule(notifier, msg); // ¿Existe?
}
```

### 6.2 _handleLoadVerse DEBE existir

```dart
void _handleLoadVerse(LiveControlNotifier notifier, Map<String, dynamic> msg) {
  notifier.loadBibleChapter(
    libroNombre: msg['libroNombre'] as String,
    capitulo: msg['capitulo'] as int,
    versiculos: (msg['versiculos'] as List).cast<String>(),
  );
}
```

---

## 7. GRPC SERVER — _handleGoToVerse

### 7.1 Lo que DEBERÍA hacer

```dart
Future<void> _handleGoToVerse({...}) async {
  // 1. Actualizar _bibleState
  _bibleState = _bibleState.copyWith(versionId, libroNumero, capitulo, versiculoNumero);
  
  // 2. Resolver contexto (prev/next verse)
  await _resolveAndCacheBibleContext();
  
  // 3. Sincronizar con providers del emisor
  _syncBibleStateToProviders();
  
  // 4. ENVIAR AL SUBPROCESS ← ESTO ES LO QUE FALTA O ESTÁ ROTO
  await _sendCurrentChapterToSubprocess();
}
```

### 7.2 _sendCurrentChapterToSubprocess() DEBE existir

```dart
Future<void> _sendCurrentChapterToSubprocess() async {
  if (_container == null) return;
  final repo = _container.read(bibliaRepositoryProvider);
  final libro = await repo.getLibroByNumero(_bibleState.versionId, _bibleState.libroNumero);
  if (libro == null) return;
  final cap = await repo.getCapitulo(libro.id, _bibleState.capitulo);
  if (cap == null) return;
  final versiculos = await repo.getVersiculosByCapitulo(cap.id);
  _container.read(windowServiceProvider).sendMessage({
    'type': 'LOAD_VERSE',
    'libroNombre': libro.nombre,
    'capitulo': _bibleState.capitulo,
    'versiculos': versiculos.map((v) => v.texto).toList(),
  });
}
```

---

## 8. PROBLEMAS CONOCIDOS

### 8.1 Proyección bíblica no funciona desde home
- **Síntoma**: Ventana se abre pero muestra "Esperando proyección..."
- **Posibles causas**:
  1. `_projectRandomVerse()` falla silenciosamente (verse es null, repo falla, etc.)
  2. `LOAD_VERSE` se envía pero el subprocess no lo recibe
  3. `_handleLoadVerse` no existe en projection_app.dart
  4. `loadBibleChapter` no crea los slides correctamente
  5. `receptorDisplayProvider` no detecta contenido bíblico

### 8.2 Proyección bíblica no funciona desde reader
- **Síntoma**: Mismo que home
- **Posibles causas**: Mismas que 8.1

### 8.3 Botón Enviar no funciona
- **Síntoma**: Dice "Enviando" pero no cambia la ventana receptora
- **Posibles causas**:
  1. `_handleGoToVerse` no llama a `_sendCurrentChapterToSubprocess()`
  2. `_sendCurrentChapterToSubprocess` no existe o falla
  3. El gRPC server no tiene acceso al `windowServiceProvider`

---

## 9. CHECKLIST DE DEBUG

Para la próxima sesión, verificar en este orden:

### Paso 1: Verificar que projection_app.dart tiene los handlers
```bash
grep -n "LOAD_VERSE" lib/presentation/views_projection/display/projection_app.dart
grep -n "_handleLoadVerse" lib/presentation/views_projection/display/projection_app.dart
```

### Paso 2: Verificar que _handleLoadVerse existe y funciona
- Leer projection_app.dart y confirmar que el handler existe
- Verificar que llama a `notifier.loadBibleChapter()` correctamente

### Paso 3: Verificar que receptorDisplayProvider detecta contenido bíblico
```bash
grep -A5 "receptorDisplayProvider" lib/presentation/views_projection/display/receptor_binding.dart
```
Debe verificar `liveState.module == ProjectionModule.bible` además de `liveState.hymn != null`

### Paso 4: Agregar logging para debug
En `_projectRandomVerse()` y `_projectCurrentChapter()`, agregar prints:
```dart
print('[DEBUG] _projectRandomVerse: verse=$verse');
print('[DEBUG] _projectRandomVerse: libro=$libro');
print('[DEBUG] _projectRandomVerse: versiculos=${versiculos.length}');
print('[DEBUG] Enviando LOAD_VERSE al subprocess');
```

### Paso 5: Verificar que el subprocess recibe el mensaje
En projection_app.dart, agregar print al inicio de `_handleMessage`:
```dart
void _handleMessage(String line) {
  print('[DEBUG] Subprocess recibió: $line');
  // ...
}
```

### Paso 6: Verificar gRPC server
En `_handleGoToVerse`, verificar que `_sendCurrentChapterToSubprocess()` se llama:
```dart
print('[DEBUG] _handleGoToVerse: enviando al subprocess');
```

---

## 10. DOCUMENTACIÓN EXISTENTE

| Archivo | Contenido |
|---|---|
| `CONTROL/ARQUITECTURA_PRESENTACION_HIMNARIO.md` | Arquitectura detallada del sistema de presentación del himnario (663 líneas) |
| `CONTROL/PENDIENTE.md` | Roadmap del proyecto |
| `CONTROL/INVESTIGACION_NUEVOS_MODULOS.md` | Investigación de 4 nuevos módulos (v1.1+) |
| `CONTROL/DOCUMENTO_MAESTRO_PRESENTACION.md` | ESTE ARCHIVO |

---

## 11. COMANDOS ÚTILES

```bash
# Correr tests
flutter test

# Analizar código
flutter analyze

# Correr app en Linux (para debug de proyección)
flutter run -d linux

# Ver logs del subprocess
# El subprocess se lanza con --projection, los prints van a la consola

# Ver estado del git
git log --oneline -20
git status
```

---

## 12. HISTORIAL DE COMMITS RELACIONADOS

```
34e208f fix(presentation): logica boton modulo + proyeccion desde home/reader biblico
fa3a358 fix(presentation): integra presentacion biblica completa en toda la app
4e46381 fix(presentation): integra PresentButton + PresentControlBar en HomeScreen
fd9dcd4 fix(android): signingConfig fallback a debug cuando no hay keystore en CI
cb3efaf ci: workflows build Android APK + Windows exe en push a mq-app-init
a8ff844 chore(db): actualizacion biblia.db con cambios del usuario
f88190c feat(presentation): Phase 5 — cambio de modulo + polish + tests finales
c306b1a feat(presentation): Phase 4 — control remoto gRPC biblico integrado
641bd81 feat(presentation): Phase 3 — controlador biblico con UI modular
a86f49e feat(presentation): Phase 2 — receptor biblico con renderizado de versiculos
6bb0d4b feat(presentation): Phase 1 — unified Bible+Hymnal core abstractions
```

---

## 13. INSTRUCCIONES PARA LA PRÓXIMA SESIÓN

1. **Leer este documento completo** para entender el contexto
2. **Leer `CONTROL/ARQUITECTURA_PRESENTACION_HIMNARIO.md`** para entender cómo funciona el himnario
3. **Seguir el checklist de debug (Sección 9)** en orden
4. **Agregar logging** para identificar dónde se rompe el flujo
5. **Correr `flutter run -d linux`** para probar la proyección local
6. **Verificar que los handlers existen** en projection_app.dart
7. **Verificar que el subprocess recibe los mensajes** con prints
8. **NO modificar código del himnario** — solo extender para biblia
9. **Mantener tests pasando** — 772/772 mínimo
10. **Commitear y pushear** después de cada fix funcional
