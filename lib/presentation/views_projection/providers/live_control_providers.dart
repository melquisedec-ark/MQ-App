import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/entities/projection_slide.dart';

// ═══════════════════════════════════════════════════════════════
// Providers independientes
// ═══════════════════════════════════════════════════════════════

/// Provider que indica si la pantalla está en modo blackout.
final isBlackoutProvider = StateProvider<bool>((ref) => false);

/// Provider que retorna el slide actual de la proyección.
final currentSlideProvider = Provider<ProjectionSlide?>((ref) {
  return ref.watch(liveControlProvider).currentSlide;
});

// ═══════════════════════════════════════════════════════════════
// LiveControlProvider (StateNotifier)
// ═══════════════════════════════════════════════════════════════

/// Notifier para controlar la navegación entre estrofas.
final liveControlProvider =
    StateNotifierProvider<LiveControlNotifier, LiveControlState>((ref) {
  return LiveControlNotifier();
});

// ═══════════════════════════════════════════════════════════════
// LiveControlState
// ═══════════════════════════════════════════════════════════════

/// Estado completo del control en vivo.
///
/// Modela el flujo de presentación basado en [ProjectionSlide]:
///   Slide 0:  [TÍTULO + NÚMERO]
///   Slide 1:  [LETRA ESTROFA 1]
///   ...
///   Slide N:  ["AMÉN"]
class LiveControlState {
  final Himno? hymn;
  final List<ProjectionSlide> slides;
  final int currentSlideIndex;
  final bool isBlackout;
  final int? versionPaisId;

  const LiveControlState({
    this.hymn,
    this.slides = const [],
    this.currentSlideIndex = 0,
    this.isBlackout = false,
    this.versionPaisId,
  });

  // ── Getters del nuevo modelo ───────────────────────────────

  /// Slide actual de la presentación.
  ProjectionSlide? get currentSlide =>
      slides.isNotEmpty && currentSlideIndex < slides.length
          ? slides[currentSlideIndex]
          : null;

  /// `true` si existe un slide siguiente al actual.
  bool get hasNextSlide => currentSlideIndex < slides.length - 1;

  /// `true` si existe un slide anterior al actual.
  bool get hasPrevSlide => currentSlideIndex > 0;

  /// Total de slides en la presentación.
  int get slideCount => slides.length;

  /// Slide siguiente (si existe).
  ProjectionSlide? get nextSlide =>
      hasNextSlide ? slides[currentSlideIndex + 1] : null;

  /// Slide anterior (si existe).
  ProjectionSlide? get prevSlide =>
      hasPrevSlide ? slides[currentSlideIndex - 1] : null;

  // ── copyWith ───────────────────────────────────────────────

  LiveControlState copyWith({
    Himno? hymn,
    List<ProjectionSlide>? slides,
    int? currentSlideIndex,
    bool? isBlackout,
    int? versionPaisId,
  }) {
    return LiveControlState(
      hymn: hymn ?? this.hymn,
      slides: slides ?? this.slides,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
      isBlackout: isBlackout ?? this.isBlackout,
      versionPaisId: versionPaisId ?? this.versionPaisId,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LiveControlNotifier
// ═══════════════════════════════════════════════════════════════

/// Notifier que maneja la navegación en vivo.
class LiveControlNotifier extends StateNotifier<LiveControlState> {
  LiveControlNotifier() : super(const LiveControlState());

  // ── Construcción de slides ─────────────────────────────────

  /// Construye la lista completa de [ProjectionSlide] a partir
  /// de un [Himno] y sus [Estrofa]s.
  ///
  /// Retorna: `[TitleSlide, ...LyricsSlide..., AmenSlide]`
  List<ProjectionSlide> _buildSlides(Himno hymn, List<Estrofa> stanzas) {
    return [
      ProjectionSlide.title(himno: hymn),
      ...stanzas.map((e) => ProjectionSlide.lyrics(estrofa: e)),
      const ProjectionSlide.amen(),
    ];
  }

  // ── Métodos del nuevo modelo ───────────────────────────────

  /// Carga un himno para proyección.
  void loadHymn(Himno hymn, List<Estrofa> stanzas, {int? versionPaisId}) {
    state = LiveControlState(
      hymn: hymn,
      slides: _buildSlides(hymn, stanzas),
      currentSlideIndex: 0,
      isBlackout: false,
      versionPaisId: versionPaisId ?? hymn.primaryVersionPaisId,
    );
  }

  /// Avanza al siguiente slide.
  void nextSlide() {
    if (state.hasNextSlide) {
      state = state.copyWith(
        currentSlideIndex: state.currentSlideIndex + 1,
        isBlackout: false,
      );
    }
  }

  /// Retrocede al slide anterior.
  void prevSlide() {
    if (state.hasPrevSlide) {
      state = state.copyWith(
        currentSlideIndex: state.currentSlideIndex - 1,
        isBlackout: false,
      );
    }
  }

  /// Va a un slide específico por índice.
  void goToSlide(int index) {
    if (index >= 0 && index < state.slides.length) {
      state = state.copyWith(
        currentSlideIndex: index,
        isBlackout: false,
      );
    }
  }

  /// Va al primer coro disponible (busca en [LyricsSlide]).
  void goToChorus() {
    final chorusIndex = state.slides.indexWhere(
      (s) => s is LyricsSlide && s.estrofa.isChorus,
    );
    if (chorusIndex != -1) {
      state = state.copyWith(
        currentSlideIndex: chorusIndex,
        isBlackout: false,
      );
    }
  }

  /// Va al inicio de la presentación (Slide 0: título).
  void goToStart() {
    state = state.copyWith(
      currentSlideIndex: 0,
      isBlackout: false,
    );
  }

  /// Va al primer slide de letra (Slide 1).
  void goToFirstLyrics() {
    if (state.slides.length >= 2) {
      state = state.copyWith(
        currentSlideIndex: 1,
        isBlackout: false,
      );
    }
  }

  // ── Blackout ───────────────────────────────────────────────

  /// Activa/desactiva el modo blackout.
  void toggleBlackout() {
    state = state.copyWith(isBlackout: !state.isBlackout);
  }

  /// Apaga la pantalla.
  void blackout() {
    state = state.copyWith(isBlackout: true);
  }

  /// Actualiza el estado completo desde una fuente externa (p.ej. servidor gRPC).
  void updateFromServer(LiveControlState newState) {
    state = newState;
  }
}
