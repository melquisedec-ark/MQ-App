import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/chords/chord_parser.dart';
import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../core/utils/chord_transposer.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/repositories/audio_repository.dart';
import '../../shared_widgets/responsive_chord_widget.dart';
import '../../shared_widgets/adaptive_stanza_text.dart';
import '../../../core/window_manager/window_providers.dart';
import '../../dual_mode_wrapper/dual_mode_providers.dart';
import '../../shared_widgets/control_sheets.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../../views_projection/providers/presentation_providers.dart';
import '../../views_projection/providers/projection_actions.dart'
    show projectHymn;
import '../providers/audio_providers.dart';
import '../../providers/fullscreen_mode_provider.dart';
import '../providers/hymn_providers.dart';
import '../providers/transpose_providers.dart';
import '../providers/arreglo_providers.dart';
import 'arrangement_editor_screen.dart';
import 'fab_menu.dart';

/// Pantalla de detalle del himno (Formato Scroll para móvil).
/// Muestra letra completa con acordes y controles de transposición
/// conectados a Riverpod.
class HymnDetailScreen extends ConsumerStatefulWidget {
  static final _log = Logger('HymnDetailScreen');

  final Himno himno;

  const HymnDetailScreen({
    super.key,
    required this.himno,
  });

  @override
  ConsumerState<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends ConsumerState<HymnDetailScreen>
    with WidgetsBindingObserver {
  bool _isPlaying = false;
  bool _showingArreglo = false;
  int? _currentPistaId;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeKeyFromHymn();
    });
  }

  @override
  void didUpdateWidget(HymnDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.himno.id != widget.himno.id) {
      setState(() => _showingArreglo = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Salir de fullscreen si la app pasa a segundo plano
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        ref.read(fullscreenModeProvider)) {
      ref.read(fullscreenModeProvider.notifier).exitFullscreen();
    }
  }

  void _initializeKeyFromHymn() {
    if (!mounted) return;
    // 1. Usar tonalidad de la BD si está disponible y no es 'C' (default)
    var tonalidad = widget.himno.versiones.firstOrNull?.tonalidadOriginal ?? '';
    if (tonalidad.isEmpty || tonalidad == 'C') {
      // 2. Si no hay tonalidad explícita, detectar del primer acorde del himno
      final primeraEstrofa =
          widget.himno.versiones.firstOrNull?.estrofas.firstOrNull?.contenido ??
              '';
      if (primeraEstrofa.isNotEmpty) {
        final chordRegex = RegExp(r'\[([A-G][#b]?m?)\]');
        final match = chordRegex.firstMatch(primeraEstrofa);
        if (match != null) {
          tonalidad = match.group(1) ?? 'C';
        }
      }
      if (tonalidad.isEmpty) tonalidad = 'C';
    }
    ref.read(transposeValueProvider.notifier).state = 0;
    ref.read(currentKeyProvider.notifier).state = tonalidad;
  }

  /// Presenta el himno actual en la ventana de proyección.
  /// Abre la ventana, carga himno+estrofas, y envía mensaje LOAD_HYMN.
  Future<void> _presentCurrentHymn() async {
    final windowService = ref.read(windowServiceProvider);
    final isPresenting = ref.read(isPresentingProvider);
    try {
      if (!isPresenting) {
        await windowService.openProjectionWindow({
          'mode': 'local',
          'source': 'hymn-detail',
        });
        ref.read(isPresentingProvider.notifier).state = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al presentar: $e')),
        );
      }
      return;
    }

    final error = await projectHymn(ref, widget.himno);
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al presentar: $error')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Presentando: ${widget.himno.titulo}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _playAudio();
    } else {
      _stopAudio();
    }
  }

  /// Activa el modo fullscreen delegando en [fullscreenModeProvider].
  /// El provider se encarga de ocultar la UI del sistema (SystemChrome).
  void _enterMobileFullscreen() {
    ref.read(fullscreenModeProvider.notifier).enterFullscreen();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appearance = ref.watch(hymnAppearanceProvider);
    final transposeValue = ref.watch(transposeValueProvider);
    final transposedKey = ref.watch(transposedKeyProvider);
    final origStanzasAsync = ref.watch(
      stanzasProvider(widget.himno.primaryVersionPaisId),
    );
    final arregloAsync = ref.watch(
      arregloByHymnProvider(widget.himno.primaryVersionPaisId),
    );
    final arreglo = arregloAsync.valueOrNull;
    final hasArreglo = arreglo != null;
    final arregloId = arreglo?.id ?? -1;
    final arregloStanzasAsync =
        ref.watch(arregloEstrofasViewProvider(arregloId));
    final stanzasAsync =
        _showingArreglo ? arregloStanzasAsync : origStanzasAsync;

    final isDesktop = ref.watch(isDesktopModeProvider);
    final isPhone = ref.watch(isPhoneModeProvider);
    final isMobileFullscreen = ref.watch(fullscreenModeProvider);
    final isPresenting = ref.watch(isPresentingProvider);

    // ── Contenido scrollable (extraído para reusar entre desktop y móvil) ──
    final scrollContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cabecera del himno
        _buildHeader(context, widget.himno, colorScheme, textTheme, appearance),
        // Toggle Original / Mi arreglo (solo si hay arreglo del usuario)
        // El toggle solo tiene sentido cuando se muestran acordes,
        // pues el valor del arreglo está en su personalización armónica
        if (hasArreglo && appearance.showChords)
          _buildArregloToggle(colorScheme: colorScheme),
        const SizedBox(height: 24),

        // Renderizado de letra desde provider
        stanzasAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar la letra',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (estrofas) {
            if (estrofas.isEmpty) {
              return Center(
                child: Text(
                  'No hay estrofas disponibles',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            int estrofaCounter = 0;
            return Column(
              children: estrofas.map((estrofa) {
                if (!estrofa.isChorus) estrofaCounter++;
                return _buildStanza(
                  context,
                  estrofa,
                  transposeValue,
                  colorScheme,
                  textTheme,
                  appearance,
                  stanzaNumber: estrofa.isChorus ? null : estrofaCounter,
                );
              }).toList(),
            );
          },
        ),
      ],
    );

    // ── SingleChildScrollView base (con controller en desktop) ──
    final scrollView = SingleChildScrollView(
      controller: isDesktop ? _scrollController : null,
      padding: const EdgeInsets.all(16),
      child: scrollContent,
    );

    // ── En desktop: centrar con ancho máximo de 800px + scrollbar visible ──
    Widget bodyContent;
    if (isDesktop) {
      bodyContent = Center(
        child: SizedBox(
          width: 800,
          child: scrollView,
        ),
      );
    } else {
      bodyContent = scrollView;
    }

    if (isDesktop) {
      bodyContent = Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: bodyContent,
      );
    }

    final showMobileFullscreen = isPhone && isMobileFullscreen;

    return PopScope(
      canPop: !showMobileFullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && showMobileFullscreen) {
          ref.read(fullscreenModeProvider.notifier).exitFullscreen();
        }
      },
      child: Scaffold(
        appBar: showMobileFullscreen
            ? null
            : AppBar(
                title: Text('Himno ${widget.himno.numero ?? ''}'),
                actions: [
                  // ── Botón Presentar (solo desktop) ──
                  if (isDesktop)
                    IconButton(
                      icon: Icon(isPresenting
                          ? Icons.stop_screen_share
                          : Icons.screen_share),
                      tooltip:
                          isPresenting ? 'Detener presentación' : 'Presentar',
                      onPressed: _presentCurrentHymn,
                    ),
                  // Menú de opciones
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'crear-arreglo') {
                        Navigator.pushNamed(
                          context,
                          '/arrangement-editor',
                          arguments: widget.himno,
                        );
                      } else if (value == 'mis-arreglos') {
                        Navigator.pushNamed(
                          context,
                          '/arrangement-list',
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'crear-arreglo',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 12),
                            Text('Crear Arreglo'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'mis-arreglos',
                        child: Row(
                          children: [
                            Icon(Icons.list_alt),
                            SizedBox(width: 12),
                            Text('Mis Arreglos'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: showMobileFullscreen
              ? _buildFullscreenContent(
                  key: const ValueKey('fullscreen'),
                  scrollContent: scrollContent,
                  appearance: appearance,
                )
              : _buildNormalBody(
                  key: const ValueKey('normal'),
                  bodyContent: bodyContent,
                  appearance: appearance,
                  context: context,
                  transposeValue: transposeValue,
                  transposedKey: transposedKey,
                  isPhone: isPhone,
                ),
        ),
        floatingActionButton: showMobileFullscreen
            ? null
            : FabMenu(
                onBrushTap: _showBrochaSheet,
                onNoteTap: _showNotaSheet,
                onSolfaTap: _showSolfaSheet,
                onSearchTap: _showLupaDialog,
              ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Himno himno,
    ColorScheme colorScheme,
    TextTheme textTheme,
    HymnAppearanceState appearance,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Título centrado
        Text(
          himno.titulo,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontFamily: appearance.fontFamily,
            color: appearance.textColor,
            fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        // Etiquetas
        Wrap(
          spacing: 8,
          runAlignment: WrapAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            Chip(
              label: Text(himno.categoria),
              backgroundColor: colorScheme.tertiaryContainer,
              labelStyle: textTheme.labelSmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
              side: BorderSide.none,
            ),
            if (!himno.esOficial)
              Chip(
                label: const Text('Personal'),
                backgroundColor: colorScheme.secondaryContainer,
                labelStyle: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }

  /// Toggle para alternar entre la letra original del himno y el arreglo
  /// personal del usuario.
  Widget _buildArregloToggle({required ColorScheme colorScheme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toggleChip(
            label: 'Original',
            selected: !_showingArreglo,
            colorScheme: colorScheme,
            onTap: () => setState(() => _showingArreglo = false),
          ),
          const SizedBox(width: 8),
          _toggleChip(
            label: 'Mi arreglo',
            selected: _showingArreglo,
            colorScheme: colorScheme,
            onTap: () => setState(() => _showingArreglo = true),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildStanza(
    BuildContext context,
    Estrofa estrofa,
    int transposeValue,
    ColorScheme colorScheme,
    TextTheme textTheme,
    HymnAppearanceState appearance, {
    int? stanzaNumber,
  }  ) {
    final isChorus = estrofa.isChorus;
    final bool useGlass =
        appearance.glassEnabled &&
        appearance.selectedFondo?.tipo == FondoPantallaTipo.imagen;

    final label = Text(
      isChorus ? 'CORO' : 'ESTROFA ${stanzaNumber ?? estrofa.orden}',
      style: (useGlass
              ? textTheme.labelSmall?.copyWith(
                  color: appearance.textColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                )
              : textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )) ??
          const TextStyle(),
    );

    final lyrics = _buildLyricWithChords(
      context,
      estrofa.contenido,
      transposeValue,
      colorScheme,
      textTheme,
      appearance,
    );

    // Sin tarjeta: contenido limpio sobre el vidrio full-screen
    if (useGlass) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: isChorus
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appearance.chordColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [label, const SizedBox(height: 8), lyrics],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [label, const SizedBox(height: 8), lyrics],
              ),
      );
    }

    // Con tarjeta: container blanco semitransparente (modo clásico)
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: appearance.cardOpacity),
        borderRadius: BorderRadius.circular(12),
        border: isChorus
            ? Border.all(
                color: appearance.chordColor.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              estrofa.isChorus
                  ? 'CORO'
                  : 'ESTROFA ${stanzaNumber ?? estrofa.orden}',
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          lyrics,
        ],
      ),
    );
  }

  Widget _buildLyricWithChords(
    BuildContext context,
    String lyric,
    int transposeValue,
    ColorScheme colorScheme,
    TextTheme textTheme,
    HymnAppearanceState appearance,
  ) {
    // Transponer usando el utility ChordTransposer
    final transposedLyric = transposeChordPro(lyric, transposeValue);

    final double baseFontSize =
        (textTheme.bodyLarge?.fontSize ?? 16) * appearance.fontScale;

    // Escala base para texto y acordes
    final double chordFontSize = (baseFontSize * 0.6).clamp(8.0, 13.0);

    // Estilo base de la letra
    final TextStyle lyricStyle =
        (textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontFamily: appearance.fontFamily,
      color: appearance.textColor,
      fontSize: baseFontSize,
      height: 1.6,
      fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
    );

    // Estilo de los acordes
    final TextStyle chordStyle = TextStyle(
      fontFamily: appearance.fontFamily,
      color: appearance.chordColor,
      fontWeight: FontWeight.bold,
      fontSize: chordFontSize,
    );

    // Sin acordes → texto plano adaptativo
    if (!appearance.showChords) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          width: double.infinity,
          child: AdaptiveStanzaText(
            // stripChords conserva los \n, el widget decide si colapsarlos
            text: stripChords(transposedLyric),
            style: lyricStyle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Con acordes → widget Wrap responsivo
    return ResponsiveChordWidget(
      stanza: transposedLyric,
      textStyle: lyricStyle,
      chordStyle: chordStyle,
      lineSpacing: 4,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    int transposeValue,
    String transposedKey,
    bool isPhone,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _isPlaying
            ? _buildPlayerBar(context, colorScheme, textTheme)
            : _buildTransposeBar(context, transposeValue, transposedKey,
                colorScheme, textTheme, isPhone),
      ),
    );
  }

  Widget _buildTransposeBar(
      BuildContext context,
      int transposeValue,
      String transposedKey,
      ColorScheme colorScheme,
      TextTheme textTheme,
      bool isPhone) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reduce gap between buttons on very narrow screens (<360px)
        final gap = constraints.maxWidth < 360 ? 4.0 : 8.0;
        return Row(
          children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => ref
                          .read(transposeValueProvider.notifier)
                          .state = (transposeValue - 1).clamp(-6, 6),
                      icon: const Icon(Icons.remove),
                      tooltip: 'Bajar tono',
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Tono',
                                style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                            Text(transposedKey,
                                style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface)),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref
                          .read(transposeValueProvider.notifier)
                          .state = (transposeValue + 1).clamp(-6, 6),
                      icon: const Icon(Icons.add),
                      tooltip: 'Subir tono',
                    ),
                  ],
                ),
              ),
            ),
            // ── Botón fullscreen (solo móvil, desktop usa F11) ──
            if (isPhone)
              IconButton(
                onPressed: _enterMobileFullscreen,
                icon: const Icon(Icons.fullscreen),
                tooltip: 'Pantalla completa',
                color: colorScheme.onSurfaceVariant,
              ),
            SizedBox(width: gap),
            IconButton.filled(
              onPressed: _togglePlayback,
              icon: const Icon(Icons.play_arrow_rounded),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              tooltip: 'Reproducir audio',
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerBar(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return _AudioPlayerBar(
      key: const ValueKey('player_bar'),
      repo: ref.read(audioRepositoryProvider),
      onStop: _togglePlayback,
    );
  }

  /// Contenido en modo fullscreen móvil.
  /// Sin SafeArea ni padding extra; doble tap para salir.
  Widget _buildFullscreenContent({
    required Key key,
    required Widget scrollContent,
    required HymnAppearanceState appearance,
  }) {
    return GestureDetector(
      key: key,
      onDoubleTap: () =>
          ref.read(fullscreenModeProvider.notifier).exitFullscreen(),
      behavior: HitTestBehavior.translucent,
      child: _FondoBackground(
        key: ValueKey(
            'fondo_bg_${appearance.selectedFondo?.rutaArchivo ?? appearance.selectedFondo?.id}'),
        fondo: appearance.selectedFondo,
        bgColor: appearance.bgColor,
        appearance: appearance,
        // Fullscreen: scroll sin padding para que el contenido ocupe toda la pantalla
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: scrollContent,
        ),
      ),
    );
  }

  /// Contenido normal con fondo, scroll y barra inferior.
  Widget _buildNormalBody({
    required Key key,
    required Widget bodyContent,
    required HymnAppearanceState appearance,
    required BuildContext context,
    required int transposeValue,
    required String transposedKey,
    required bool isPhone,
  }) {
    return Column(
      key: key,
      children: [
        Expanded(
          child: _FondoBackground(
            key: ValueKey(
                'fondo_bg_${appearance.selectedFondo?.rutaArchivo ?? appearance.selectedFondo?.id}'),
            fondo: appearance.selectedFondo,
            bgColor: appearance.bgColor,
            appearance: appearance,
            child: bodyContent,
          ),
        ),
        _buildBottomBar(context, transposeValue, transposedKey, isPhone),
      ],
    );
  }

  @override
  void dispose() {
    // Restaurar SystemChrome al salir de la pantalla (crítico: evitar
    // que el sistema UI quede oculto si se navega estando en fullscreen).
    ref.read(fullscreenModeProvider.notifier).exitFullscreen();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    if (_isPlaying) {
      // Disparar stop sin await — el widget se está destruyendo
      ref.read(audioRepositoryProvider).stop();
      _isPlaying = false;
    }
    super.dispose();
  }

  Future<void> _playAudio([int? pistaId]) async {
    final audioRepo = ref.read(audioRepositoryProvider);
    final himnoId = widget.himno.id;

    // Si no se especificó pista, buscar la primera disponible
    int targetPistaId = pistaId ?? _currentPistaId ?? himnoId;
    if (pistaId == null && _currentPistaId == null) {
      try {
        final pistas = await audioRepo.getByHimno(himnoId);
        if (pistas.isNotEmpty) {
          targetPistaId = pistas.first.id;
        }
      } catch (_) {}
    }

    _currentPistaId = targetPistaId;
    // Activar estado ANTES de reproducir para feedback instantáneo
    if (mounted) setState(() => _isPlaying = true);
    ref.read(isAudioPlayingProvider.notifier).state = true;

    audioRepo.play(targetPistaId).then((_) {
      HymnDetailScreen._log.info(
        'Reproduciendo pista $targetPistaId para himno $himnoId',
      );
    }).catchError((error) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ref.read(isAudioPlayingProvider.notifier).state = false;
      HymnDetailScreen._log.warning('Error al reproducir audio: $error');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$error'.contains('Archivo no encontrado')
                ? 'Archivo no encontrado. Agregue la pista desde Admin > Catálogos > Pistas.'
                : 'No se pudo reproducir el audio',
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Cerrar',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    });
  }

  void _stopAudio() {
    final audioRepo = ref.read(audioRepositoryProvider);
    audioRepo.stop().then((_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ref.read(isAudioPlayingProvider.notifier).state = false;
      HymnDetailScreen._log.info('Audio detenido');
    }).catchError((error) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ref.read(isAudioPlayingProvider.notifier).state = false;
      HymnDetailScreen._log.warning('Error al detener audio: $error');
    });
  }

  // ---------------------------------------------------------------------------
  // FAB — Brocha: Configuración visual (tamaño fuente, color fondo)
  // ---------------------------------------------------------------------------
  void _showBrochaSheet() {
    showBrushSheet(
      context,
      ref: ref,
    );
  }

  // ---------------------------------------------------------------------------
  // FAB — Nota: Panel de pistas de audio
  // ---------------------------------------------------------------------------
  void _showNotaSheet() {
    showNoteSheet(
      context,
      ref: ref,
      himnoId: widget.himno.id,
      currentPistaId: _currentPistaId,
      onPlayPista: (pistaId) {
        _currentPistaId = pistaId;
        _playAudio(pistaId);
      },
      onStop: _stopAudio,
    );
  }

  // ---------------------------------------------------------------------------
  // FAB — Solfa: Panel de músico (transposición, acordes)
  // ---------------------------------------------------------------------------
  void _showSolfaSheet() {
    showSolfaSheet(
      context,
      ref: ref,
      onCreateArrangement: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArrangementEditorScreen(himno: widget.himno),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FAB — Lupa: Diálogo de búsqueda de himnos
  // ---------------------------------------------------------------------------
  Future<void> _showLupaDialog() async {
    final result = await showSearchSheet(
      context,
      ref: ref,
      currentHimnoId: widget.himno.id,
    );

    // Si se seleccionó un himno (distinto del actual), navegar a su detalle
    if (result != null && result > 0 && result != widget.himno.id) {
      if (!mounted) return;
      // Buscar el objeto Himno completo desde el repositorio
      try {
        final himno =
            await ref.read(hymnRepositoryProvider).getHymnById(result);
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/hymn-detail',
            arguments: himno,
          );
        }
      } catch (e) {
        HymnDetailScreen._log.warning('Error al cargar himno desde lupa: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al abrir el himno')),
          );
        }
      }
    }
  }
}

