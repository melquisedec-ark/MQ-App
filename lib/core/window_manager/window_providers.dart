import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'window_service.dart';

/// Provider del servicio de ventana de proyección.
///
/// Inyecta la implementación adecuada según la plataforma:
/// - Web: [WebWindowService] con `window.open()` + `BroadcastChannel`
/// - Desktop (Windows, Linux, macOS): [SubprocessWindowService] que lanza
///   una segunda instancia de la app con el argumento `--projection`.
///   Esto es necesario porque `window_manager` v0.5.1 no soporta la creación
///   de una segunda ventana real. [DesktopWindowService] queda como respaldo
///   para el modo de ventana única (fullscreen + always-on-top).
/// - Móvil: [MobileWindowService] stub (no soportado)
final windowServiceProvider = Provider<WindowService>((ref) {
  if (kIsWeb) {
    return WebWindowService();
  }
  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return SubprocessWindowService();
    }
  } catch (_) {}
  return MobileWindowService();
});
