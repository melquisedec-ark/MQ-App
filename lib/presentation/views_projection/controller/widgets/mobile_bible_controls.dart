import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Panel de navegación bíblica compacto para modo emisor mobile.
///
/// Estilo glassmorphism con [BackdropFilter] y overlay semitransparente.
/// Se muestra únicamente cuando el módulo activo es [ProjectionModule.bible].
///
/// Incluye 4 botones de navegación (capítulo anterior, versículo anterior,
/// versículo siguiente, capítulo siguiente) y un indicador de referencia actual.
///
/// Ejemplo de uso dentro de [MinimalControlScreen] (o similar):
/// ```dart
/// if (liveState.module == ProjectionModule.bible)
///   MobileBibleControlBar(
///     libroNombre: liveState.libroNombre,
///     capitulo: liveState.capitulo,
///     versiculoActual: liveState.versiculoActual,
///     totalVersiculos: liveState.versiculos.length,
///     onPrevChapter: () { /* ... */ },
///     onNextChapter: () { /* ... */ },
///     onPrevVerse: () { /* ... */ },
///     onNextVerse: () { /* ... */ },
///   ),
/// ```
class MobileBibleControlBar extends StatelessWidget {
  final String libroNombre;
  final int capitulo;
  final int versiculoActual;
  final int totalVersiculos;

  final VoidCallback? onPrevChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback? onPrevVerse;
  final VoidCallback? onNextVerse;

  const MobileBibleControlBar({
    super.key,
    required this.libroNombre,
    required this.capitulo,
    required this.versiculoActual,
    required this.totalVersiculos,
    this.onPrevChapter,
    this.onNextChapter,
    this.onPrevVerse,
    this.onNextVerse,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header: icono + referencia ──
                _BibleHeader(
                  libroNombre: libroNombre,
                  capitulo: capitulo,
                  versiculoActual: versiculoActual,
                  totalVersiculos: totalVersiculos,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 10),
                // ── Fila de navegación ──
                _BibleNavigationRow(
                  onPrevChapter: onPrevChapter,
                  onNextChapter: onNextChapter,
                  onPrevVerse: onPrevVerse,
                  onNextVerse: onNextVerse,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────

class _BibleHeader extends StatelessWidget {
  final String libroNombre;
  final int capitulo;
  final int versiculoActual;
  final int totalVersiculos;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _BibleHeader({
    required this.libroNombre,
    required this.capitulo,
    required this.versiculoActual,
    required this.totalVersiculos,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.menu_book_outlined,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$libroNombre $capitulo',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        // Chip con versículo actual
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'v. ${versiculoActual + 1} / $totalVersiculos',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Navegación
// ─────────────────────────────────────────────────────────────────

class _BibleNavigationRow extends StatelessWidget {
  final VoidCallback? onPrevChapter;
  final VoidCallback? onNextChapter;
  final VoidCallback? onPrevVerse;
  final VoidCallback? onNextVerse;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _BibleNavigationRow({
    this.onPrevChapter,
    this.onNextChapter,
    this.onPrevVerse,
    this.onNextVerse,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MobileBibleNavButton(
          icon: Icons.first_page,
          label: 'Cap. ant.',
          onPressed: onPrevChapter,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        _MobileBibleNavButton(
          icon: Icons.navigate_before,
          label: 'Vers. ant.',
          onPressed: onPrevVerse,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        _MobileBibleNavButton(
          icon: Icons.navigate_next,
          label: 'Vers. sig.',
          onPressed: onNextVerse,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        _MobileBibleNavButton(
          icon: Icons.last_page,
          label: 'Cap. sig.',
          onPressed: onNextChapter,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Botón individual
// ─────────────────────────────────────────────────────────────────

class _MobileBibleNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _MobileBibleNavButton({
    required this.icon,
    required this.label,
    this.onPressed,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          if (onPressed != null) {
            HapticFeedback.lightImpact();
            onPressed!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isDisabled
                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                    : colorScheme.onSurface,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: isDisabled
                      ? colorScheme.onSurface.withValues(alpha: 0.38)
                      : colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
