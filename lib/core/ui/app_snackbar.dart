import 'package:flutter/material.dart';

/// Tipos semánticos de SnackBar con colores predefinidos.
enum AppSnackBarType {
  /// Notificación neutral (default). Usa colores del tema inverso.
  info,

  /// Confirmación de éxito (verde).
  success,

  /// Error (color error del tema).
  error,

  /// Advertencia (naranja).
  warning,
}

/// Muestra un SnackBar consistente y centrado con auto-dismiss.
///
/// Características (D5):
/// - Anti-stacking: oculta y limpia snackbars pendientes antes de mostrar
/// - Duración por defecto: 3 segundos (vs 4s default de Flutter)
/// - `behavior: SnackBarBehavior.fixed` (M3 default)
/// - Soporta `action` opcional (Deshacer, Reintentar)
/// - 4 tipos semánticos con colores predefinidos
///
/// Usar SIEMPRE este helper en vez de llamar a
/// [ScaffoldMessenger.showSnackBar] directamente.
void showAppSnackBar(
  BuildContext ctx,
  String message, {
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
  AppSnackBarType type = AppSnackBarType.info,
}) {
  final messenger = ScaffoldMessenger.of(ctx);
  messenger.hideCurrentSnackBar();
  messenger.clearSnackBars();
  final colorScheme = Theme.of(ctx).colorScheme;
  final (Color bg, Color fg) = switch (type) {
    AppSnackBarType.success => (const Color(0xFF2E7D32), Colors.white),
    AppSnackBarType.error => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer
      ),
    AppSnackBarType.warning => (const Color(0xFFEF6C00), Colors.white),
    AppSnackBarType.info => (
        colorScheme.inverseSurface,
        colorScheme.onInverseSurface
      ),
  };
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: fg)),
      backgroundColor: bg,
      duration: duration,
      behavior: SnackBarBehavior.fixed,
      action: action,
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}
