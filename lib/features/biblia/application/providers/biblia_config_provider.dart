import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/nota.dart';
import '../../data/repositories/biblia_config_repository.dart';
import 'biblia_version_provider.dart';
import 'current_libro_provider.dart';

/// Provider del [BibliaConfigRepository]. Reusa el `bibleDatabaseHelperProvider`.
final bibliaConfigRepositoryProvider = Provider<BibliaConfigRepository>((ref) {
  final db = ref.watch(bibleDatabaseHelperProvider);
  return BibliaConfigRepository(db);
});

/// Modo de tema seleccionado por el usuario.
///
/// Hidrata desde la BD en el constructor; las actualizaciones se persisten
/// vía [setThemeMode]. Se usa desde la pantalla de Settings.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;

  ThemeModeNotifier(this._ref) : super(ThemeMode.system) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      final raw = await repo.get(
        BibliaConfigKeys.themeMode,
        defaultValue: 'system',
      );
      state = _parseMode(raw);
    } catch (_) {
      // Si falla, mantener ThemeMode.system
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      await repo.set(BibliaConfigKeys.themeMode, _modeName(mode));
    } catch (_) {
      // Silent fail; el state local ya quedó actualizado
    }
  }

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
}

/// Extensión sobre [ThemeMode] que cicla entre los 3 modos.
///
/// Orden del ciclo: light → dark → system → light. Se usa desde el FAB de
/// tema ([ThemeModeToggleButton]) y desde [setThemeMode] del notifier.
extension ThemeModeCycle on ThemeMode {
  /// Devuelve el siguiente modo en el ciclo light/dark/system.
  ThemeMode get cycle {
    switch (this) {
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
      case ThemeMode.system:
        return ThemeMode.light;
    }
  }
}

/// Versión bíblica preferida (abreviatura: "RV1909" o "RV1569").
///
/// Se persiste en `biblia.config` y se aplica al `currentVersionIdProvider`
/// cuando la UI lo necesita.
final preferredBibliaVersionProvider =
    StateNotifierProvider<PreferredBibliaVersionNotifier, String>(
  (ref) => PreferredBibliaVersionNotifier(ref),
);

class PreferredBibliaVersionNotifier extends StateNotifier<String> {
  final Ref _ref;

  PreferredBibliaVersionNotifier(this._ref) : super('RV1909') {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      final raw = await repo.get(
        BibliaConfigKeys.versionPreferida,
        defaultValue: 'RV1909',
      );
      state = raw;
    } catch (_) {
      // Mantener default
    }
  }

  Future<void> setVersion(String abreviatura) async {
    state = abreviatura;
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      await repo.set(BibliaConfigKeys.versionPreferida, abreviatura);
      // Aplicar al provider de versión actual.
      final versions = await _ref.read(activeBibliaVersionsProvider.future);
      final match = versions.firstWhere(
        (v) => v.abreviatura == abreviatura,
        orElse: () => versions.first,
      );
      _ref.read(currentVersionIdProvider.notifier).state = match.id;
    } catch (_) {
      // Silent fail
    }
  }
}

/// Modo de vista del emisor por defecto (compact / preview).
///
/// Es la preferencia persistente; el modo *actual* en runtime se
/// mantiene en `currentEmitterViewModeProvider` (no persistente).
final emitterViewModeDefaultProvider =
    StateNotifierProvider<EmitterViewModeDefaultNotifier, String>(
  (ref) => EmitterViewModeDefaultNotifier(ref),
);

class EmitterViewModeDefaultNotifier extends StateNotifier<String> {
  final Ref _ref;

  EmitterViewModeDefaultNotifier(this._ref) : super('compact') {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      state = await repo.get(
        BibliaConfigKeys.emitterViewModeDefault,
        defaultValue: 'compact',
      );
    } catch (_) {}
  }

  Future<void> setMode(String value) async {
    state = value;
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      await repo.set(BibliaConfigKeys.emitterViewModeDefault, value);
    } catch (_) {}
  }
}

/// Modo de vista *actual* del emisor (no persistente; cambia en runtime).
///
/// Es lo que la UI consulta para saber si renderizar Compact o Preview.
/// El default se hidrata desde [emitterViewModeDefaultProvider].
final currentEmitterViewModeProvider =
    StateProvider<String>((ref) {
  return ref.watch(emitterViewModeDefaultProvider);
});

/// Glassmorphism habilitado (bool). Persistido en BD.
final glassmorphismEnabledProvider =
    StateNotifierProvider<GlassmorphismEnabledNotifier, bool>(
  (ref) => GlassmorphismEnabledNotifier(ref),
);

class GlassmorphismEnabledNotifier extends StateNotifier<bool> {
  final Ref _ref;

  GlassmorphismEnabledNotifier(this._ref) : super(true) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      state = await repo.getBool(
        BibliaConfigKeys.glassmorphismEnabled,
        defaultValue: true,
      );
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      await repo.setBool(BibliaConfigKeys.glassmorphismEnabled, value);
    } catch (_) {}
  }
}

/// Auto-registrar historial al leer versículos.
final autoHistorialProvider =
    StateNotifierProvider<AutoHistorialNotifier, bool>(
  (ref) => AutoHistorialNotifier(ref),
);

class AutoHistorialNotifier extends StateNotifier<bool> {
  final Ref _ref;

  AutoHistorialNotifier(this._ref) : super(true) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      state = await repo.getBool(
        BibliaConfigKeys.autoHistorial,
        defaultValue: true,
      );
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      await repo.setBool(BibliaConfigKeys.autoHistorial, value);
    } catch (_) {}
  }
}

/// Color por defecto al crear una nota.
final notaColorDefaultProvider =
    StateNotifierProvider<NotaColorDefaultNotifier, NotaColor>(
  (ref) => NotaColorDefaultNotifier(ref),
);

class NotaColorDefaultNotifier extends StateNotifier<NotaColor> {
  final Ref _ref;

  NotaColorDefaultNotifier(this._ref) : super(NotaColor.ninguno) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      final raw = await repo.get(
        BibliaConfigKeys.notaColorDefault,
        defaultValue: 'ninguno',
      );
      state = NotaColorX.fromString(raw) ?? NotaColor.ninguno;
    } catch (_) {}
  }

  Future<void> setColor(NotaColor color) async {
    state = color;
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      await repo.set(BibliaConfigKeys.notaColorDefault, color.value);
    } catch (_) {}
  }
}
