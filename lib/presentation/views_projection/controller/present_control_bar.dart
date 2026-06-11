import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';

import '../../../core/enums/himno_tipo.dart';
import '../../../core/network/connection_state.dart';
import '../../../domain/entities/himno.dart';
import '../../../core/window_manager/window_providers.dart';
import '../../shared_widgets/control_sheets.dart';
import '../../views_personal/providers/audio_providers.dart';
import '../../views_personal/providers/hymn_providers.dart';
import '../providers/connection_providers.dart';
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
    final liveState = ref.watch(liveControlProvider);
    return Row(
      children: [
        Icon(
          liveState.module == ProjectionModule.bible
              ? Icons.menu_book_outlined
              : Icons.music_note_rounded,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasHymn
                ? hymn!.titulo
                : liveState.module == ProjectionModule.bible
                    ? '${liveState.libroNombre} ${liveState.capitulo}'
                    : 'Selecciona contenido para proyectar',
            style: textTheme.titleSmall?.copyWith(
              color: hasHymn || liveState.module == ProjectionModule.bible
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
  
  /// Envía comando al subproceso local (WindowService) y también por gRPC
  /// si está conectado como emisor a un display remoto.
  void _sendNavCommand(WidgetRef ref, String type, {VoidCallback? gRPCAction}) {
    // Local: subproceso de proyección
    ref.read(windowServiceProvider).sendMessage({'type': type});
    // Remoto: display gRPC si estamos en modo emisor
    final role = ref.read(connectionRoleProvider);
    if (role == ConnectionRole.emitter && gRPCAction != null) {
      gRPCAction();
    }
  }

  Widget _buildNavigationRow(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    TextTheme textTheme,
    LiveControlState liveState,
  ) {
    final slide = liveState.currentSlide;
    final isBible = liveState.module == ProjectionModule.bible;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavButton(
          icon: Icons.skip_previous,
          label: isBible ? 'Anterior' : 'Anterior',
          onPressed: liveState.hasPrevSlide
              ? () {
                  ref.read(liveControlProvider.notifier).prevSlide();
                  _sendNavCommand(ref, 'PREV_SLIDE',
                    gRPCAction: () =>
                        ref.read(controlDataSourceProvider).sendPrevStanza(),
                  );
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
                    '${slide.displayNumber > 0 ? slide.displayNumber : liveState.currentSlideIndex + 1} / ${liveState.slides.length}'
                : isBible
                    ? '${liveState.libroNombre} ${liveState.capitulo}'
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
          label: isBible ? 'Siguiente' : 'Siguiente',
          onPressed: liveState.hasNextSlide
              ? () {
                  ref.read(liveControlProvider.notifier).nextSlide();
                  _sendNavCommand(ref, 'NEXT_SLIDE',
                    gRPCAction: () =>
                        ref.read(controlDataSourceProvider).sendNextStanza(),
                  );
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
    final liveState = ref.watch(liveControlProvider);
    final isBible = liveState.module == ProjectionModule.bible;

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
        if (isBible)
          // En modo Biblia: Lupa abre el selector de libros para buscar
          _FuncButton(
            icon: Icons.search,
            label: 'Buscar',
            onPressed: () => appRouter.go('/biblia'),
          )
        else ...[
          // En modo Himnario: Solfa, Nota, Lupa
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
        // Botón de cambio de módulo — muestra el módulo al que CAMBIARÁS
        Consumer(
          builder: (context, ref, _) {
            final liveState = ref.watch(liveControlProvider);
            final isBible = liveState.module == ProjectionModule.bible;
            // Si estoy en Biblia → botón dice "Himnario" (para cambiar a himnario)
            // Si estoy en Himnario → botón dice "Biblia" (para cambiar a biblia)
            return _FuncButton(
              icon: isBible ? Icons.music_note_outlined : Icons.menu_book_outlined,
              label: isBible ? 'Himnario' : 'Biblia',
              onPressed: () {
                final newModule = isBible
                    ? ProjectionModule.hymnal
                    : ProjectionModule.bible;
                // Navegar al módulo seleccionado usando el router global
                // (GoRouter.of(context) no funciona desde el overlay del
                // builder porque está fuera del Navigator).
                if (newModule == ProjectionModule.hymnal) {
                  appRouter.go('/himnario');
                } else {
                  appRouter.go('/biblia');
                }
                ref.read(liveControlProvider.notifier).switchToModule(newModule);
                // Enviar al subproceso local
                try {
                  ref.read(windowServiceProvider).sendMessage({
                    'type': 'SWITCH_MODULE',
                    'module': newModule.name,
                  });
                } catch (_) {}
                // En modo emisor: enviar comando al display remoto via gRPC
                final role = ref.read(connectionRoleProvider);
                if (role == ConnectionRole.emitter) {
                  try {
                    if (newModule == ProjectionModule.hymnal) {
                      ref.read(controlDataSourceProvider).sendSwitchToHymnal();
                    } else {
                      ref.read(controlDataSourceProvider).sendSwitchToBible();
                    }
                  } catch (_) {}
                }
              },
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Acciones
  // ─────────────────────────────────────────────────────────────

  /// Carga un himno por ID y lo envía al subproceso local y/o al display
  /// remoto vía gRPC si estamos en modo emisor.
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
      // Enviar al subproceso local
      final windowService = ref.read(windowServiceProvider);
      await windowService.sendMessage({
        'type': 'LOAD_HYMN',
        'himno_id': himno.id,
        'titulo': himno.titulo,
        'numero': himno.numero,
        'tipo': himno.tipo.name,
        'estrofas': estrofas
            .map((e) => {
                  'id': e.id,
                  'version_pais_id': e.versionPaisId,
                  'tipo': e.tipo.name,
                  'orden': e.orden,
                  'contenido': e.contenido,
                },)
            .toList(),
      });
      // En modo emisor: también enviar al display remoto vía gRPC
      final role = ref.read(connectionRoleProvider);
      if (role == ConnectionRole.emitter) {
        try {
          await ref.read(controlDataSourceProvider).sendHymnContent(
            hymnId: himno.id,
            titulo: himno.titulo,
            numero: himno.numero,
            tipo: himno.tipo.name,
            versionPaisId: versionPaisId,
            estrofas: estrofas
                .map((e) => <String, dynamic>{
                      'id': e.id,
                      'version_pais_id': e.versionPaisId,
                      'tipo': e.tipo.name,
                      'orden': e.orden,
                      'contenido': e.contenido,
                    },)
                .toList(),
          );
        } catch (_) {}
      }
    } catch (_) {
      // Error silencioso — el Provider mantiene el himno anterior
    }
  }

  /// Finaliza la presentación. En modo emisor desconecta del display
  /// remoto; en modo local cierra la ventana de proyección.
  Future<void> _handleExit(BuildContext context, WidgetRef ref) async {
    final role = ref.read(connectionRoleProvider);
    if (role == ConnectionRole.emitter) {
      // Desconectar del display remoto
      try {
        ref.read(connectionStateProvider.notifier).disconnect();
      } catch (_) {}
      ref.read(connectionRoleProvider.notifier).state = ConnectionRole.none;
    } else {
      // Cerrar ventana de proyección local
      final windowService = ref.read(windowServiceProvider);
      try {
        await windowService.closeProjectionWindow();
      } catch (_) {}
    }
    ref.read(isPresentingProvider.notifier).state = false;
    // Resetear el estado del control en vivo
    final notifier = ref.read(liveControlProvider.notifier);
    notifier.switchToModule(ProjectionModule.hymnal);
    notifier.loadHymn(
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
