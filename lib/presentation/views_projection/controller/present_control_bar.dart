import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/himno_tipo.dart';
import '../../../domain/entities/himno.dart';
import '../../../core/window_manager/window_providers.dart';
import '../../shared_widgets/control_sheets.dart';
import '../../views_personal/providers/audio_providers.dart';
import '../../views_personal/providers/hymn_providers.dart';
import '../providers/live_control_providers.dart';
import '../providers/presentation_providers.dart';

/// Barra de control inferior que se superpone a [HomeScreen] cuando el
/// modo presentación está activo en desktop ([isPresenting] == true).
///
/// Muestra el himno cargado, navegación (anterior/siguiente) y botones
/// de función (brocha, solfa, nota, lupa). Se conecta con
/// [liveControlProvider] y [isPresentingProvider] de Riverpod.
///
/// Estilo: [AnimatedContainer] con [surfaceContainerHigh], bordes
/// redondeados en la parte superior y sombra sutil.
class PresentControlBar extends ConsumerWidget {
  const PresentControlBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final liveState = ref.watch(liveControlProvider);
    final hymn = liveState.hymn;
    final hasHymn = hymn != null;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header: título del himno + salir ──
                _buildHeader(
                  context,
                  ref,
                  colorScheme,
                  textTheme,
                  hymn,
                  hasHymn,
                ),
                const SizedBox(height: 8),
                // ── Navegación ──
                _buildNavigationRow(
                  context,
                  ref,
                  colorScheme,
                  textTheme,
                  liveState,
                ),
                const SizedBox(height: 8),
                // ── Funciones ──
                _buildFunctionRow(
                  context,
                  ref,
                  colorScheme,
                  textTheme,
                  hymn,
                  hasHymn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Himno? hymn,
    bool hasHymn,
  ) {
    return Row(
      children: [
        Icon(
          Icons.music_note_rounded,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasHymn ? hymn!.titulo : 'Selecciona un himno para proyectar',
            style: textTheme.titleSmall?.copyWith(
              color: hasHymn
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _handleExit(context, ref),
          icon: const Icon(Icons.stop_screen_share, size: 18),
          label: const Text('Salir'),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Navegación: Anterior / Siguiente
  // ─────────────────────────────────────────────────────────────

  Widget _buildNavigationRow(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    TextTheme textTheme,
    LiveControlState liveState,
  ) {
    final slide = liveState.currentSlide;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavButton(
          icon: Icons.skip_previous,
          label: 'Anterior',
          onPressed: liveState.hasPrevSlide
              ? () {
                  ref.read(liveControlProvider.notifier).prevSlide();
                  ref
                      .read(windowServiceProvider)
                      .sendMessage({'type': 'PREV_SLIDE'});
                }
              : null,
        ),
        const SizedBox(width: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            slide != null
                ? '${slide.displayLabel} '
                    '${liveState.currentSlideIndex + 1} / ${liveState.slides.length}'
                : '—',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 24),
        _NavButton(
          icon: Icons.skip_next,
          label: 'Siguiente',
          onPressed: liveState.hasNextSlide
              ? () {
                  ref.read(liveControlProvider.notifier).nextSlide();
                  ref
                      .read(windowServiceProvider)
                      .sendMessage({'type': 'NEXT_SLIDE'});
                }
              : null,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Funciones: Brocha, Solfa, Nota, Lupa
  // ─────────────────────────────────────────────────────────────

  Widget _buildFunctionRow(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Himno? hymn,
    bool hasHymn,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _FuncButton(
          icon: Icons.brush,
          label: 'Brocha',
          onPressed: () => showBrushSheet(
            context,
            ref: ref,
          ),
        ),
        _FuncButton(
          icon: Icons.music_note,
          label: 'Solfa',
          onPressed: () => showSolfaSheet(
            context,
            ref: ref,
          ),
        ),
        _FuncButton(
          icon: Icons.audiotrack,
          label: 'Nota',
          onPressed: hasHymn
              ? () => showNoteSheet(
                    context,
                    ref: ref,
                    himnoId: hymn!.id,
                    currentPistaId: null,
                    onPlayPista: (pistaId) =>
                        ref.read(audioRepositoryProvider).play(pistaId),
                    onStop: () =>
                        ref.read(audioRepositoryProvider).stop(),
                  )
              : null,
        ),
        _FuncButton(
          icon: Icons.search,
          label: 'Lupa',
          onPressed: () async {
            if (!hasHymn || hymn == null) return;
            final result = await showSearchSheet(
              context,
              ref: ref,
              currentHimnoId: hymn.id,
            );
            if (result != null && result > 0 && context.mounted) {
              _loadAndProject(ref, result);
            }
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Acciones
  // ─────────────────────────────────────────────────────────────

  /// Carga un himno por ID en [liveControlProvider].
  Future<void> _loadAndProject(WidgetRef ref, int hymnId) async {
    try {
      final repo = ref.read(hymnRepositoryProvider);
      final himno = await repo.getHymnById(hymnId);
      final versionPaisId = himno.primaryVersionPaisId;
      final estrofas = await repo.getStanzas(versionPaisId);
      ref.read(liveControlProvider.notifier).loadHymn(
            himno,
            estrofas,
            versionPaisId: versionPaisId,
          );
    } catch (_) {
      // Error silencioso — el Provider mantiene el himno anterior
    }
  }

  /// Finaliza la presentación: cierra la ventana de proyección y
  /// resetea [isPresentingProvider] a `false`.
  Future<void> _handleExit(BuildContext context, WidgetRef ref) async {
    final windowService = ref.read(windowServiceProvider);
    try {
      await windowService.closeProjectionWindow();
    } catch (_) {
      // Ignorar error si la ventana ya estaba cerrada
    }
    ref.read(isPresentingProvider.notifier).state = false;
    // Resetear el estado del control en vivo cargando un himno vacío
    ref.read(liveControlProvider.notifier).loadHymn(
      const Himno(
        id: 0,
        titulo: '',
        tipo: HimnoTipo.oficial,
        versiones: [],
        categorias: [],
      ),
      [],
    );
  }
}

// ───────────────────────────────────────────────────────────────
// Widgets internos
// ───────────────────────────────────────────────────────────────

/// Botón de navegación (Anterior / Siguiente).
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _NavButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = onPressed == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 32,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            foregroundColor: isDisabled
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDisabled
                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                    : colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// Botón de función (Brocha, Solfa, Nota, Lupa).
class _FuncButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _FuncButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = onPressed == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          iconSize: 24,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            foregroundColor: isDisabled
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDisabled
                    ? colorScheme.onSurface.withValues(alpha: 0.38)
                    : colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
