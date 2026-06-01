import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, Platform, Process, ProcessStartMode;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'window_state.dart';

/// Servicio abstracto para gestión de ventanas de proyección.
///
/// Define el contrato para abrir, cerrar y escuchar eventos
/// de la ventana secundaria de proyección.
abstract class WindowService {
  /// Abre una ventana de proyección con los argumentos dados.
  Future<void> openProjectionWindow(Map<String, dynamic> args);

  /// Cierra la ventana de proyección actual.
  Future<void> closeProjectionWindow();

  /// Envía un mensaje JSON a la ventana de proyección.
  ///
  /// El mensaje se serializa como JSON y se envía a través del canal de
  /// comunicación correspondiente (stdin del subproceso, BroadcastChannel
  /// en web, etc.).
  Future<void> sendMessage(Map<String, dynamic> message);

  /// Stream de eventos de la ventana de proyección.
  Stream<WindowEvent> get onWindowEvent;
}

/// Implementación para Desktop (Linux/Windows/MacOS).
///
/// Usa [window_manager](https://pub.dev/packages/window_manager) para
/// gestionar la ventana principal en modo proyección.
///
/// ## Limitación conocida
/// `window_manager` v0.5.1 **no soporta la creación de una segunda ventana**.
/// La API únicamente permite gestionar la ventana principal de la aplicación
/// (cambiar tamaño, posición, título, pantalla completa, etc.).
/// `openProjectionWindow()` configura la ventana **actual** en modo
/// proyección (pantalla completa, always-on-top, fondo negro, título
/// personalizado). Para una verdadera segunda ventana en desktop se
/// recomienda [SubprocessWindowService].
class DesktopWindowService implements WindowService {
  final StreamController<WindowEvent> _eventController =
      StreamController<WindowEvent>.broadcast();

  /// Estado previo de la ventana antes de entrar en modo proyección.
  _WindowSnapshot? _previousState;

  @override
  Future<void> openProjectionWindow(Map<String, dynamic> args) async {
    // Guardar estado actual de la ventana para restaurarlo después
    _previousState = await _WindowSnapshot.capture();

    // Configurar la ventana para proyección: fullscreen + always-on-top
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setTitle('MQ App - Proyección');
    await windowManager.setBackgroundColor(Colors.black);
    await windowManager.setSkipTaskbar(true);

    _eventController.add(
      WindowEvent(
        type: WindowEventType.opened,
        data: args,
      ),
    );
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    // No-op: DesktopWindowService usa la misma ventana, no necesita IPC
  }

  @override
  Future<void> closeProjectionWindow() async {
    if (_previousState != null) {
      // Restaurar estado previo de la ventana
      await windowManager.setFullScreen(_previousState!.wasFullScreen);
      await windowManager.setAlwaysOnTop(_previousState!.wasAlwaysOnTop);
      await windowManager.setTitle(_previousState!.title);
      await windowManager.setSkipTaskbar(_previousState!.wasSkipTaskbar);
      if (_previousState!.backgroundColor != null) {
        await windowManager.setBackgroundColor(
          _previousState!.backgroundColor!,
        );
      }
      _previousState = null;
    } else {
      // Sin estado guardado: restaurar valores por defecto
      await windowManager.setFullScreen(false);
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setTitle('MQ App');
      await windowManager.setSkipTaskbar(false);
    }

    _eventController.add(const WindowEvent(type: WindowEventType.closed));
  }

  @override
  Stream<WindowEvent> get onWindowEvent => _eventController.stream;
}

/// Firma de función para iniciar un proceso, análoga a [Process.start].
///
/// Los parámetros nombrados son [nullable] porque Dart no permite valores
/// por defecto en [typedef] de función. [SubprocessWindowService] pasa los
/// valores reales; los tests pueden omitirlos.
/// Se inyecta en [SubprocessWindowService] para facilitar los tests unitarios.
typedef ProcessStarter = Future<Process> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool? includeParentEnvironment,
  bool? runInShell,
  ProcessStartMode? mode,
});

/// Starter por defecto que delega en [Process.start].
Future<Process> _defaultStarter(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool? includeParentEnvironment,
  bool? runInShell,
  ProcessStartMode? mode,
}) =>
    Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment ?? true,
      runInShell: runInShell ?? false,
      mode: mode ?? ProcessStartMode.normal,
    );

/// Implementación que lanza una segunda instancia del proceso para la
/// ventana de proyección.
///
/// Usa [Process.start] para ejecutar una copia de la aplicación con el
/// argumento `--projection`, lo que crea una ventana Flutter independiente
/// dedicada a la proyección.
///
/// ## Ventajas
/// - Sin necesidad de plugins nativos adicionales (más allá de `window_manager`)
/// - Ventana verdaderamente independiente con su propio engine Flutter
/// - Compatible con Linux, macOS y Windows
///
/// ## Desventajas
/// - Mayor consumo de memoria (dos procesos Flutter)
/// - La comunicación entre ventanas requiere un mecanismo externo
///
/// ## Comunicación entre procesos
/// La comunicación se realiza a través de stdin/stdout del subproceso hijo
/// usando mensajes JSON delimitados por newline (\n).
/// La ventana principal escribe mensajes al stdin del hijo, y el hijo
/// responde por stdout.
///
/// [processStarter] permite inyectar un mecanismo de creación de procesos
/// alternativo (p.ej. en tests). Por defecto usa [Process.start].
class SubprocessWindowService implements WindowService {
  final ProcessStarter _processStarter;