/// Barra de reproducción reactiva: progreso, tiempo y controles.
class _AudioPlayerBar extends StatefulWidget {
  final AudioRepository repo;
  final VoidCallback onStop;

  const _AudioPlayerBar({super.key, required this.repo, required this.onStop});

  @override
  State<_AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<_AudioPlayerBar> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    widget.repo.onDurationChanged.listen((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });
    widget.repo.onPositionChanged.listen((p) {
      if (!_isSliding && mounted) setState(() => _position = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final durationSec = _duration.inSeconds.toDouble();
    final positionSec = _position.inSeconds.toDouble();
    final progress = durationSec > 0 ? positionSec / durationSec : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(_fmt(positionSec),
                style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant, fontSize: 11)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 10),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (v) {
                    setState(() {
                      _isSliding = true;
                    });
                  },
                  onChangeEnd: (v) {
                    widget.repo.seek(Duration(
                        milliseconds: (v * durationSec * 1000).round()));
                    setState(() => _isSliding = false);
                  },
                ),
              ),
            ),
            Text(_fmt(durationSec),
                style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.stop_rounded, size: 28),
              color: colorScheme.error,
              onPressed: widget.onStop,
              tooltip: 'Detener',
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double sec) {
    final t = sec.round();
    return '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}';
  }
}

