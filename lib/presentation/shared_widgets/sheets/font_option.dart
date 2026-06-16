import 'package:flutter/material.dart';

// =============================================================================
// FontOption — Selector visual de fuente tipográfica
// =============================================================================

/// Widget reutilizable para seleccionar una fuente tipográfica.
/// Muestra una tarjeta con el nombre de la fuente y un preview.
class FontOption extends StatelessWidget {
  final String family;
  final String label;
  final String previewText;
  final bool isSelected;
  final VoidCallback onTap;

  const FontOption({
    super.key,
    required this.family,
    required this.label,
    required this.previewText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: family,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              previewText,
              style: TextStyle(
                fontFamily: family,
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}