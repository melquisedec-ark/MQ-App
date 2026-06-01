> ⚠️ **DOCUMENTO HISTÓRICO** — Plan de delegación del 13 de mayo de 2026
> Las tareas aquí descritas (I4, I3, M6, M7, M2, M3) fueron ejecutadas.
> Ver `doc/tareas_pendientes.md` para estado actual.

# Plan de Delegación — HimnarioID 2.0

**Arquitecto:** @arqui
**Fecha:** 2026-05-13
**Estado:** Histórico — tareas ejecutadas

---

## A. Selección de tareas para esta sesión

| Tarea | Agente | Archivos principales | Esfuerzo estimado | Prioridad |
|-------|--------|---------------------|-------------------|-----------|
| **I4** — Getters para `_connectedHost`/`_connectedPort` | @dev | `lib/data/datasources/remote/grpc_control_datasource.dart` | ~10 min | 🔴 Alta |
| **I3** — Detección de plataforma en `app_initializer.dart` | @dev | `lib/bootstrap/app_initializer.dart` | ~30 min | 🔴 Alta |
| **M6** — Implementar `_removeChordAtLine` | @dev | `lib/presentation/app_controller/screens/arrangement_editor_screen.dart` | ~30 min | 🟡 Media |
| **M7** — Agregar categorías al seed data | @dev | `lib/core/database/database_helper.dart` | ~15 min | 🟡 Media |
| **M2** — UI: Standby dinámica | @design | `lib/presentation/app_display/screens/standby_screen.dart` | ~1h | 🟢 Normal |
| **M3** — UI: Animaciones de transición | @design | `lib/presentation/app_display/screens/live_projection_screen.dart` | ~1h | 🟢 Normal |

### Tareas diferidas para otro sprint

Las siguientes tareas son grandes (requieren múltiples archivos, nueva infraestructura o >2h de trabajo) y **no se abordarán en esta sesión**:

| Tarea | Razón | Sprint sugerido |
|-------|-------|-----------------|
| **I1** — Servidor gRPC (Display) | Requiere crear `bin/server.dart`, integración con proto, lógica de control de estrofas, testing E2E | Sprint 2 |
| **I2** — Control remoto funcional | Depende de I1 (servidor gRPC funcionando), añade estado compartido y comunicación bidireccional | Sprint 2 |
| **I5** — Conexión automática mDNS | Depende de I1+I2, requiere integración con `MdnsDiscovery` y reconnection logic | Sprint 3 |
| **A1** — Reproductor de audio | Depende de `audioplayers`, requiere `PistaAudio` datasource, UI de reproducción, tests | Sprint 3 |
| **A2** — Transposición con preview | Mejora UX sobre providers existentes, no crítica | Sprint 4 |
| **M1** — Tests unitarios (al menos 80% coverage) | Tarea transversal, requiere definir mocking strategy y CI | Sprint 2-3 |
| **M4** — Tema consistente (Material Design 3) | ~2h, se puede delegar a @design tras M2+M3 | Sprint 2 |
| **M5** — Documentación de API interna | Tarea de @documentador para cuando la API esté estable | Sprint 3 |

---

## B. Instrucciones detalladas para @dev

---

### Tarea I4 — Getters públicos para `_connectedHost`/`_connectedPort`

**Archivo**: `lib/data/datasources/remote/grpc_control_datasource.dart`
**Contexto**: La clase `GrpcControlDataSource` tiene campos privados `_connectedHost` (String?) y `_connectedPort` (int?) que se asignan en `connect()` y se limpian en `disconnect()`. Actualmente no hay forma de inspeccionar a qué host/port está conectada la instancia desde fuera (solo existe `isConnected`).

**Cambio**: Agregar dos getters públicos de solo lectura para exponer `_connectedHost` y `_connectedPort`.

**Código sugerido** — Insertar DESPUÉS de la línea 23 (`int? _connectedPort;`):

```dart
  /// Dirección IP del display al que se está conectado.
  String? get connectedHost => _connectedHost;

  /// Puerto del display al que se está conectado.
  int? get connectedPort => _connectedPort;
```

**Línea exacta**: Insertar entre la línea 23 y 24 (después de `int? _connectedPort;`, antes de `/// Indica si hay una conexión activa.`)

**Qué NO hacer**:
- No modificar `connect()` ni `disconnect()` — los getters solo leen los campos existentes
- No agregar setters — los campos deben seguir siendo privados
- No cambiar la visibilidad de `_connectedHost`/`_connectedPort`