/// Renderiza el fondo según el tipo seleccionado (color o imagen).
class _FondoBackground extends StatelessWidget {
  final FondoPantalla? fondo;
  final Color bgColor;
  final Widget child;
  final HymnAppearanceState? appearance;

  const _FondoBackground({
    super.key,
    required this.fondo,
    required this.bgColor,
    required this.child,
    this.appearance,
  });

  @override
  Widget build(BuildContext context) {
    if (fondo == null) {
      return SizedBox.expand(child: Container(color: bgColor, child: child));
    }
    return switch (fondo!.tipo) {
      FondoPantallaTipo.colorSolido =>
        SizedBox.expand(child: Container(color: bgColor, child: child)),
      FondoPantallaTipo.imagen => SizedBox.expand(
          child: Stack(
            children: [
              if (fondo!.rutaArchivo != null)
                Positioned.fill(
                  child: Image.file(
                    File(fondo!.rutaArchivo!),
                    key: ValueKey('img_${fondo!.rutaArchivo}'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: bgColor),
                  ),
                ),
              // Full-screen glass overlay
              if (appearance != null &&
                  appearance!.glassEnabled &&
                  fondo!.rutaArchivo != null)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: appearance!.glassBlurSigma,
                        sigmaY: appearance!.glassBlurSigma,
                      ),
                      child: Container(
                        color: appearance!.glassOverlayColor.withValues(
                          alpha: appearance!.cardOpacity.clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
    };
  }
}
