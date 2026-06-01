> ⚠️ **DOCUMENTO HISTÓRICO** — Fase 4 (mayo 2026)
> Las tareas descritas aquí fueron ejecutadas. El estado actual del proyecto
> incluye las mejoras de SET_CONFIG (showChords), proyección con scroll,
> y reflow de acordes. Ver `doc/CONTEXTO_PROYECTO.md` para estado actual.
> Fecha de archivo: 20 de mayo de 2026

# Fase 4: Probar `SubprocessWindowService` en Linux

> ⚠️ **LEE TODO EL DOCUMENTO** antes de comenzar. Hay diagnóstico crítico en la Sección 1.

---

## 1. Diagnóstico Técnico (IMPORTANTE — leer primero)

### 1.1 ¿Cuál WindowService se usa en Linux?

**`SubprocessWindowService`**. Decisión en `window_providers.dart:23-24`:
```dart
if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  return SubprocessWindowService();
}
```

### 1.2 ¿SubprocessWindowService está implementado o es stub?

**Completamente implementado**. Todos los métodos son reales:

| Método | Estado | Código |
|--------|--------|--------|
| `openProjectionWindow()` | ✅ `Process.start(Platform.resolvedExecutable, ['--projection'])` + stdout listener |
| `sendMessage()` | ✅ `stdin.write(jsonEncode(m) + '\n')` |
| `closeProjectionWindow()` | ✅ `process.kill()` |
| `onWindowEvent` | ✅ broadcast StreamController |

### 1.3 ¿ProjectionApp existe y funciona?

**Sí**. `lib/presentation/views_projection/display/projection_app.dart`:
- Escucha stdin como JSON lines
- Maneja: LOAD_HYMN, NEXT_STANZA, PREV_STANZA, GO_TO_STANZA, BLACKOUT
- SET_CONFIG existe como case pero tiene body vacío (bug menor)
- Renderiza LiveProjectionScreen cuando hay himno cargado

### 1.4 Riesgos identificados

| # | Riesgo | Severidad | Detalle |
|---|--------|-----------|---------|
| R1 | **Puerto gRPC 50051 ocupado** | 🔴 | Padre e hijo intentan iniciar GrpcDisplayServer en mismo puerto |
| R2 | **Concurrencia SQLite** | 🟡 | Dos procesos abriendo la misma DB |
| R3 | **Asset loading** | 🟡 | En debug los assets los sirve el Flutter tool; el subproceso no tiene acceso |
| R4 | **Sin tests** | 🔴 | Cero tests para SubprocessWindowService |
| R5 | **SET_CONFIG vacío** | 🟢 | Case existe pero no hace nada |

### 1.5 Debug vs Release

| Aspecto | `flutter run` | Binary compilado |
|---------|--------------|------------------|
| Assets | Servidor HTTP del Flutter tool | Bundled en el binary |
| Lock file | ❌ Puede fallar | ✅ No aplica |
| **Recomendación** | ❌ No usar | ✅ Usar `flutter build linux --debug` |

---

## 2. Plan de Tareas

### Tarea F4.1: Test unitario de `SubprocessWindowService`

| Campo | Valor |
|-------|-------|
| **Archivos** | Crear `test/unit/core/window_manager/subprocess_window_service_test.dart` |
| **Tiempo** | 2h |
| **Prioridad** | 🔴 P0 |

#### Qué hacer

Crear tests que cubran:

1. `openProjectionWindow()` con éxito — mockear `Process.start`, verificar evento `opened`
2. `openProjectionWindow()` cuando ya hay ventana abierta — segunda llamada debe ser NO-OP
3. `openProjectionWindow()` cuando falla `Process.start` — verificar que relanza excepción
4. `sendMessage()` con ventana abierta — verificar JSON + `\n` en stdin
5. `sendMessage()` sin ventana abierta — NO-OP sin errores
6. `closeProjectionWindow()` con ventana abierta — verificar `process.kill()` + evento `closed`
7. `closeProjectionWindow()` sin ventana abierta — NO-OP
8. `onWindowEvent` stream — verificar eventos opened/closed
9. stdout del hijo — simular JSON en stdout, verificar `onChildMessage`
10. Salida del hijo — simular `exitCode`, verificar evento `closed`

#### Código base sugerido para mock

```dart
class MockProcess extends Mock implements Process {
  final stdinController = StreamController<List<int>>();
  final stdoutController = StreamController<List<int>>();
  final stderrController = StreamController<List<int>>();
  final _stdinSink = MockIOSink();

  @override
  IOSink get stdin => _stdinSink;

  @override
  Stream<List<int>> get stdout => stdoutController.stream;

  @override
  Stream<List<int>> get stderr => stderrController.stream;
}

class MockIOSink extends Mock implements IOSink {}
```

