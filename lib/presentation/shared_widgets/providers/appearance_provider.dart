import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../../data/repositories/fondo_repository_impl.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../../core/enums/fondo_pantalla_tipo.dart';

/// Estado global de apariencia para el modo personal.
/// Controla fondo, colores de texto/acordes, tamaño de fuente y toggle de acordes.
class HymnAppearanceState {
  final Color bgColor;
  final FondoPantalla? selectedFondo; // fondo seleccionado (imagen o color)
  final Color textColor;
  final Color chordColor;
  final double fontScale;
  final String fontFamily;
  final bool isBold;
  final double projectionFontScale;
  final bool showChords;
  final double cardOpacity;
  final double glassBlurSigma;
  final bool glassEnabled;
  final Color glassOverlayColor;

  const HymnAppearanceState({
    this.bgColor = Colors.transparent,
    this.selectedFondo,
    this.textColor = const Color(0xFF1C1B1F),
    this.chordColor = const Color(0xFFCCA43B),
    this.fontScale = 1.0,
    this.fontFamily = 'Merriweather',
    this.isBold = false,
    this.projectionFontScale = 1.0,
    this.showChords = true,
    this.cardOpacity = 0.1,
    this.glassBlurSigma = 10.0,
    this.glassEnabled = true,
    this.glassOverlayColor = Colors.white,
  });

  static const _fondoSentinel = Object();

  HymnAppearanceState copyWith({
    Color? bgColor,
    Object? selectedFondo = _fondoSentinel,
    Color? textColor,
    Color? chordColor,
    double? fontScale,
    String? fontFamily,
    bool? isBold,
    double? projectionFontScale,
    bool? showChords,
    double? cardOpacity,
    double? glassBlurSigma,
    bool? glassEnabled,
    Color? glassOverlayColor,
  }) {
    return HymnAppearanceState(
      bgColor: bgColor ?? this.bgColor,
      selectedFondo: selectedFondo == _fondoSentinel
          ? this.selectedFondo
          : selectedFondo as FondoPantalla?,
      textColor: textColor ?? this.textColor,
      chordColor: chordColor ?? this.chordColor,
      fontScale: fontScale ?? this.fontScale,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      projectionFontScale: projectionFontScale ?? this.projectionFontScale,
      showChords: showChords ?? this.showChords,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      glassBlurSigma: glassBlurSigma ?? this.glassBlurSigma,
      glassEnabled: glassEnabled ?? this.glassEnabled,
      glassOverlayColor: glassOverlayColor ?? this.glassOverlayColor,
    );
  }
}

class HymnAppearanceNotifier extends StateNotifier<HymnAppearanceState> {
  final DatabaseHelper _dbHelper;

  HymnAppearanceNotifier(this._dbHelper) : super(const HymnAppearanceState()) {
    _loadFromDb();
  }

  /// Carga las preferencias guardadas desde la BD
  Future<void> _loadFromDb() async {
    try {
      final fontFamily = await _dbHelper.getConfig('font_family');
      final isBold = await _dbHelper.getConfig('is_bold');
      final bgColor = await _dbHelper.getConfig('bg_color');
      final textColor = await _dbHelper.getConfig('text_color');
      final chordColor = await _dbHelper.getConfig('chord_color');
      final fontScale = await _dbHelper.getConfig('font_scale');
      final projectionFontScale =
          await _dbHelper.getConfig('projection_font_scale');

      final showChordsStr = await _dbHelper.getConfig('show_chords');
      final cardOpacityStr = await _dbHelper.getConfig('card_opacity');
      final glassBlurSigmaStr = await _dbHelper.getConfig('glass_blur_sigma');
      final glassEnabledStr = await _dbHelper.getConfig('glass_enabled');
      final glassOverlayColorStr = await _dbHelper.getConfig('glass_overlay_color');

      state = state.copyWith(
        fontFamily: fontFamily ?? 'Merriweather',
        isBold: isBold == 'true',
        bgColor: bgColor != null ? _hexToColor(bgColor) : Colors.transparent,
        textColor: textColor != null ? _hexToColor(textColor) : const Color(0xFF1C1B1F),
        chordColor: chordColor != null ? _hexToColor(chordColor) : const Color(0xFFCCA43B),
        fontScale: fontScale != null ? double.tryParse(fontScale) ?? 1.0 : 1.0,
        projectionFontScale: projectionFontScale != null
            ? double.tryParse(projectionFontScale)?.clamp(0.5, 4.5) ?? 1.0
            : 1.0,
        showChords: showChordsStr == 'true',
        cardOpacity: cardOpacityStr != null ? double.tryParse(cardOpacityStr)?.clamp(0.0, 1.0) ?? 0.1 : 0.1,
        glassBlurSigma: glassBlurSigmaStr != null
            ? double.tryParse(glassBlurSigmaStr)?.clamp(0.0, 20.0) ?? 10.0
            : 10.0,
        glassEnabled: glassEnabledStr == 'true',
        glassOverlayColor: glassOverlayColorStr != null
            ? _hexToColor(glassOverlayColorStr)
            : Colors.white,
      );
      // Cargar fondo seleccionado
      final fondoIdStr = await _dbHelper.getConfig('bg_fondo_id');
      if (fondoIdStr != null && fondoIdStr.isNotEmpty) {
        final fondoId = int.tryParse(fondoIdStr);
        if (fondoId != null) {
          try {
            final dataSource = CatalogLocalDataSource(dbHelper: _dbHelper);
            final repo = FondoRepositoryImpl(dataSource);
            final fondo = await repo.getById(fondoId);
            if (fondo != null) {
              state = state.copyWith(selectedFondo: fondo);
            }
          } catch (_) {
            // Ignorar error al cargar fondo individual
          }
        }
      }
    } catch (e) {
      // Si falla la carga, usar valores por defecto
    }
  }

