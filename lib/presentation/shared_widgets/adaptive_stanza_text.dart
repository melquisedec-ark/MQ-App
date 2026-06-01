import 'package:flutter/material.dart';

/// Renderiza una estrofa sin acordes de forma adaptativa.
///
/// ## Comportamiento
///
/// 1. Toma el texto de la estrofa (cada verso separado por `\n`).
/// 2. Dentro de un [LayoutBuilder], mide cada verso con [TextPainter]
///    usando el ancho disponible real.
/// 3. **Si todos los versos caben en una linea** (ninguno hace wrap):
///    preserva los saltos de linea originales -> se ve como poesia/versos.
/// 4. **Si algun verso es mas ancho que el contenedor** (hard-wrap):
///    reemplaza TODOS los `\n` por espacios -> texto fluye como parrafo.
///
/// ## Por que
///
/// En himnos, cuando la letra es corta los versos separados se ven mejor.
/// Cuando es larga y de todas formas se corta, un parrafo fluido
/// aprovecha mejor el espacio horizontal.
class AdaptiveStanzaText extends StatelessWidget {
  /// Texto de la estrofa (con `\n` entre versos).
  final String text;

  /// Estilo tipografico (heredado o custom).
  final TextStyle style;

  /// Alineacion horizontal.
  final TextAlign textAlign;

  const AdaptiveStanzaText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final verses = text.split('\n');

    // Si hay 0 o 1 versos no hay decision que tomar
    if (verses.length <= 1) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        softWrap: true,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textScaler = MediaQuery.textScalerOf(context);

        final anyOverflow = verses.any((verse) {
          if (verse.isEmpty) return false;
          final tp = TextPainter(
            text: TextSpan(text: verse, style: style),
            textDirection: Directionality.of(context),
            textScaler: textScaler,
            maxLines: 1,
          )..layout(maxWidth: maxWidth);

          return tp.didExceedMaxLines;
        });

        if (anyOverflow) {
          // Modo parrafo fluido: reemplazar \n por espacios
          return Text(
            text.replaceAll('\n', ' '),
            style: style,
            textAlign: textAlign,
            softWrap: true,
          );
        } else {
          // Modo versos: preservar saltos de linea originales
          return Text(
            text,
            style: style,
            textAlign: textAlign,
            softWrap: true,
          );
        }
      },
    );
  }
}
