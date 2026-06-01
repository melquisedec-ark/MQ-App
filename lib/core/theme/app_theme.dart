import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Temas de la aplicación HimnarioID 2.0.
///
/// Paleta corporativa: Negro, Dorado, Blanco.
/// NO usa [colorSchemeSeed] ni [ColorScheme.fromSeed] — todos los
/// colores se definen manualmente en [AppColors].
class AppTheme {
  AppTheme._();

  // ─── Tema Claro ───
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: AppColors.lightColorScheme,
    scaffoldBackgroundColor: AppColors.lightColorScheme.surface,
    appBarTheme: _lightAppBarTheme,
    cardTheme: _lightCardTheme,
    floatingActionButtonTheme: _fabTheme,
    navigationBarTheme: _navigationBarTheme,
    bottomSheetTheme: _lightBottomSheetTheme,
    switchTheme: _switchTheme,
    sliderTheme: _sliderTheme,
    inputDecorationTheme: _lightInputDecorationTheme,
    textTheme: _textTheme,
  );

  // ─── Tema Oscuro (ideal para proyección) ───
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: AppColors.darkColorScheme,
    scaffoldBackgroundColor: AppColors.darkColorScheme.surface,
    appBarTheme: _darkAppBarTheme,
    cardTheme: _darkCardTheme,
    floatingActionButtonTheme: _fabTheme,
    navigationBarTheme: _navigationBarTheme,
    bottomSheetTheme: _darkBottomSheetTheme,
    switchTheme: _switchTheme,
    sliderTheme: _sliderTheme,
    inputDecorationTheme: _darkInputDecorationTheme,
    textTheme: _textTheme,
  );

  // ─── Tema de Proyección (Display - PC/TV) ───
  // Sin decoraciones, fondo negro puro, texto gigante.
  // Usa un ColorScheme simplificado con colores planos.
  static final ThemeData projectionTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      surface: Colors.black,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.4,
      ),
      displayMedium: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 36,
        color: Colors.white,
        height: 1.6,
      ),
    ),
  );

  // ===========================================================================
  // Component Themes
  // ===========================================================================

  // ─── AppBar ───
  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFF1C1B1F),
    surfaceTintColor: Colors.transparent,
  );

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    foregroundColor: Color(0xFFE6E1E5),
    surfaceTintColor: Colors.transparent,
  );

  // ─── Card ───
  static final CardThemeData _lightCardTheme = CardThemeData(
    elevation: 1,
    color: AppColors.lightColorScheme.surfaceContainer,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  static final CardThemeData _darkCardTheme = CardThemeData(
    elevation: 2,
    color: AppColors.darkColorScheme.surfaceContainer,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  // ─── FAB ───
  static const FloatingActionButtonThemeData _fabTheme =
      FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFCCA43B),
    foregroundColor: Color(0xFF1A1A1A),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    elevation: 4,
    highlightElevation: 8,
  );

  // ─── NavigationBar ───
  static const NavigationBarThemeData _navigationBarTheme =
      NavigationBarThemeData(
    height: 72,
    indicatorColor: Color(0xFF3A2A10),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // ─── BottomSheet — LIGHT ───
  static final BottomSheetThemeData _lightBottomSheetTheme =
      BottomSheetThemeData(
    backgroundColor: AppColors.lightColorScheme.surfaceContainer,
    surfaceTintColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
  );

  // ─── BottomSheet — DARK ───
  static final BottomSheetThemeData _darkBottomSheetTheme =
      BottomSheetThemeData(
    backgroundColor: AppColors.darkColorScheme.surfaceContainer,
    surfaceTintColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
  );

  // ─── Switch ───
  static final SwitchThemeData _switchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFCCA43B);
      }
      return null;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFCCA43B).withValues(alpha: 0.38);
      }
      return null;
    }),
  );

  // ─── Slider ───
  static final SliderThemeData _sliderTheme = SliderThemeData(
    activeTrackColor: const Color(0xFFCCA43B),
    thumbColor: const Color(0xFFCCA43B),
    inactiveTrackColor: const Color(0xFF4A4A4A),
    overlayColor: const Color(0xFFCCA43B).withValues(alpha: 0.12),
    valueIndicatorColor: const Color(0xFFCCA43B),
    valueIndicatorTextStyle: const TextStyle(
      color: Color(0xFF1A1A1A),
    ),
  );

  // ─── InputDecoration — LIGHT ───
  static final InputDecorationTheme _lightInputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightColorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.lightColorScheme.outlineVariant,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFCCA43B),
        width: 2,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.lightColorScheme.outlineVariant,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  // ─── InputDecoration — DARK ───
  static final InputDecorationTheme _darkInputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkColorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.darkColorScheme.outlineVariant,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFCCA43B),
        width: 2,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.darkColorScheme.outlineVariant,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  // ─── TextTheme ───
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.bold,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
  );
}
