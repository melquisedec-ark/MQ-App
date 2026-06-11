import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_config_provider.dart';

/// Notifier de prueba para [themeModeProvider] que NO accede a la base de datos.
///
/// [ThemeModeNotifier] original ejecuta `_loadFromDb()` en su constructor,
/// lo cual crea un timer de sqflite de 10s que queda pendiente en CI y hace
/// fallar los tests de widgets. Este notifier reemplaza completamente la
/// implementación para tests.
class TestThemeModeNotifier extends StateNotifier<ThemeMode> {
  TestThemeModeNotifier() : super(ThemeMode.light);

  void setThemeMode(ThemeMode mode) => state = mode;
}

/// Override listo para usar en [ProviderScope] de tests de widgets.
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     themeModeTestOverride,
///     ...otherOverrides,
///   ],
///   child: ...,
/// )
/// ```
final themeModeTestOverride = themeModeProvider.overrideWith(
  (ref) => TestThemeModeNotifier(),
);