**Verificación**:
1. `dart analyze lib/data/datasources/remote/grpc_control_datasource.dart` → 0 issues nuevos
2. Los getters deben aparecer en autocompletado de IDE al usar `GrpcControlDataSource`
3. No deben existir warnings de "unused getter" — se usarán cuando se implemente I5

---

### Tarea I3 — Detección de plataforma en `app_initializer.dart`

**Archivo**: `lib/bootstrap/app_initializer.dart`
**Contexto**: `_initPlatform()` en la línea 44-47 es un placeholder vacío con solo un log. Necesitamos detectar si la app se ejecuta en **web**, **desktop** (linux/windows/macos), o **mobile** (android/ios) y almacenar esa información para que el resto de la app pueda decidir comportamientos (ej: mostrar UI de display vs controlador).

**Cambio**: Implementar `_initPlatform()` para detectar la plataforma usando `dart:io` (Platform) y `dart:html`/`kIsWeb` de Flutter, y guardar el resultado como un enum accesible globalmente.

**Paso 1**: Crear el archivo `lib/core/enums/platform_type.dart`:

```dart
/// Tipo de plataforma donde se ejecuta la aplicación.
enum PlatformType {
  /// Web (navegador)
  web,
  /// Linux desktop
  linux,
  /// Windows desktop
  windows,
  /// macOS desktop
  macos,
  /// Android
  android,
  /// iOS
  ios,
  /// Desconocido
  unknown;

  /// `true` si es una plataforma desktop.
  bool get isDesktop => this == linux || this == windows || this == macos;

  /// `true` si es una plataforma mobile.
  bool get isMobile => this == android || this == ios;

  /// `true` si es web.
  bool get isWeb => this == web;
}
```

**Paso 2**: Crear el archivo `lib/core/constants/app_constants.dart`:

```dart
import '../enums/platform_type.dart';

/// Constantes globales de la aplicación.
/// Se inicializan en [AppInitializer.initialize] antes de runApp().
class AppConstants {
  AppConstants._();

  /// Tipo de plataforma detectada al inicio.
  /// No debe usarse antes de que [AppInitializer] haya completado.
  static PlatformType platformType = PlatformType.unknown;

  /// `true` si la plataforma es desktop.
  static bool get isDesktop => platformType.isDesktop;

  /// `true` si la plataforma es mobile.
  static bool get isMobile => platformType.isMobile;

  /// `true` si la plataforma es web.
  static bool get isWeb => platformType.isWeb;
}
```

**Paso 3**: Modificar `_initPlatform()` en `app_initializer.dart` (reemplazar líneas 44-47):

```dart
  /// Detecta la plataforma donde se ejecuta la aplicación.
  ///
  /// Usa [Platform] de dart:io en native y [kIsWeb] para detectar web.
  /// El resultado se almacena en [AppConstants.platformType] para acceso
  /// global sin necesidad de importar dart:io en cada archivo.
  static Future<void> _initPlatform() async {
    PlatformType detected;
    try {
      // dart:io solo está disponible en native (no web)
      if (Platform.isLinux) {
        detected = PlatformType.linux;
      } else if (Platform.isWindows) {
        detected = PlatformType.windows;
      } else if (Platform.isMacOS) {
        detected = PlatformType.macos;
      } else if (Platform.isAndroid) {
        detected = PlatformType.android;
      } else if (Platform.isIOS) {
        detected = PlatformType.ios;
      } else {
        detected = PlatformType.unknown;
      }
    } catch (_) {
      // Si Platform no está disponible, asumimos web
      detected = PlatformType.web;
    }

    AppConstants.platformType = detected;
    _log.info('Plataforma detectada: $detected');
  }
```

**Paso 4**: Agregar el import necesario en `app_initializer.dart`:

Agregar al inicio del archivo (después de la línea 1):
```dart
import 'dart:io' show Platform;
import '../core/constants/app_constants.dart';
import '../core/enums/platform_type.dart';
```

**Qué NO hacer**:
- No usar `dart:html` (deprecado) — usar `kIsWeb` de `foundation.dart` o el try-catch como se muestra
- No modificar `main.dart` ni `app.dart` — la inicialización ya se llama desde `main.dart`
- No agregar dependencias nuevas a `pubspec.yaml` — todo es de la SDK
- No cambiar la firma de `AppInitializer.initialize()` — debe seguir siendo `Future<void>`

