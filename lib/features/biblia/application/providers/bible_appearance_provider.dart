import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/biblia_config_repository.dart';
import 'biblia_config_provider.dart';

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

  const BibleAppearanceState({
    this.fontScale = 1.0,
    this.fontFamily = 'system',
    this.textColor = Colors.white,
    this.lineHeight = 1.6,
  });

  BibleAppearanceState copyWith({
    double? fontScale,
    String? fontFamily,
    Color? textColor,
    double? lineHeight,
  }) {
    return BibleAppearanceState(
      fontScale: fontScale ?? this.fontScale,
      fontFamily: fontFamily ?? this.fontFamily,
      textColor: textColor ?? this.textColor,
      lineHeight: lineHeight ?? this.lineHeight,
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
      final rawTextColor = await repo.get(
        BibliaConfigKeys.bibliaTextColor,
        defaultValue: 'blanco',
      );
      final rawLineHeight = await repo.get(
        BibliaConfigKeys.bibliaLineHeight,
        defaultValue: '1.6',
      );

      if (!_hydrated) {
        _hydrated = true;
        state = BibleAppearanceState(
          fontScale: double.tryParse(rawFontScale) ?? 1.0,
          fontFamily: rawFontFamily,
          textColor: _colorFromName(rawTextColor),
          lineHeight: double.tryParse(rawLineHeight) ?? 1.6,
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

  /// Color del texto.
  void setTextColor(Color value) {
    state = state.copyWith(textColor: value);
    _persist(BibliaConfigKeys.bibliaTextColor, _colorName(value));
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

  /// Parsea nombre de color a [Color].
  static Color _colorFromName(String name) {
    switch (name) {
      case 'negro':
        return Colors.black;
      case 'sepia':
        return const Color(0xFF3E2723); // marrón oscuro sepia
      case 'azul':
        return const Color(0xFF1565C0);
      default:
        return Colors.white;
    }
  }

  /// Convierte [Color] a nombre para persistencia.
  static String _colorName(Color color) {
    if (color == Colors.black) return 'negro';
    if (color == const Color(0xFF3E2723)) return 'sepia';
    if (color == const Color(0xFF1565C0)) return 'azul';
    return 'blanco';
  }
}
