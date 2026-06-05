import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/entities/projection_slide.dart';
import 'presentation_providers.dart';

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
///   Himnario: Slide 0: [TÍTULO + NÚMERO] → Slide 1..N: [LETRA ESTROFA] → Slide N+1: ["AMÉN"]
///   Biblia:   Slide 0: [LIBRO + CAPÍTULO] → Slide 1..N: [VERSÍCULO] → Slide N+1: ["FIN"]
class LiveControlState {
  final Himno? hymn;
  final List<ProjectionSlide> slides;
  final int currentSlideIndex;
  final bool isBlackout;
  final int? versionPaisId;

  // Bible fields
  final ProjectionModule module;
  final List<String> versiculos;
  final String libroNombre;
  final int capitulo;
  final int versiculoActual;
  final String bibleTheme;
  final double bibleFontScale;

  const LiveControlState({
    this.hymn,
    this.slides = const [],
    this.currentSlideIndex = 0,
    this.isBlackout = false,
    this.versionPaisId,
    this.module = ProjectionModule.hymnal,
    this.versiculos = const <String>[],
    this.libroNombre = '',
    this.capitulo = 0,
    this.versiculoActual = 0,
    this.bibleTheme = 'papel',
    this.bibleFontScale = 1.0,
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
    ProjectionModule? module,
    List<String>? versiculos,
    String? libroNombre,
    int? capitulo,
    int? versiculoActual,
    String? bibleTheme,
    double? bibleFontScale,
  }) {
    return LiveControlState(
      hymn: hymn ?? this.hymn,
      slides: slides ?? this.slides,
      currentSlideIndex: currentSlideIndex ?? this.currentSlideIndex,
      isBlackout: isBlackout ?? this.isBlackout,
      versionPaisId: versionPaisId ?? this.versionPaisId,
      module: module ?? this.module,
      versiculos: versiculos ?? this.versiculos,
      libroNombre: libroNombre ?? this.libroNombre,
      capitulo: capitulo ?? this.capitulo,
      versiculoActual: versiculoActual ?? this.versiculoActual,
      bibleTheme: bibleTheme ?? this.bibleTheme,
      bibleFontScale: bibleFontScale ?? this.bibleFontScale,
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

  // ── Métodos bíblicos ──────────────────────────────────────

  /// Carga un capítulo bíblico completo para proyección.
  void loadBibleChapter({
    required String libroNombre,
    required int capitulo,
    required List<String> versiculos,
  }) {
    state = state.copyWith(
      module: ProjectionModule.bible,
      libroNombre: libroNombre,
      capitulo: capitulo,
      versiculos: versiculos,
      versiculoActual: 0,
      currentSlideIndex: 0,
      slides: _buildBibleSlides(libroNombre, capitulo, versiculos),
    );
  }

  /// Construye slides bíblicos: título + versículos + fin.
  List<ProjectionSlide> _buildBibleSlides(
    String libro, int cap, List<String> versos,
  ) {
    final slides = <ProjectionSlide>[
      ProjectionSlide.bibleTitle(libroNombre: libro, capitulo: cap),
      ...versos.asMap().entries.map((e) => ProjectionSlide.verse(
        numero: e.key + 1,
        texto: e.value,
        referencia: '$libro $cap:${e.key + 1}',
        totalVersiculos: versos.length,
      )),
      ProjectionSlide.bibleEnd(libroNombre: libro, capitulo: cap),
    ];
    return slides;
  }

  /// Cambia tema bíblico en proyección.
  void setBibleTheme(String theme) {
    state = state.copyWith(bibleTheme: theme);
  }

  /// Cambia escala de fuente bíblica en proyección.
  void setBibleFontScale(double scale) {
    state = state.copyWith(bibleFontScale: scale.clamp(0.8, 4.0));
  }
}
