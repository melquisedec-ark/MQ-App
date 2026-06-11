import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_config_provider.dart';

/// Override listo para usar en [ProviderScope] de tests de widgets.
///
/// [ThemeModeNotifier] original ejecuta `_loadFromDb()` en su constructor,
/// lo cual crea un timer de sqflite de 10s que queda pendiente en CI y hace
/// fallar los tests de widgets. Este override usa `autoLoad: false` para
/// evitar el acceso a BD y setea el estado inicial directamente.
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
  (ref) => ThemeModeNotifier(ref, autoLoad: false)..state = ThemeMode.light,
);
