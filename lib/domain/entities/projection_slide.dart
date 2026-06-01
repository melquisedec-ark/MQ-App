import 'package:freezed_annotation/freezed_annotation.dart';
import 'estrofa.dart';
import 'himno.dart';

part 'projection_slide.freezed.dart';

/// Representa una diapositiva (slide) en el flujo de presentación.
///
/// El flujo completo de un himno se compone de:
/// 1. [TitleSlide]: Título + número del himno (full screen, centrado)
/// 2. [LyricsSlide]: Letra de cada estrofa (una por slide, máximo tamaño)
/// 3. [AmenSlide]: "Amén" al final (centrado, full screen)
@freezed
sealed class ProjectionSlide with _$ProjectionSlide {
  const ProjectionSlide._();

  /// Slide 0: Título + número del himno.
  const factory ProjectionSlide.title({required Himno himno}) = TitleSlide;

  /// Slides 1..N-1: Letra de una estrofa.
  const factory ProjectionSlide.lyrics({required Estrofa estrofa}) = LyricsSlide;

  /// Slide N: "Amén" al final.
  const factory ProjectionSlide.amen() = AmenSlide;

  /// Etiqueta textual para identificar el tipo de slide en la UI.
  String get displayLabel => switch (this) {
        TitleSlide() => 'Portada',
        LyricsSlide() => 'Letra',
        AmenSlide() => 'Amén',
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
