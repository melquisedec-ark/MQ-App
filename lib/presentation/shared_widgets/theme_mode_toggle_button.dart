import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/biblia/application/providers/biblia_config_provider.dart';

/// Botón flotante para alternar entre modo claro, oscuro y seguir el dispositivo.
///
/// - **Tap** → cicla al siguiente modo (light → dark → system → light).
/// - **Long press** → abre un [BottomSheet] con 3 [RadioListTile] para elegir.
///
/// Muestra un icono dinámico según el modo actual:
/// - `light_mode` → modo claro
/// - `dark_mode` → modo oscuro
/// - `brightness_auto` → seguir dispositivo
///
/// El posicionamiento (Stack/Positioned o Scaffold.floatingActionButton) lo
/// decide el widget padre.
class ThemeModeToggleButton extends ConsumerWidget {
  const ThemeModeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Tooltip(
      message: _tooltip(themeMode),
      child: GestureDetector(
        onTap: () => ref
            .read(themeModeProvider.notifier)
            .setThemeMode(themeMode.cycle),
        onLongPress: () => _showThemePicker(context, ref, themeMode),
        child: Material(
          shape: const CircleBorder(),
          elevation: 6,
          color: const Color(0xFFCCA43B),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              _icon(themeMode),
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra un [BottomSheet] con 3 [RadioListTile] para seleccionar el tema.
  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Tema de la aplicación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            for (final entry in const [
              (ThemeMode.system, 'Seguir dispositivo',
                  Icons.brightness_auto_rounded),
              (ThemeMode.light, 'Modo claro', Icons.light_mode_rounded),
              (ThemeMode.dark, 'Modo oscuro', Icons.dark_mode_rounded),
            ])
              RadioListTile<ThemeMode>(
                title: Text(entry.$2),
                secondary: Icon(entry.$3),
                value: entry.$1,
                groupValue: current,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
          ],
        ),
      ),
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
