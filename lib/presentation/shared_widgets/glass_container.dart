import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Panel con efecto glassmorphism (vidrio esmerilado).
///
/// Aplica un [BackdropFilter] con [ImageFilter.blur] sobre el fondo,
/// con un overlay semitransparente para garantizar legibilidad del contenido.
///
/// Ideal para superponer texto sobre imágenes de fondo en proyección.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final Color overlayColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Widget? background;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 10.0,
    this.opacity = 0.25,
    this.overlayColor = Colors.black,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.border,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (background != null) background!,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                margin: margin,
                padding: padding,
                decoration: BoxDecoration(
                  color: overlayColor.withValues(alpha: opacity),
                  border: border,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