**Verificación**:
1. `dart analyze lib/bootstrap/app_initializer.dart` → 0 issues
2. `dart analyze lib/core/enums/platform_type.dart` → 0 issues
3. `dart analyze lib/core/constants/app_constants.dart` → 0 issues
4. Verificar en tiempo de ejecución que `AppConstants.platformType` no sea `unknown` en desktop/mobile
5. Verificar que `AppConstants.isDesktop` retorne `true` en Linux al ejecutar `flutter run -d linux`

---

### Tarea M6 — Implementar `_removeChordAtLine` en el editor de arreglos

**Archivo**: `lib/presentation/app_controller/screens/arrangement_editor_screen.dart`
**Contexto**: El método `_removeChordAtLine()` en la línea 498-500 es un placeholder vacío (solo contiene un comentario). Este método se dispara desde el botón "Quitar" del selector musical (línea 463). Debe eliminar el **primer acorde** `[Acorde]` de la línea actualmente en edición.

**Cambio**: Implementar `_removeChordAtLine()` para que:
1. Tome la línea actual en edición (`_editingStanzaIndex`, `_editingLineIndex`)
2. Elimine el primer patrón `[Acorde]` que encuentre en esa línea usando la regex `RegExp(r'\[([A-G][#b]?[A-Ga-g0-9]*)\]')`
3. Actualice `_editedStanzas` con el nuevo contenido
4. Use `setState` para reflejar el cambio en la UI

**Código sugerido** — Reemplazar líneas 497-500:

```dart
  /// Elimina el primer acorde de la línea en edición.
  void _removeChordAtLine() {
    if (_editingStanzaIndex < 0 || _editingLineIndex < 0) return;

    final stanzasAsync = ref.read(stanzasProvider(widget.himno.id));
    stanzasAsync.whenData((estrofas) {
      if (_editingStanzaIndex >= estrofas.length) return;
      final estrofa = estrofas[_editingStanzaIndex];

      // Obtener el contenido (editado u original)
      final key = '${estrofa.id}_content';
      final content = _editedStanzas[key] ?? estrofa.contenido;
      final lines = content.split('\n');

      if (_editingLineIndex >= lines.length) return;
      final line = lines[_editingLineIndex];

      // Eliminar el primer acorde [Acorde] de la línea
      final chordRegex = RegExp(r'\[([A-G][#b]?[A-Ga-g0-9]*)\]');
      final newLine = line.replaceFirst(chordRegex, '').trim();

      lines[_editingLineIndex] = newLine;
      final newContent = lines.join('\n');

      setState(() {
        _editedStanzas[key] = newContent;
      });
    });
  }
```

**Qué NO hacer**:
- No modificar `_insertChordAtLine` — ya funciona correctamente
- No modificar `_buildChordSelector` — el botón "Quitar" ya está conectado
- No agregar imports nuevos — la regex ya está definida en `_buildChordProLine` (línea 281)
- No usar `ref.read` inline fuera del closure cuando haya mounts pendientes — el código usa `ref.read` antes del `whenData` que es seguro
- No olvidar el `.trim()` después de `replaceFirst` para eliminar espacios residuales

**Verificación**:
1. `dart analyze lib/presentation/app_controller/screens/arrangement_editor_screen.dart` → 0 issues nuevos
2. Abrir el editor de arreglos, seleccionar una estrofa, tocar una línea, presionar "Quitar" → el primer acorde de esa línea debe desaparecer
3. Si la línea no tiene acordes, el botón "Quitar" debe ser no-op (no crash)
4. Confirmar que los cambios persisten al guardar el arreglo

---

### Tarea M7 — Agregar categorías al seed data

**Archivo**: `lib/core/database/database_helper.dart`
**Contexto**: Actualmente la tabla `Categoria` se crea en el schema pero nunca se insertan datos de semilla. Los himnos de ejemplo no tienen categorías asignadas. Esto hace que `Himno.categoria` siempre retorne cadena vacía. Hay que insertar categorías reales y asignarlas a los himnos de ejemplo.

**Cambio**: Al final del método `_seedData(Database db)` (después de la línea 328, el último `}` de `_seedData`), agregar:

1. Inserción de categorías predefinidas
2. Asignación de categorías a los himnos de seed via `Himno_Categoria`
3. Cargar las categorías en los modelos correspondientes

