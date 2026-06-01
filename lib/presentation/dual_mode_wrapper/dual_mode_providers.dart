import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_mode.dart';

/// Notifier para el modo de dispositivo (PC/Celular).
///
/// En producción, detecta automáticamente la plataforma.
/// En debug, permite override manual para facilitar el desarrollo.
///
/// TODO: Persistir la selección de modo usando `shared_preferences`
/// para recordar la elección entre sesiones en modo debug.
/// Actualmente `shared_preferences` no está incluido en pubspec.yaml.
class DualModeNotifier extends StateNotifier<DeviceMode> {
  DualModeNotifier() : super(_detectInitialMode());

  static DeviceMode _detectInitialMode() {
    if (kReleaseMode) {
      // En producción: detectar automáticamente
      if (kIsWeb) return DeviceMode.desktop;
      try {
        if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
          return DeviceMode.desktop;
        }
      } catch (_) {
        // Platform no disponible (web con import condicional)
      }
      return DeviceMode.phone;
    }
    // En debug: phone por defecto (se puede cambiar con DeviceSwitch)
    return DeviceMode.phone;
  }

  /// Cambia al modo especificado.
  void setMode(DeviceMode mode) => state = mode;

  /// Conmuta entre [DeviceMode.phone] y [DeviceMode.desktop].
  void toggleMode() {
    state = state == DeviceMode.phone ? DeviceMode.desktop : DeviceMode.phone;
  }
}

/// Provider principal del modo dual.
///
/// Expone el [DeviceMode] actual y permite cambiarlo a través
/// de [DualModeNotifier.setMode] o [DualModeNotifier.toggleMode].
final deviceModeProvider =
    StateNotifierProvider<DualModeNotifier, DeviceMode>(
  (ref) => DualModeNotifier(),
);

/// Provider derivado: `true` si el dispositivo está en modo [DeviceMode.desktop].
final isDesktopModeProvider = Provider<bool>(
  (ref) => ref.watch(deviceModeProvider) == DeviceMode.desktop,
);

/// Provider derivado: `true` si el dispositivo está en modo [DeviceMode.phone].
final isPhoneModeProvider = Provider<bool>(
  (ref) => ref.watch(deviceModeProvider) == DeviceMode.phone,
);