```dart
// En el test, mockear Process.start como top-level function.
// Usar un wrapper o la función directamente:
final mockProcess = MockProcess();

// Usar zone o fake para interceptar Process.start
// Alternativa: extraer Process.start a un método protegido
```

#### Verificación

```bash
flutter test test/unit/core/window_manager/subprocess_window_service_test.dart
```

---

### Tarea F4.2: Test widget de `ProjectionApp`

| Campo | Valor |
|-------|-------|
| **Archivos** | Crear `test/widget/projection_app_test.dart` |
| **Tiempo** | 3h |
| **Prioridad** | 🔴 P0 |

#### Qué hacer

Tests widget para `ProjectionApp`:

1. **Estado inicial** — "Esperando proyección..."
2. **LOAD_HYMN** — escribir JSON por stdin, verificar que muestra el himno
3. **NEXT_STANZA** — cargar himno con 3 estrofas, enviar NEXT, verificar cambio
4. **PREV_STANZA** — avanzar 2, retroceder 1, verificar contenido correcto
5. **GO_TO_STANZA** — ir a índice específico
6. **BLACKOUT true/false** — verificar pantalla negra / restauración
7. **Mensaje mal formado** — texto no-JSON no debe crashear
8. **LOAD_HYMN con estrofas vacías** — debe manejarse sin error

#### Cómo mockear stdin

**Opción A (recomendada)**: Modificar `ProjectionApp` para aceptar un `Stream<String>` opcional:

```dart
class ProjectionApp extends ConsumerStatefulWidget {
  final Stream<String>? stdinOverride;
  const ProjectionApp({super.key, this.stdinOverride});
```

En `_setupStdinListener`:
```dart
final source = widget.stdinOverride ?? stdin.transform(utf8.decoder).transform(const LineSplitter());
```

**Opción B**: Usar `zone` de Dart para reemplazar stdin.

#### Verificación

```bash
flutter test test/widget/projection_app_test.dart
```

---

### Tarea F4.3: Aislar subproceso del servidor gRPC

| Campo | Valor |
|-------|-------|
| **Archivos** | `lib/main.dart`, `lib/bootstrap/app_initializer.dart` |
| **Tiempo** | 30min |
| **Prioridad** | 🔴 P0 |

#### Qué hacer

El subproceso con `--projection` no necesita servidor gRPC (se comunica por stdin). Modificar:

**`lib/bootstrap/app_initializer.dart`**:
```dart
static Future<void> initialize(
  [ProviderContainer? container, {
  bool skipNetwork = false,
}]) async {
  // ... DB, platform ...
  if (!skipNetwork) {
    await _initNetworkServices(container);
  }
}
```

**`lib/main.dart`**:
```dart
if (args.contains('--projection')) {
  final container = ProviderContainer();
  AppContainer().init(container);
  await AppInitializer.initialize(container, skipNetwork: true); // ← cambio
  // ...
}
```

#### Verificación

```bash
# Compilar y ejecutar; verificar que NO hay log "Servidor gRPC iniciado" en el subproceso
./build/linux/debug/*/himnario_id_2 --projection 2>&1 | grep -i "gRPC\|servidor\|server"
# → No debe mostrar nada
```

---

### Tarea F4.4: Verificar Linux runner pasa `--projection`

| Campo | Valor |
|-------|-------|
| **Archivos** | `linux/my_application.cc` (revisar) o `linux/runner/main.cc` |
| **Tiempo** | 30min |
| **Prioridad** | 🟡 P1 |

#### Qué hacer

Buscar en el código C++ del runner de Linux si filtra argumentos:

```bash
grep -rn "argv\|argc\|fl_arguments\|GetArguments\|args" linux/ --include="*.cc" --include="*.cpp" --include="*.c"
```

Si el runner filtra args desconocidos, agregar `--projection` a los permitidos.

Si no hay filtro (lo más probable), la tarea se completa con solo verificarlo.

#### Verificación

Agregar temporalmente en `main.dart`:
```dart
debugPrint('ARGS RECEIVED: $args');
```
Ejecutar el binary con `--projection` y verificar que aparece.

---

### Tarea F4.5: Prueba manual del flujo completo en Linux

| Campo | Valor |
|-------|-------|
| **Tiempo** | 2h |
| **Prioridad** | 🔴 P0 |

#### Qué hacer

1. Compilar:
```bash
flutter build linux --debug
```

2. Ejecutar el binary (NO `flutter run`):
```bash
./build/linux/debug/<bundle>/himnario_id_2
```

3. Probar secuencia:
   - [ ] App principal inicia sin errores
   - [ ] Presionar "Presentar" (FAB)
   - [ ] Aparece la ventana secundaria con "Esperando proyección..."
   - [ ] Seleccionar un himno
   - [ ] La ventana secundaria muestra título + estrofas
   - [ ] Navegar estrofas (prev/next) → el contenido cambia
   - [ ] Presionar "Detener" → la ventana secundaria se cierra
   - [ ] Repetir ciclo 3 veces sin crasheos

