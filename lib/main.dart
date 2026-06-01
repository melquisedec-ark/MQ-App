import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'bootstrap/app_container.dart';
import 'bootstrap/app_initializer.dart';
import 'core/database/db_version_manager.dart';
import 'core/theme/app_theme.dart';
import 'presentation/views_projection/display/projection_app.dart';
import 'presentation/widgets/db_update_screen.dart';

/// Punto de entrada principal de HimnarioID 2.0.
///
/// ## Multi-ventana (Bug 3)
/// Cuando se lanza con el argumento `--projection`, la aplicación inicia
/// como una ventana de proyección secundaria (ver [ProjectionApp]).
/// Esto permite que el usuario tenga una ventana de control y una ventana
/// de proyección separadas en el escritorio.
///
/// ## DB Auto-Update
/// Antes de lanzar la app principal, se verifica si la base de datos
/// pre-cargada en assets necesita actualización (comparando versiones
/// mediante [DbVersionManager]). Si es necesario, se muestra [DbUpdateScreen]
/// que realiza la copia e inicialización, y luego transiciona a la app
/// principal automáticamente.
///
/// ### Flujo de decisión
/// ```
/// main()
///   ├─ ¿modo proyección? → ProjectionApp
///   └─ modo principal:
///       ├─ Leer assetVersion (db_version.json)
///       ├─ Leer localVersion (db_version_applied.txt)
///       ├─ ¿assetVersion > localVersion?
///       │   ├─ Sí → runApp(DbUpdateScreen) — copia BD con feedback visual
///       │   └─ No → AppInitializer.initialize() + runApp(HimnarioApp)
/// ```
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Modo Proyección: segunda ventana ──
  if (args.contains('--projection')) {
    await _startProjectionWindow();
    return;
  }

  // ── Modo Principal ──
  await _startMainApp();
}

/// Inicia la ventana de proyección secundaria (subproceso).
///
/// Este modo se usa cuando la app se lanza con el argumento `--projection`
/// desde [desktop_multi_window]. Se comunica con la ventana principal
/// vía stdin/stdout (protocolo JSON).
Future<void> _startProjectionWindow() async {
  final container = ProviderContainer();
  AppContainer().init(container);
  await windowManager.ensureInitialized();
  // El subproceso NO necesita servidor gRPC (se comunica por stdin/stdout)
  await AppInitializer.initialize(container: container, skipNetwork: true);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ProjectionApp(),
    ),
  );
}

/// Inicia la ventana principal de la aplicación.
///
/// 1. Inicializa window_manager (solo desktop).
/// 2. Verifica si la BD necesita actualización (comparación rápida de
///    versiones sin abrir la BD).
/// 3. Si necesita actualización:
///    - Muestra [DbUpdateScreen] con feedback visual inmediato.
///    - La pantalla ejecuta la copia de BD e inicialización completa.
///    - Al terminar, transiciona automáticamente a [HimnarioApp].
/// 4. Si NO necesita actualización:
///    - Inicializa todos los servicios (incluyendo BD, mDNS, gRPC).
///    - Lanza [HimnarioApp] directamente.
Future<void> _startMainApp() async {
  // ── Inicializar window_manager para desktop ──
  if (!kIsWeb) {
    try {
      await windowManager.ensureInitialized();
    } catch (_) {
      // window_manager no está disponible en esta plataforma
    }
  }

  // ── Crear contenedor Riverpod ──
  final container = ProviderContainer();
  AppContainer().init(container);

  // ── Verificar si la BD necesita actualización ──
  // Lectura rápida de versiones sin abrir la BD
  final needsUpdate = await _quickCheckDbUpdate();

  // Crear MaterialApp compartido para evitar anidamiento de navegadores.
  // DbUpdateScreen y HimnarioApp comparten el mismo tema y navigator.
  final appTheme = AppTheme.lightTheme;
  final darkTheme = AppTheme.darkTheme;

  if (needsUpdate) {
    // Mostrar pantalla de actualización con feedback visual.
    // DbUpdateScreen ejecuta AppInitializer.initialize() internamente
    // y transiciona a HimnarioApp al completar (vía runApp).
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          title: 'MQ App',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: DbUpdateScreen(container: container),
        ),
      ),
    );
  } else {
    // Inicialización normal: BD, mDNS, servidor gRPC, etc.
    await AppInitializer.initialize(container: container);

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          title: 'MQ App',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: const HimnarioApp(),
        ),
      ),
    );
  }
}

/// Verificación rápida de si la BD necesita actualización.
///
/// Lee la versión del asset (`db_version.json`) y la versión aplicada
/// localmente (`db_version_applied.txt`). Si la del asset es mayor,
/// retorna `true`.
///
/// Este método NO abre la base de datos SQLite — solo lee archivos
/// pequeños, por lo que es adecuado para llamarse antes de `runApp()`.
Future<bool> _quickCheckDbUpdate() async {
  try {
    final assetVersion = await DbVersionManager.readAssetVersion();
    if (assetVersion <= 0) return false;

    final dir = await getApplicationDocumentsDirectory();
    final localVersion = await DbVersionManager.readLocalVersion(dir.path);

    return DbVersionManager.needsUpdate(assetVersion, localVersion);
  } catch (_) {
    // Si falla (ej: entorno de test sin path_provider), asumir
    // que NO necesita actualización para no bloquear al usuario.
    return false;
  }
}