  /// Guarda las preferencias actuales en la BD
  Future<void> _saveToDb() async {
    try {
      await _dbHelper.setConfig('font_family', state.fontFamily);
      await _dbHelper.setConfig('is_bold', state.isBold.toString());
      await _dbHelper.setConfig('bg_color', _colorToHex(state.bgColor));
      await _dbHelper.setConfig('text_color', _colorToHex(state.textColor));
      await _dbHelper.setConfig('chord_color', _colorToHex(state.chordColor));
      await _dbHelper.setConfig('font_scale', state.fontScale.toString());
      await _dbHelper.setConfig(
        'projection_font_scale',
        state.projectionFontScale.toString(),
      );
      await _dbHelper.setConfig('show_chords', state.showChords.toString());
      await _dbHelper.setConfig('card_opacity', state.cardOpacity.toString());
      await _dbHelper.setConfig('glass_blur_sigma', state.glassBlurSigma.toString());
      await _dbHelper.setConfig('glass_enabled', state.glassEnabled.toString());
      await _dbHelper.setConfig('glass_overlay_color', _colorToHex(state.glassOverlayColor));
    } catch (e) {
      // Silent fail en escritura
    }
  }

  /// Guarda exclusivamente el fondo seleccionado en la BD.
  /// Separado de _saveToDb() para evitar que setters de apariencia
  /// (textColor, fontScale, etc.) sobrescriban bg_fondo_id = ''.
  Future<void> _saveBgFondoId(String? id) async {
    try {
      await _dbHelper.setConfig('bg_fondo_id', id ?? '');
    } catch (e) {
      // Silent fail
    }
  }

  /// Convierte Color a string hex (ej: #FF6750A4)
  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Convierte string hex a Color
  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    // Si el hex es de 6 dígitos (sin alpha), agregar FF como alpha por defecto
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  // ─── Setters (todos guardan después de cambiar) ───
  void setBgColor(Color color) {
    state = state.copyWith(bgColor: color, selectedFondo: null);
    _saveToDb();
    _saveBgFondoId(null);
  }

  void setFondo(FondoPantalla fondo) {
    Color resolvedColor;
    switch (fondo.tipo) {
      case FondoPantallaTipo.colorSolido:
        resolvedColor = fondo.colorHex != null
            ? _hexToColor(fondo.colorHex!)
            : Colors.transparent;
        break;
      case FondoPantallaTipo.imagen:
        resolvedColor = Colors.transparent;
    }
    state = state.copyWith(
      bgColor: resolvedColor,
      selectedFondo: fondo,
    );
    _saveToDb();
    _saveBgFondoId(fondo.id.toString());
  }

  /// Limpia el fondo seleccionado dejando solo el color sólido.
  void clearFondo() {
    state = state.copyWith(selectedFondo: null);
    _saveToDb();
    _saveBgFondoId(null);
  }

  void setTextColor(Color color) {
    state = state.copyWith(textColor: color);
    _saveToDb();
  }

  void setChordColor(Color color) {
    state = state.copyWith(chordColor: color);
    _saveToDb();
  }

  void setFontScale(double scale) {
    state = state.copyWith(fontScale: scale);
    _saveToDb();
  }

  void setProjectionFontScale(double scale) {
    state = state.copyWith(projectionFontScale: scale.clamp(0.5, 4.5));
    _saveToDb();
  }

  void setFontFamily(String family) {
    state = state.copyWith(fontFamily: family);
    _saveToDb();
  }

  void setIsBold(bool value) {
    state = state.copyWith(isBold: value);
    _saveToDb();
  }

  void toggleBold() {
    state = state.copyWith(isBold: !state.isBold);
    _saveToDb();
  }

  void setShowChords(bool value) {
    state = state.copyWith(showChords: value);
    _saveToDb();
  }

  void toggleShowChords() {
    state = state.copyWith(showChords: !state.showChords);
    _saveToDb();
  }

  void setCardOpacity(double value) {
    state = state.copyWith(cardOpacity: value.clamp(0.0, 1.0));
    _saveToDb();
  }

  void setGlassBlurSigma(double value) {
    state = state.copyWith(glassBlurSigma: value.clamp(0.0, 20.0));
    _saveToDb();
  }

  void setGlassEnabled(bool value) {
    state = state.copyWith(glassEnabled: value);
    _saveToDb();
  }

  void toggleGlass() {
    state = state.copyWith(glassEnabled: !state.glassEnabled);
    _saveToDb();
  }

  void setGlassOverlayColor(Color color) {
    state = state.copyWith(glassOverlayColor: color);
    _saveToDb();
  }

  void reset() {
    state = const HymnAppearanceState();
    _saveToDb();
  }
}

final hymnAppearanceProvider =
    StateNotifierProvider<HymnAppearanceNotifier, HymnAppearanceState>((ref) {
  return HymnAppearanceNotifier(DatabaseHelper.instance);
});