#### Si algo falla

| Síntoma | Causa probable | Debug |
|---------|---------------|-------|
| Ventana secundaria se abre y cierra | Crash en ProjectionApp | `./build/.../himnario_id_2 --projection 2>&1` para ver stderr |
| Pantalla negra sin texto | Assets no encontrados | Verificar `Directory.current` |
| No aparece ventana | Process.start falla | Agregar try-catch con print en `openProjectionWindow()` |
| DB error | Concurrencia SQLite | Verificar WAL mode en DatabaseHelper |
| JSON no se recibe | Encoding issue | Verificar que `\n` termina cada mensaje |

---

### Tarea F4.6: Test de integración del flujo WindowService (opcional)

| Campo | Valor |
|-------|-------|
| **Archivos** | Crear `test/integration/window_service_flow_test.dart` |
| **Tiempo** | 2h |
| **Prioridad** | 🟡 P1 |

#### Qué hacer

Si la Tarea F4.5 descubre bugs, crear tests de integración que aíslen el flujo:

1. Crear un `FakeWindowService` (implementa `WindowService` con StreamControllers)
2. Verificar que `projectHymn()` construye el mensaje correcto y lo envía
3. Verificar que `present_control_bar.dart` envía `NEXT_STANZA`/`PREV_STANZA` correctamente

---

### ✅ Tarea F4.7: SET_CONFIG implementado

| Campo | Valor |
|-------|-------|
| **Archivos** | `projection_app.dart`, `live_control_providers.dart` |
| **Tiempo** | 30min |
| **Prioridad** | 🟢 P2 (opcional) |

#### Qué se hizo

SET_CONFIG se implementó y expandió: ahora soporta `showChords` junto con `fontSize`, `backgroundColor`, `transitionSpeed`, etc. El toggle global de acordes (`showChords`) se sincroniza vía IPC desde `control_sheets.dart` hasta `projection_app.dart`.

> **Actualización (19 mayo 2026):** SET_CONFIG ahora soporta `showChords` para el toggle global de acordes. Ver `feature/acordes-toggle-global`.

---

## 3. Orden de Ejecución Recomendado

```
Día 1:
  1. F4.3 — Aislar subproceso de red (30min) ← HACER PRIMERO, desbloquea todo
  2. F4.4 — Verificar Linux runner (30min)
  3. F4.1 — Tests unitarios SubprocessWindowService (2h)
  4. F4.2 — Tests widget ProjectionApp (3h)

Día 2:
  5. F4.5 — Prueba manual en Linux (2h) ← DESCUBRE BUGS REALES
  6. F4.6 — Tests integración según bugs encontrados (2h, condicional)
  7. F4.7 — SET_CONFIG si sobra tiempo (30min)

Validación final:
  - dart analyze lib/ → 0 errors, 0 warnings
  - flutter test → no introduce nuevas fallas
  - Prueba manual completa (CA5-CA8)
```

---

## 4. Criterios de Aceptación

| # | Criterio | Verificación |
|---|----------|-------------|
| CA1 | `dart analyze lib/` → 0 errors, 0 warnings | `dart analyze lib/` |
| CA2 | Tests de SubprocessWindowService pasan | `flutter test test/unit/core/window_manager/subprocess_window_service_test.dart` |
| CA3 | Tests de ProjectionApp pasan | `flutter test test/widget/projection_app_test.dart` |
| CA4 | `flutter test` no introduce nuevas fallas | Comparar con los 7 failures pre-existentes |
| CA5 | Se puede abrir ventana de proyección en Linux | Prueba manual |
| CA6 | Al presionar Presentar + himno, la proyección muestra el himno | Prueba manual |
| CA7 | Navegación entre estrofas funciona en la proyección | Prueba manual |
| CA8 | Cerrar presentación cierra la ventana secundaria | Prueba manual |

---

## 5. Referencias

- `lib/core/window_manager/window_service.dart` — Interfaz + todas las impl
- `lib/core/window_manager/window_providers.dart` — Provider que selecciona impl
- `lib/core/window_manager/window_state.dart` — WindowEvent y WindowEventType
- `lib/main.dart` — Entry point con detección `--projection`
- `lib/presentation/views_projection/display/projection_app.dart` — App del subproceso
- `lib/presentation/views_projection/display/live_projection_screen.dart` — UI de proyección
- `lib/presentation/views_projection/providers/projection_actions.dart` — projectHymn()
- `lib/presentation/views_projection/providers/live_control_providers.dart` — LiveControlNotifier
- `lib/presentation/views_projection/controller/present_control_bar.dart` — Uso de sendMessage
- `lib/presentation/views_personal/dashboard/present_button.dart` — Uso de open/close window
- `lib/bootstrap/app_initializer.dart` — Inicialización de red
