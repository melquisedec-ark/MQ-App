import 'package:freezed_annotation/freezed_annotation.dart';
import 'estrofa.dart';
import 'himno.dart';

part 'projection_slide.freezed.dart';

/// Representa una diapositiva (slide) en el flujo de presentación.
///
/// Flujo de himnario:
/// 1. [TitleSlide]: Título + número del himno (full screen, centrado)
/// 2. [LyricsSlide]: Letra de cada estrofa (una por slide, máximo tamaño)
/// 3. [AmenSlide]: "Amén" al final (centrado, full screen)
///
/// Flujo de biblia:
/// 1. [BibleTitleSlide]: Libro + capítulo (full screen, centrado)
/// 2. [VerseSlide]: Versículo individual con texto y referencia
/// 3. [BibleEndSlide]: Fin de capítulo (centrado, full screen)
@freezed
sealed class ProjectionSlide with _$ProjectionSlide {
  const ProjectionSlide._();

  // ── Himnario ────────────────────────────────────────────────

  /// Slide 0: Título + número del himno.
  const factory ProjectionSlide.title({required Himno himno}) = TitleSlide;

  /// Slides 1..N-1: Letra de una estrofa.
  const factory ProjectionSlide.lyrics({required Estrofa estrofa}) = LyricsSlide;

  /// Slide N: "Amén" al final.
  const factory ProjectionSlide.amen() = AmenSlide;

  // ── Biblia ──────────────────────────────────────────────────

  /// Slide de título de libro/capítulo bíblico.
  const factory ProjectionSlide.bibleTitle({
    required String libroNombre,
    required int capitulo,
  }) = BibleTitleSlide;

  /// Slide de versículo individual con texto y referencia.
  const factory ProjectionSlide.verse({
    required int numero,
    required String texto,
    required String referencia,
    required int totalVersiculos,
  }) = VerseSlide;

  /// Slide de fin de capítulo bíblico.
  const factory ProjectionSlide.bibleEnd({
    required String libroNombre,
    required int capitulo,
  }) = BibleEndSlide;

  /// Etiqueta textual para identificar el tipo de slide en la UI.
  String get displayLabel => switch (this) {
        TitleSlide() => 'Portada',
        LyricsSlide() => 'Letra',
        AmenSlide() => 'Amén',
        BibleTitleSlide() => 'Título',
        VerseSlide() => 'Versículo',
        BibleEndSlide() => 'Fin',
      };
}

/// Extension de helpers para [TitleSlide].
extension TitleSlideHelpers on TitleSlide {
  /// Título del himno desde el slide de portada.
  String get titulo => himno.titulo;

  /// Número del himno desde el slide de portada.
  int? get numero => himno.numero;
}

/// Extension de helpers para [LyricsSlide].
extension LyricsSlideHelpers on LyricsSlide {
  /// Contenido ChordPro de la estrofa.
  String get contenido => estrofa.contenido;

  /// `true` si la estrofa es un coro.
  bool get isChorus => estrofa.isChorus;
}

/// Extension de helpers para [BibleTitleSlide].
extension BibleTitleSlideHelpers on BibleTitleSlide {
  /// Referencia formateada: "Génesis 1".
  String get referencia => '$libroNombre $capitulo';
}

/// Extension de helpers para [VerseSlide].
extension VerseSlideHelpers on VerseSlide {
  /// Progreso del versículo: "1/31".
  String get progreso => '$numero/$totalVersiculos';
}

/// Extension de helpers para [BibleEndSlide].
extension BibleEndSlideHelpers on BibleEndSlide {
  /// Referencia formateada: "Génesis 1 — Fin".
  String get referencia => '$libroNombre $capitulo — Fin';
}