**Código sugerido** — Al final de `_seedData`, ANTES del cierre `}` de la función (línea 329), agregar:

```dart
    // ─── CATEGORÍAS ──────────────────────────────────────────
    final categorias = [
      'Adoración',
      'Alabanza',
      'Fe',
      'Esperanza',
      'Amor de Dios',
      'Santidad',
      'Redención',
      'Creación',
      'Oración',
      'Consagración',
      'Navidad',
      'Semana Santa',
      'Resurrección',
      'Espíritu Santo',
      'Comunión',
    ];

    final categoriaIds = <int, int>{};
    for (final (index, nombre) in categorias.indexed) {
      final id = await db.insert('Categoria', {
        'id': index + 1,
        'nombre': nombre,
      });
      categoriaIds[nombre] = id;
    }

    // ─── ASIGNAR CATEGORÍAS A HIMNOS ─────────────────────────
    // Himno 1: Santo, Santo, Santo → Adoración, Santidad
    await db.insert('Himno_Categoria', {
      'himno_id': 1,
      'categoria_id': categoriaIds['Adoración']!,
    });
    await db.insert('Himno_Categoria', {
      'himno_id': 1,
      'categoria_id': categoriaIds['Santidad']!,
    });

    // Himno 2: Cuán grande es Dios → Alabanza, Creación
    await db.insert('Himno_Categoria', {
      'himno_id': 2,
      'categoria_id': categoriaIds['Alabanza']!,
    });
    await db.insert('Himno_Categoria', {
      'himno_id': 2,
      'categoria_id': categoriaIds['Creación']!,
    });

    // Himno 3: Grande es tu fidelidad → Fe, Amor de Dios
    await db.insert('Himno_Categoria', {
      'himno_id': 3,
      'categoria_id': categoriaIds['Fe']!,
    });
    await db.insert('Himno_Categoria', {
      'himno_id': 3,
      'categoria_id': categoriaIds['Amor de Dios']!,
    });
```

**Qué NO hacer**:
- No modificar `_onCreate` — los datos de semilla van en `_seedData`
- No modificar `_ensureSeedData` — ya llama a `_seedData`
- No borrar las categorías existentes si la BD ya fue creada (es seguro porque `_seedData` solo se ejecuta si la tabla Himno está vacía)
- No usar valores fijos para IDs de categoría (usar el mapa dinámico)

**Verificación**:
1. `dart analyze lib/core/database/database_helper.dart` → 0 issues nuevos
2. Tras borrar la BD y reiniciar la app, `HymnCard` debe mostrar categorías como "Adoración", "Alabanza", etc.
3. La función `getCategories()` debe retornar 15 categorías
4. Himno 1 debe tener categorías "Adoración" y "Santidad"

---

## C. Instrucciones detalladas para @design

---

### Tarea M2 — UI: Standby dinámica

**Archivo**: `lib/presentation/app_display/screens/standby_screen.dart`
**Contexto**: La pantalla de standby actual es estática. Muestra un logo, un mensaje y un `LinearProgressIndicator` sin variación. Se necesita que la pantalla tenga un comportamiento visual más dinámico y profesional, acorde con Material Design 3, idealmente con elementos animados sutiles.

**Cambio**: Rediseñar `StandbyScreen` para que incluya:

1. **Animación de pulso** en el icono de nota musical (escala 1.0 → 1.1 → 1.0 infinito)
2. **Animación de rotación** sutil en un decorativo (opcional) o un gradiente animado de fondo
3. **Reemplazar `LinearProgressIndicator`** por un patrón de ondas (wave) animadas o dots pulsantes
4. **Usar `colorScheme` y `textTheme` del tema** en lugar de colores hardcodeados (respetando el fondo oscuro para proyección)
5. **Widgets `const`** donde sea posible

**Principios de diseño a seguir**:
- Usar `colorScheme.onSurface`, `colorScheme.primary`, etc. del tema en vez de `Colors.white` hardcodeado
- Mantener fondo predominantemente oscuro (la pantalla es para proyección en TV/PC)
- Programación funcional: preferir `AnimatedBuilder` sobre `StatefulWidget` si es simple
- Si se necesita `StatefulWidget`, usar `AnimationController` con `SingleTickerProviderStateMixin`
- No agregar dependencias nuevas; usar solo `package:flutter/material.dart`

**Código sugerido** (estructura base — @design puede refinar la creatividad visual):