  SubprocessWindowService({ProcessStarter? processStarter})
      : _processStarter = processStarter ?? _defaultStarter;

  final StreamController<WindowEvent> _eventController =
      StreamController<WindowEvent>.broadcast();

  /// StreamController para mensajes entrantes desde el proceso hijo.
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Referencia al proceso hijo de proyección, si está activo.
  Process? _projectionProcess;

  /// Stream de mensajes recibidos desde el proceso hijo (respuestas).
  Stream<Map<String, dynamic>> get onChildMessage =>
      _messageController.stream;

  @override
  Future<void> openProjectionWindow(Map<String, dynamic> args) async {
    // Si ya hay una ventana abierta, no crear otra
    if (_projectionProcess != null) {
      return;
    }

    try {
      _projectionProcess = await _processStarter(
        Platform.resolvedExecutable,
        ['--projection'],
        workingDirectory: Directory.current.path,
        includeParentEnvironment: true,
        runInShell: false,
        mode: ProcessStartMode.normal,
      );

      // Escuchar stdout del hijo para parsear respuestas JSON
      _projectionProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        try {
          final message = jsonDecode(line) as Map<String, dynamic>;
          _messageController.add(message);
        } catch (_) {
          // Ignorar líneas que no sean JSON válido
        }
      });

      // Escuchar stderr para logging
      _projectionProcess!.stderr.listen((data) {
        // Log opcional de stderr de la ventana de proyección
      });

      // Manejar la salida del proceso
      _projectionProcess!.exitCode.then((code) {
        _projectionProcess = null;
        _eventController.add(
          const WindowEvent(type: WindowEventType.closed),
        );
      });

      _eventController.add(
        WindowEvent(
          type: WindowEventType.opened,
          data: args,
        ),
      );
    } catch (e) {
      _projectionProcess = null;
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (_projectionProcess == null) return;
    final jsonLine = '${jsonEncode(message)}\n';
    _projectionProcess!.stdin.write(jsonLine);
  }

  @override
  Future<void> closeProjectionWindow() async {
    if (_projectionProcess != null) {
      _projectionProcess!.kill();
      _projectionProcess = null;
    }
    _eventController.add(const WindowEvent(type: WindowEventType.closed));
  }

  @override
  Stream<WindowEvent> get onWindowEvent => _eventController.stream;
}

/// Captura del estado de la ventana para poder restaurarlo.
class _WindowSnapshot {
  _WindowSnapshot({
    required this.wasFullScreen,
    required this.wasAlwaysOnTop,
    required this.title,
    required this.wasSkipTaskbar,
    this.backgroundColor,
  });

  final bool wasFullScreen;
  final bool wasAlwaysOnTop;
  final String title;
  final bool wasSkipTaskbar;
  final Color? backgroundColor;

  static Future<_WindowSnapshot> capture() async {
    return _WindowSnapshot(
      wasFullScreen: await windowManager.isFullScreen(),
      wasAlwaysOnTop: await windowManager.isAlwaysOnTop(),
      title: await windowManager.getTitle(),
      wasSkipTaskbar: await windowManager.isSkipTaskbar(),
      backgroundColor: null, // window_manager no permite leer el color actual
    );
  }
}

/// Implementación para Web.
///
/// Usa [window.open()](https://developer.mozilla.org/en-US/docs/Web/API/Window/open)
/// + [BroadcastChannel](https://developer.mozilla.org/en-US/docs/Web/API/BroadcastChannel)
/// para comunicación entre ventanas.
class WebWindowService implements WindowService {
  final StreamController<WindowEvent> _eventController =
      StreamController<WindowEvent>.broadcast();

  @override
  Future<void> openProjectionWindow(Map<String, dynamic> args) async {
    // TODO(web): Habilitar cuando dart:html esté disponible en compilación web.
    _eventController.add(
      WindowEvent(
        type: WindowEventType.opened,
        data: args,
      ),
    );
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    // TODO(web): Implementar vía BroadcastChannel cuando esté disponible
  }

  @override
  Future<void> closeProjectionWindow() async {
    _eventController.add(const WindowEvent(type: WindowEventType.closed));
  }

  @override
  Stream<WindowEvent> get onWindowEvent => _eventController.stream;
}

/// Implementación stub para dispositivos móviles.
///
/// Las operaciones de ventana secundaria no están soportadas
/// en plataformas que no permiten múltiples ventanas.
class MobileWindowService implements WindowService {
  @override
  Future<void> openProjectionWindow(Map<String, dynamic> args) =>
      Future.error(
        UnsupportedError(
          'Segunda ventana no soportada en móvil',
        ),
      );

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    // No-op: móvil no soporta segunda ventana
  }

  @override
  Future<void> closeProjectionWindow() => Future.value();

  @override
  Stream<WindowEvent> get onWindowEvent => const Stream.empty();
}
