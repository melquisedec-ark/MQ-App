import 'package:flutter/material.dart';

/// Modo de vista del lector bíblico.
enum BibleReaderViewMode {
  /// Un versículo a la vez (vista por defecto, navegación con flechas).
  verse,

  /// Capítulo completo visible, scroll con `ScrollablePositionedList`.
  chapter,
}

/// Tarjeta de versículo compacta para la vista de capítulo.
///
/// Layout: número gold a la izquierda (32dp) + texto a la derecha con
/// `bodyLarge` (18sp) y line-height 1.6 del sistema. Si [esFoco] es
/// `true`, el fondo usa `surfaceContainerHigh` con elevación 1.
///
/// Los parámetros [fontFamily], [textColor] y [lineHeight] permiten
/// personalizar la apariencia desde [ReadingSettingsSheet].
class VerseCard extends StatelessWidget {
  const VerseCard({
    super.key,
    required this.numero,
    required this.texto,
    this.esFoco = false,
    this.onTap,
    this.onLongPress,
    this.notaIndicatorColor,
    this.fontFamily,
    this.textColor,
    this.lineHeight,
  });

  /// Número del versículo (1, 2, 3, ...).
  final int numero;

  /// Texto completo del versículo.
  final String texto;

  /// Si es `true`, muestra un fondo elevado que destaca el versículo.
  final bool esFoco;

  /// Callback al tap normal.
  final VoidCallback? onTap;

  /// Callback al long press.
  final VoidCallback? onLongPress;

  /// Color del indicador de nota (si no es null, muestra un dot 14×14).
  final Color? notaIndicatorColor;

  /// Familia tipográfica opcional (null = system default).
  final String? fontFamily;

  /// Color del texto opcional (null = default del tema).
  final Color? textColor;

  /// Altura de línea opcional (null = 1.6).
  final double? lineHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: esFoco ? colorScheme.surfaceContainerHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(esFoco ? 8 : 0),
        border: esFoco
            ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número gold a la izquierda
          SizedBox(
            width: 32,
            child: Text(
              '$numero',
              style: textTheme.titleSmall?.copyWith(
                color: const Color(0xFFCCA43B),
                fontWeight: FontWeight.w700,
                fontFamily:
                    fontFamily == 'system' ? null : fontFamily,
              ),
            ),
          ),
          // Indicador de nota (14×14)
          if (notaIndicatorColor != null) ...[
            const SizedBox(width: 4),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: notaIndicatorColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
          const SizedBox(width: 8),
          // Texto del versículo
          Expanded(
            child: Text(
              texto,
              style: textTheme.bodyLarge?.copyWith(
                height: lineHeight ?? 1.6,
                fontWeight: esFoco ? FontWeight.w500 : FontWeight.w400,
                color: textColor,
                fontFamily:
                    fontFamily == 'system' ? null : fontFamily,
              ),
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      ),
    );
  }
}