```dart
import 'package:flutter/material.dart';

/// Pantalla de Standby (Espera) para Display
/// Se muestra cuando no hay conexión con el controlador
class StandbyScreen extends StatefulWidget {
  final String? networkName;

  const StandbyScreen({
    super.key,
    this.networkName,
  });

  @override
  State<StandbyScreen> createState() => _StandbyScreenState();
}

class _StandbyScreenState extends State<StandbyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  
  // Segundo controlador para dots animados
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Fondo del tema oscuro
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono animado con pulso
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              ),
              child: Icon(
                Icons.music_note_rounded,
                size: 120,
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 48),

            // Título principal
            Text(
              'HimnarioID',
              style: textTheme.displayLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w300,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),

            // Subtítulo
            Text(
              'Esperando conexión del controlador...',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 48),

            // Indicador de carga con dots animados
            _AnimatedDots(
              controller: _dotsController,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 48),

            // Información de red
            if (widget.networkName != null) ...[
              Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                indent: 80,
                endIndent: 80,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Red: ${widget.networkName}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget de dots animados como indicador de carga.
class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _AnimatedDots({
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = ((controller.value + delay) % 1.0);
            final opacity = value < 0.5 ? value * 2 : (1.0 - value) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
```

**Verificación**:
1. `dart analyze lib/presentation/app_display/screens/standby_screen.dart` → 0 issues nuevos
2. La pantalla en `flutter run -d linux` (o cualquier desktop) debe mostrar:
   - Icono de nota musical con pulso suave (escala 1.0↔1.15)
   - Tres dots animados (opacity cíclica) en lugar de barra de progreso
   - Texto que usa colores del tema (no blanco puro hardcodeado)
3. No debe tener warnings de `prefer_const_constructors`

---

### Tarea M3 — UI: Animaciones de transición

**Archivo**: `lib/presentation/app_display/screens/live_projection_screen.dart`
**Contexto**: `LiveProjectionScreen` ya tiene una animación de fade básica cuando cambia la estrofa. Sin embargo, es una animación simple. Se necesita mejorar la experiencia visual con una transición más rica usando Material Design 3 motion guidelines.

**Cambio**: Mejorar las animaciones de transición entre estrofas:

1. **Mantener el fade existente** pero combinarlo con un **slide vertical** (la estrofa nueva sube desde abajo mientras la vieja se desvanece)
2. **Soporte para `transitionSpeed`**: usar una propiedad `transitionSpeed` (double 0.0-1.0) para controlar la duración de la animación (actualmente hardcodeada a 800ms)
3. **Mejora en blackout**: animar la transición a negro en vez de instantánea
4. **Usar `colorScheme` y `textTheme` del tema** en lugar de colores hardcodeados

**Código sugerido** — Reemplazar el archivo completo con esta versión mejorada:

