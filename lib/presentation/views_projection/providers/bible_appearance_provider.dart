import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de apariencia bíblica en el receptor.
///
/// Mantiene el tema y escala de fuente para la proyección de versículos.
/// Este provider es independiente del himnario y se actualiza vía mensajes
/// stdin (SET_BIBLE_THEME, SET_BIBLE_FONT_SIZE).
class BibleAppearanceState {
  final String theme;       // 'papel', 'sepia', 'noche', 'dark', 'azulNoche', 'altoContraste'
  final double fontScale;   // 0.8 - 4.0

  const BibleAppearanceState({
    this.theme = 'papel',
    this.fontScale = 1.0,
  });

  BibleAppearanceState copyWith({String? theme, double? fontScale}) {
    return BibleAppearanceState(
      theme: theme ?? this.theme,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

/// Notifier de apariencia bíblica para la ventana receptora.
class BibleAppearanceNotifier extends StateNotifier<BibleAppearanceState> {
  BibleAppearanceNotifier() : super(const BibleAppearanceState());

  /// Cambia el tema visual de proyección bíblica.
  void setTheme(String theme) => state = state.copyWith(theme: theme);

  /// Cambia la escala de fuente (clamp 0.8 - 4.0).
  void setFontScale(double scale) =>
      state = state.copyWith(fontScale: scale.clamp(0.8, 4.0));
}

/// Provider de apariencia bíblica en el receptor.
///
/// NO depende de servicios de red — el subprocess se lanza con
/// `skipNetwork: true`.
final bibleAppearanceProvider =
    StateNotifierProvider<BibleAppearanceNotifier, BibleAppearanceState>(
  (ref) => BibleAppearanceNotifier(),
);
