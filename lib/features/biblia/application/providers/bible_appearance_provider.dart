import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/biblia_config_repository.dart';
import 'biblia_config_provider.dart';

/// Temas de lectura predefinidos para el lector bíblico.
///
/// Cada tema define un fondo y color de texto optimizados para
/// diferentes condiciones de iluminación. Reemplaza el selector
/// de color individual (v1.0.4b).
enum ReadingTheme {
  papel('Papel', Color(0xFFFAFAFA), Color(0xFF2D2D2D)),
  sepia('Sepia', Color(0xFFF5E6C8), Color(0xFF5C4033)),
  noche('Noche', Color(0xFF1A1A1A), Color(0xFFE8E8E8)),
  azulNoche('Azul noche', Color(0xFF1E293B), Color(0xFFCBD5E1)),
  altoContraste('Alto contraste', Color(0xFFFFFFFF), Color(0xFF000000));

  const ReadingTheme(this.label, this.backgroundColor, this.textColor);
  final String label;
  final Color backgroundColor;
  final Color textColor;

  /// Convierte nombre de color antiguo al tema más cercano.
  static ReadingTheme fromOldColorName(String name) {
    switch (name) {
      case 'negro':
        return ReadingTheme.altoContraste;
      case 'sepia':
        return ReadingTheme.sepia;
      case 'azul':
        return ReadingTheme.azulNoche;
      default:
        return ReadingTheme.papel;
    }
  }

  /// ID string para persistencia en BD.
  String get id => name;

  /// Busca tema por ID string.
  static ReadingTheme? fromId(String? id) {
    for (final t in ReadingTheme.values) {
      if (t.name == id) return t;
    }
    return null;
  }
}

/// Estado de apariencia del lector bíblico.
///
/// Persistido en `biblia.db` vía [BibliaConfigRepository]. Sigue el mismo
/// patrón que [ThemeModeNotifier].
class BibleAppearanceState {
  /// Escala de fuente (0.8 – 1.5, default 1.0).
  final double fontScale;

  /// Familia tipográfica ('system', 'serif', 'monospace').
  final String fontFamily;

  /// Color del texto (depende del tema).
  final Color textColor;

  /// Altura de línea (1.4 – 2.0, default 1.6).
  final double lineHeight;

  /// Color de fondo del tema de lectura actual.
  final Color backgroundColor;

  /// ID del tema de lectura seleccionado.
  final String themeId;

  const BibleAppearanceState({
    this.fontScale = 1.0,
    this.fontFamily = 'system',
    this.textColor = Colors.white,
    this.lineHeight = 1.6,
    this.backgroundColor = Colors.black,
    this.themeId = 'papel',
  });

  BibleAppearanceState copyWith({
    double? fontScale,
    String? fontFamily,
    Color? textColor,
    double? lineHeight,
    Color? backgroundColor,
    String? themeId,
  }) {
    return BibleAppearanceState(
      fontScale: fontScale ?? this.fontScale,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      lineHeight: lineHeight ?? this.lineHeight,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      themeId: themeId ?? this.themeId,
    );
  }
}

/// Provider del estado de apariencia del lector bíblico.
///
/// Se hidrata desde BD al iniciar; cada cambio se persiste automáticamente.
final bibleAppearanceProvider =
    StateNotifierProvider<BibleAppearanceNotifier, BibleAppearanceState>(
  (ref) => BibleAppearanceNotifier(ref),
);

class BibleAppearanceNotifier extends StateNotifier<BibleAppearanceState> {
  final Ref _ref;
  bool _hydrated = false;

  BibleAppearanceNotifier(this._ref) : super(const BibleAppearanceState()) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);

      final rawFontScale = await repo.get(
        BibliaConfigKeys.bibliaFontScale,
        defaultValue: '1.0',
      );
      final rawFontFamily = await repo.get(
        BibliaConfigKeys.bibliaFontFamily,
        defaultValue: 'system',
      );
      // Migración: si existe tema nuevo, usarlo; si no, mapear color viejo.
      final rawTheme = await repo.get(
        BibliaConfigKeys.bibliaReadingTheme,
        defaultValue: '',
      );
      ReadingTheme theme;
      if (rawTheme.isNotEmpty) {
        theme = ReadingTheme.fromId(rawTheme) ?? ReadingTheme.papel;
      } else {
        // Migración desde color antiguo → tema más cercano.
        final rawTextColor = await repo.get(
          BibliaConfigKeys.bibliaTextColor,
          defaultValue: 'blanco',
        );
        theme = ReadingTheme.fromOldColorName(rawTextColor);
      }
      final rawLineHeight = await repo.get(
        BibliaConfigKeys.bibliaLineHeight,
        defaultValue: '1.6',
      );

      if (!_hydrated) {
        _hydrated = true;
        state = BibleAppearanceState(
          fontScale: double.tryParse(rawFontScale) ?? 1.0,
          fontFamily: rawFontFamily,
          textColor: theme.textColor,
          lineHeight: double.tryParse(rawLineHeight) ?? 1.6,
          backgroundColor: theme.backgroundColor,
          themeId: theme.id,
        );
      }
    } catch (_) {
      _hydrated = true;
    }
  }

  /// Escala de fuente (0.8 – 1.5).
  void setFontScale(double value) {
    final clamped = value.clamp(0.8, 1.5);
    state = state.copyWith(fontScale: clamped);
    _persist(BibliaConfigKeys.bibliaFontScale, clamped.toStringAsFixed(1));
  }

  /// Familia tipográfica ('system', 'serif', 'monospace').
  void setFontFamily(String value) {
    state = state.copyWith(fontFamily: value);
    _persist(BibliaConfigKeys.bibliaFontFamily, value);
  }

  /// Tema de lectura predefinido.
  void setTheme(ReadingTheme theme) {
    state = state.copyWith(
      textColor: theme.textColor,
      backgroundColor: theme.backgroundColor,
      themeId: theme.id,
    );
    _persist(BibliaConfigKeys.bibliaReadingTheme, theme.id);
  }

  /// Altura de línea (1.4 – 2.0).
  void setLineHeight(double value) {
    final clamped = value.clamp(1.4, 2.0);
    state = state.copyWith(lineHeight: clamped);
    _persist(BibliaConfigKeys.bibliaLineHeight, clamped.toStringAsFixed(1));
  }

  void _persist(String key, String value) {
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      repo.set(key, value);
    } catch (_) {
      // Silent fail; el state local ya quedó actualizado
    }
  }
}
