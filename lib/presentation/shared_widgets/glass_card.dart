import 'package:flutter/material.dart';

/// Tarjeta sólida que usa los colores del tema.
///
/// Reemplaza el anterior GlassCard (efecto glassmorphism).
/// Sin transparencias ni degradados — color sólido puro con contraste óptimo.
///
/// Usa [Card] de Material internamente, heredando [CardThemeData] del tema.
class GlassCard extends StatelessWidget {
  /// Widget hijo de la tarjeta.
  final Widget child;

  /// Callback al presionar la tarjeta.
  final VoidCallback? onTap;

  /// Radio de las esquinas.
  final double borderRadius;

  /// Padding interno.
  final EdgeInsetsGeometry padding;

  /// Margen externo.
  final EdgeInsetsGeometry? margin;

  /// Si es `true`, usa el borde dorado en lugar del color por defecto.
  final bool goldBorder;

  /// Color de fondo sólido. Por defecto usa [ColorScheme.surfaceContainer].
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.goldBorder = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        backgroundColor ?? colorScheme.surfaceContainer;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: goldBorder
          ? BorderSide(color: colorScheme.primary, width: 1.5)
          : BorderSide.none,
    );

    final card = Card(
      color: bgColor,
      elevation: 1,
      margin: margin ?? EdgeInsets.zero,
      shape: shape,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}
