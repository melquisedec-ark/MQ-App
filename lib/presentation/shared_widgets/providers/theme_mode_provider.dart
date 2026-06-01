import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';

/// Provider del modo de tema (claro, oscuro o sistema).
///
/// Persiste la selección en la tabla [Configuracion] bajo la clave
/// `'theme_mode'` con valores `'light'`, `'dark'` o `'system'`.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(DatabaseHelper.instance);
});

/// Notifier que gestiona el modo de tema seleccionado por el usuario.
///
/// Al iniciar carga la preferencia guardada; si no existe usa [ThemeMode.system]
/// para que la primera vez se adapte al tema del dispositivo.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final DatabaseHelper _dbHelper;

  ThemeModeNotifier(this._dbHelper) : super(ThemeMode.system) {
    _loadFromDb();
  }

  /// Carga la preferencia guardada desde la BD.
  Future<void> _loadFromDb() async {
    try {
      final saved = await _dbHelper.getConfig('theme_mode');
      if (saved != null) {
        state = _parseMode(saved);
      }
    } catch (_) {
      // Si falla la lectura, usar ThemeMode.system (valor por defecto)
    }
  }

  /// Persiste el modo actual en la BD.
  Future<void> _saveToDb() async {
    try {
      await _dbHelper.setConfig('theme_mode', _modeName(state));
    } catch (_) {
      // Silent fail en escritura
    }
  }

  /// Convierte un String al [ThemeMode] correspondiente.
  ThemeMode _parseMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Convierte [ThemeMode] a su nombre en String.
  String _modeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Cicla entre los modos: Light → Dark → System → Light.
  void cycleMode() {
    switch (state) {
      case ThemeMode.light:
        state = ThemeMode.dark;
      case ThemeMode.dark:
        state = ThemeMode.system;
      case ThemeMode.system:
        state = ThemeMode.light;
    }
    _saveToDb();
  }
}
