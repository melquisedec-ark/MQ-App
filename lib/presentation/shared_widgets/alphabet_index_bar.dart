import 'package:flutter/material.dart';

/// Barra lateral alfabética (A-Z) que permite saltar a himnos
/// por la primera letra de su título.
///
/// Soporta:
/// - Tap en una letra → llama a [onLetterSelected]
/// - Arrastrar el dedo sobre la barra → llama a [onLetterSelected] continuamente
///
/// Solo se muestra cuando el orden de la lista es A-Z o Z-A.
class AlphabetIndexBar extends StatelessWidget {
  final ValueChanged<String> onLetterSelected;
  final Color? textColor;
  final double fontSize;

  static const List<String> letters = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
    'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z',
  ];

  const AlphabetIndexBar({
    super.key,
    required this.onLetterSelected,
    this.textColor,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultColor = textColor ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return GestureDetector(
      onTapUp: (details) {
        _onTapAtPosition(details.localPosition, context, defaultColor);
      },
      onPanUpdate: (details) {
        _onTapAtPosition(details.localPosition, context, defaultColor);
      },
      child: Container(
        width: 24,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: letters.map((letter) {
            return Expanded(
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: defaultColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _onTapAtPosition(Offset position, BuildContext context, Color defaultColor) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final letterIndex = (position.dy / size.height * letters.length).floor().clamp(0, letters.length - 1);
    onLetterSelected(letters[letterIndex]);
  }
}
