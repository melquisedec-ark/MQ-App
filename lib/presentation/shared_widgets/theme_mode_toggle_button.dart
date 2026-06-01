import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_mode_provider.dart';

/// Botón para alternar entre modo claro, oscuro y seguir el tema del dispositivo.
///
/// Muestra un icono dinámico según el modo actual:
/// - ☀️ `light_mode` → modo claro
/// - 🌙 `dark_mode` → modo oscuro
/// - 🤖 `brightness_auto` → seguir dispositivo
///
/// Nota: el posicionamiento está a cargo del widget padre ([_BottomRightButtons]
/// en himnario_dual_app.dart). Este widget solo devuelve el [FloatingActionButton].
class ThemeModeToggleButton extends ConsumerWidget {
  const ThemeModeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return FloatingActionButton(
      heroTag: 'theme_mode_toggle',
      backgroundColor: const Color(0xFFCCA43B),
      foregroundColor: const Color(0xFF1A1A1A),
      onPressed: () => ref.read(themeModeProvider.notifier).cycleMode(),
      tooltip: _tooltip(themeMode),
      child: Icon(_icon(themeMode)),
    );
  }

  IconData _icon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _tooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Modo claro';
      case ThemeMode.dark:
        return 'Modo oscuro';
      case ThemeMode.system:
        return 'Seguir dispositivo';
    }
  }
}
