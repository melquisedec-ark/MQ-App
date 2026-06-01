import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

/// Notifier para el modo de pantalla completa en móvil.
///
/// Oculta la barra de estado y navegación usando SystemChrome.
/// Envuelve las llamadas en try-catch porque SystemChrome no está
/// disponible en web.
class FullscreenModeNotifier extends StateNotifier<bool> {
  static final _log = Logger('FullscreenModeNotifier');

  FullscreenModeNotifier() : super(false);

  /// Activa el modo fullscreen: oculta UI del sistema (modo immersive).
  void enterFullscreen() {
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      state = true;
      _log.info('Fullscreen activado');
    } catch (e) {
      _log.warning('Error al activar fullscreen: $e');
    }
  }

  /// Desactiva el modo fullscreen: restaura UI del sistema (edge-to-edge).
  void exitFullscreen() {
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.restoreSystemUIOverlays();
      state = false;
      _log.info('Fullscreen desactivado');
    } catch (e) {
      _log.warning('Error al desactivar fullscreen: $e');
    }
  }

  @override
  void dispose() {
    if (state) exitFullscreen();
    super.dispose();
  }
}

/// Provider que expone el estado fullscreen (true/false).
///
/// Usar [fullscreenModeProvider.notifier] para llamar a
/// [FullscreenModeNotifier.enterFullscreen] o [FullscreenModeNotifier.exitFullscreen].
final fullscreenModeProvider =
    StateNotifierProvider<FullscreenModeNotifier, bool>(
  (ref) => FullscreenModeNotifier(),
);
