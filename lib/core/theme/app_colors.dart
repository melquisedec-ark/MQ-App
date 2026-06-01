import 'package:flutter/material.dart';

/// Constantes de color centralizadas para HimnarioID 2.0.
///
/// Paleta corporativa: Negro, Dorado, Blanco.
/// Todos los colores de la aplicación deben referenciarse desde aquí
/// o desde el [ColorScheme] construido con estas constantes.
class AppColors {
  AppColors._();

  // ─── Dorados corporativos ───
  static const Color gold = Color(0xFFCCA43B);
  static const Color darkGold = Color(0xFF8B7330);

  // ─── Neutros ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color nearWhite = Color(0xFFFEFAF0);
  static const Color black = Color(0xFF000000);
  static const Color nearBlack = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkSurfaceDim = Color(0xFF0A0A0A);

  // ─── Dark Mode ColorScheme ───
  // Fondo negro puro (#000000), contraste óptimo sobre fondo oscuro.
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFCCA43B),
    onPrimary: Color(0xFF1A1A1A),
    primaryContainer: Color(0xFF4A3A10),
    onPrimaryContainer: Color(0xFFE8D48B),
    secondary: Color(0xFF8B7355),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF3A2A10),
    onSecondaryContainer: Color(0xFFE8D48B),
    tertiary: Color(0xFF6B8B8B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF1A2A2A),
    onTertiaryContainer: Color(0xFFB0D0D0),
    error: Color(0xFFCF6679),
    onError: Color(0xFF000000),
    errorContainer: Color(0xFF4A1520),
    onErrorContainer: Color(0xFFF0B0B8),
    surface: Color(0xFF000000),
    onSurface: Color(0xFFE6E1E5),
    surfaceDim: Color(0xFF000000),
    surfaceBright: Color(0xFF1A1A1A),
    surfaceContainerLowest: Color(0xFF050505),
    surfaceContainerLow: Color(0xFF0F0F0F),
    surfaceContainer: Color(0xFF1A1A1A),
    surfaceContainerHigh: Color(0xFF252525),
    surfaceContainerHighest: Color(0xFF303030),
    onSurfaceVariant: Color(0xFFC4C0C8),
    outline: Color(0xFF8B8B8B),
    outlineVariant: Color(0xFF4A4A4A),
    shadow: Color(0xFF000000),
    scrim: Color(0xCC000000),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF1C1B1F),
    inversePrimary: Color(0xFF8B7330),
    surfaceTint: Color(0xFFCCA43B),
  );

  // ─── Light Mode ColorScheme ───
  // Fondo blanco puro (#FFFFFF), tarjetas y contenedores sólidos.
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF8B7330),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8D48B),
    onPrimaryContainer: Color(0xFF2A1F08),
    secondary: Color(0xFF6B5335),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF0E0C0),
    onSecondaryContainer: Color(0xFF2A1F08),
    tertiary: Color(0xFF4A6B6B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD0E8E8),
    onTertiaryContainer: Color(0xFF0A1A1A),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF0D0D0),
    onErrorContainer: Color(0xFF3A0A0A),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1B1F),
    surfaceDim: Color(0xFFE0DCD6),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8F5F2),
    surfaceContainer: Color(0xFFF0EDEA),
    surfaceContainerHigh: Color(0xFFE8E5E2),
    surfaceContainerHighest: Color(0xFFE0DDDA),
    onSurfaceVariant: Color(0xFF4A4A4A),
    outline: Color(0xFF7A7A7A),
    outlineVariant: Color(0xFFC4C0BC),
    shadow: Color(0xFF000000),
    scrim: Color(0x66000000),
    inverseSurface: Color(0xFF333333),
    onInverseSurface: Color(0xFFE6E1E5),
    inversePrimary: Color(0xFFCCA43B),
    surfaceTint: Color(0xFF8B7330),
  );
}