```dart
import 'package:flutter/material.dart';

/// Pantalla de Proyección en Vivo (Live Projection)
/// Muestra el himno actual con transiciones suaves entre estrofas
class LiveProjectionScreen extends StatefulWidget {
  final String himnoTitulo;
  final String himnoNumero;
  final String estrofaActual;
  final bool isVisible;
  final Color? backgroundColor;
  final double fontSize;
  final double transitionSpeed; // 0.0 (lento) a 1.0 (rápido)

  const LiveProjectionScreen({
    super.key,
    required this.himnoTitulo,
    required this.himnoNumero,
    required this.estrofaActual,
    this.isVisible = true,
    this.backgroundColor,
    this.fontSize = 36,
    this.transitionSpeed = 0.5,
  });

  @override
  State<LiveProjectionScreen> createState() => _LiveProjectionScreenState();
}

class _LiveProjectionScreenState extends State<LiveProjectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Duración calculada: 0.0→1200ms, 1.0→200ms
  Duration get _transitionDuration => Duration(
    milliseconds: 1200 - (widget.transitionSpeed * 1000).round(),
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: _transitionDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(LiveProjectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambia la estrofa o la visibilidad, reiniciar animación
    final stanzaChanged = oldWidget.estrofaActual != widget.estrofaActual;
    final visibilityChanged = oldWidget.isVisible != widget.isVisible;

    if (stanzaChanged || visibilityChanged) {
      _controller.duration = _transitionDuration;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bgColor = widget.backgroundColor ?? colorScheme.surface;

    // Blackout animado
    if (!widget.isVisible) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Si está en blackout y la animación no ha comenzado, negro directo
          final isFullyBlack = !widget.isVisible && _controller.isCompleted;
          return Container(
            color: isFullyBlack
                ? Colors.black
                : Color.lerp(bgColor, Colors.black, _controller.value),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 80,
              vertical: 60,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Número del himno
                Text(
                  '#${widget.himnoNumero}',
                  style: textTheme.displayLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                    fontWeight: FontWeight.bold,
                    fontSize: widget.fontSize * 0.6,
                  ),
                ),
                const SizedBox(height: 16),

                // Título del himno
                Text(
                  widget.himnoTitulo,
                  style: textTheme.displayLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontSize: widget.fontSize * 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Divisor decorativo
                Container(
                  width: 200,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        colorScheme.primary.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Contenido de la estrofa
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.estrofaActual,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize: widget.fontSize,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Principios de diseño a seguir**:
- Usar `colorScheme.onSurface` en vez de `Colors.white` 
- Usar `colorScheme.surface` en vez de `Colors.black` para fondo
- Mantener `transitionSpeed` configurable desde el provider
- Curva `Curves.easeOutCubic` para una sensación más natural que `easeInOut`
- Widgets `const` donde sea posible

**Verificación**:
1. `dart analyze lib/presentation/app_display/screens/live_projection_screen.dart` → 0 issues nuevos
2. Al cambiar de estrofa, la nueva estrofa debe aparecer con un fade + slide-up (8% de la altura)
3. La duración debe responder al valor `transitionSpeed` (0.0 ≈ 1.2s, 1.0 ≈ 0.2s)
4. El blackout debe ser animado (transición de color al negro, no instantáneo)

---

## D. Criterios de aceptación

Para que @arqui considere una tarea COMPLETA, debe cumplir TODAS estas condiciones:

### Criterios globales (aplican a toda tarea)
- [ ] `dart analyze lib/` no debe introducir NINGÚN error nuevo
- [ ] `dart analyze lib/` no debe introducir NINGÚN warning nuevo (mantener máximo 2 existentes)
- [ ] Los widgets deben usar constructores `const` donde sea posible
- [ ] No se deben agregar dependencias nuevas a `pubspec.yaml`
- [ ] El código debe seguir los principios de programación funcional (inmutabilidad, evitar setState innecesario)

### I4 — Getters connectedHost/connectedPort
- [ ] Getters públicos `connectedHost` y `connectedPort` existen y retornan los valores correctos
- [ ] No hay setters públicos
- [ ] El código compila sin errores

### I3 — Detección de plataforma
- [ ] `PlatformType` enum existe en `lib/core/enums/platform_type.dart`
- [ ] `AppConstants` existe en `lib/core/constants/app_constants.dart`
- [ ] `_initPlatform()` detecta correctamente Linux, Windows, macOS, Android, iOS y web
- [ ] `AppConstants.isDesktop` retorna true en Linux
- [ ] No se usa `dart:html`

### M6 — _removeChordAtLine
- [ ] El método elimina el primer acorde de la línea seleccionada
- [ ] No crashea si la línea no tiene acordes
- [ ] Los cambios se reflejan en `_editedStanzas`
- [ ] El botón "Quitar" en la UI funciona correctamente

### M7 — Categorías en seed data
- [ ] 15 categorías se insertan en la tabla `Categoria`
- [ ] Los 3 himnos tienen asignaciones en `Himno_Categoria`
- [ ] `HymnCard` muestra la categoría correctamente
- [ ] `getCategories()` retorna 15 categorías

### M2 — Standby dinámica
- [ ] Icono de nota musical tiene animación de pulso
- [ ] `LinearProgressIndicator` reemplazado por dots animados o wave
- [ ] Usa `colorScheme` y `textTheme` del tema (mínimo: no `Colors.white` hardcodeado)
- [ ] Animaciones no consumen CPU cuando la ventana no es visible (usar `AutoDispose` si aplica)
- [ ] Sin errores de análisis estático

### M3 — Animaciones de transición
- [ ] Transición combina fade + slide vertical
- [ ] Duración configurable via `transitionSpeed`
- [ ] Blackout animado (no instantáneo)
- [ ] Usa `colorScheme` y `textTheme` del tema
- [ ] Sin errores de análisis estático

---

*Documento generado por @arqui. Las tareas diferidas están documentadas en `doc/TAREAS_DIFERIDAS.md` para planificación del próximo sprint.*
