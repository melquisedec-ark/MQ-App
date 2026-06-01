import 'package:flutter/material.dart';

import '../../core/chords/chord_segment.dart';
import '../../core/chords/chord_parser.dart';

/// Renderiza texto ChordPro con acordes sobre la letra usando Wrap.
///
/// [stanza] es el texto ChordPro (multilínea) de la estrofa.
/// [textStyle] estilo base para la letra (tamaño, color, etc.).
/// [chordStyle] estilo para los acordes (tamaño, color, negrita).
/// [lineSpacing] espacio extra entre líneas de la estrofa.
/// [textAlign] alineación horizontal de la letra (null → left).
/// [runAlignment] alineación vertical de las líneas en el Wrap.
/// [debug] si true, pinta bordes de cada segmento (útil para depuración).
///
/// Diseño:
/// - Cada [ChordSegment] se renderiza con acorde arriba y texto abajo.
/// - [ChordSegment.isLineBreak] fuerza salto de línea real con [lineSpacing].
/// - Usa [Wrap] nativo → reflow automático en cualquier ancho.
/// - Stack + Positioned evita que acordes anchos estiren la columna.
class ResponsiveChordWidget extends StatelessWidget {
  final String stanza;
  final TextStyle? textStyle;
  final TextStyle? chordStyle;
  final double lineSpacing;
  final TextAlign? textAlign;
  final WrapAlignment runAlignment;
  final bool debug;

  const ResponsiveChordWidget({
    super.key,
    required this.stanza,
    this.textStyle,
    this.chordStyle,
    this.lineSpacing = 8.0,
    this.textAlign,
    this.runAlignment = WrapAlignment.start,
    this.debug = false,
  });

  TextStyle get _effectiveTextStyle =>
      textStyle ?? const TextStyle(fontSize: 16, color: Colors.black87);

  TextStyle get _effectiveChordStyle =>
      chordStyle ??
      const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFFCCA43B),
      );

  @override
  Widget build(BuildContext context) {
    final segments = parseChordProStanza(stanza);
    if (stanza.trim().isEmpty) return const SizedBox.shrink();

    final children = segments.map((segment) {
      if (segment.isLineBreak) {
        return _LineBreakPlaceholder(lineSpacing: lineSpacing);
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack permite que el acorde flote sin estirar el ancho
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Dummy invisible — reserva altura, ancho mínimo
              Text(' ',
                style: _effectiveChordStyle.copyWith(
                  height: 1.1, color: Colors.transparent,
                ),
              ),
              if (segment.chord != null)
                Positioned(
                  left: 0, top: 0,
                  child: Text(segment.chord!,
                    style: _effectiveChordStyle.copyWith(height: 1.1),
                  ),
                ),
            ],
          ),
          // Letra — dicta el ancho real de la Column
          segment.text.isNotEmpty
              ? Text(segment.text,
                  style: _effectiveTextStyle.copyWith(height: 1.1),
                  textAlign: textAlign,
                )
              : const SizedBox(height: 0),
        ],
      );
    }).toList();

    return Wrap(
      spacing: 0.0,
      runSpacing: lineSpacing,
      alignment: textAlign == TextAlign.center
          ? WrapAlignment.center
          : textAlign == TextAlign.right
              ? WrapAlignment.end
              : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.end,
      runAlignment: runAlignment,
      children: children,
    );
  }
}

/// Marcador invisible que fuerza un salto de línea real en Wrap.
///
/// Usa una [SizedBox] con ancho infinito para romper la línea actual.
class _LineBreakPlaceholder extends StatelessWidget {
  final double lineSpacing;
  const _LineBreakPlaceholder({required this.lineSpacing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: lineSpacing,
    );
  }
}
