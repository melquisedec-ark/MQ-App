import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../shared_widgets/control_sheets.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../providers/active_hymn_providers.dart';
import '../providers/connection_providers.dart';
import '../providers/live_control_providers.dart';
import '../../views_personal/providers/audio_providers.dart';

/// Panel de control minimalista para modo Emisor.
///
/// Se abre al seleccionar un himno en [ConnectedDashboard].
/// Sin scroll de letra, solo controles de navegación y función.
/// Los cambios se envían al provider local y por gRPC al Receptor.
class MinimalControlScreen extends ConsumerWidget {
  const MinimalControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isConnected = ref.watch(isConnectedProvider);
    final liveState = ref.watch(liveControlProvider);
    final hymnId = ref.watch(activeHymnIdProvider);

    // Si no hay himno seleccionado, mostrar placeholder
    if (hymnId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Control de Proyección')),
        body: const Center(child: Text('Selecciona un himno para proyectar')),
      );
    }

    // Escuchar estrofas y cargar en LiveControl cuando lleguen
    ref.listen(activeStanzasProvider, (prev, next) {
      next.whenData((estrofas) {
        if (estrofas == null || estrofas.isEmpty) return;
        final himno = ref.read(activeHymnProvider).valueOrNull;
        if (himno == null) return;
        final currentHymn = liveState.hymn;
        if (currentHymn == null || currentHymn.id != himno.id) {
          ref
              .read(liveControlProvider.notifier)
              .loadHymn(himno, estrofas, versionPaisId: himno.primaryVersionPaisId);
          if (isConnected) {
            _sendHymnToDisplay(ref, himno, estrofas);
          }
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(liveState.hymn?.titulo ?? 'Control de Proyección'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Indicador de conexión
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.cast,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'Modo Emisor - Conectado' : 'Sin conexión',
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
                if (liveState.currentSlide != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${liveState.currentSlide!.displayLabel} '
                      '${liveState.currentSlideIndex + 1}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // Botones de navegación grandes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: Icons.skip_previous,
                label: 'Anterior',
                onPressed: liveState.hasPrevSlide
                    ? () async {
                  ref
                      .read(liveControlProvider.notifier)
                      .prevSlide();
                  if (ref.read(isConnectedProvider)) {
                    try {
                      await ref
                          .read(controlDataSourceProvider)
                          .sendPrevStanza();
                    } catch (_) {
                      // Fallo silencioso — el estado local persiste
                    }
                  }
                }
                    : null,
              ),
              const SizedBox(width: 32),
              _ControlButton(
                icon: Icons.skip_next,
                label: 'Siguiente',
                onPressed: liveState.hasNextSlide
                    ? () async {
                  ref
                      .read(liveControlProvider.notifier)
                      .nextSlide();
                  if (ref.read(isConnectedProvider)) {
                    try {
                      await ref
                          .read(controlDataSourceProvider)
                          .sendNextStanza();
                    } catch (_) {
                      // Fallo silencioso — el estado local persiste
                    }
                  }
                }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Botones de función
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _FunctionButton(
                icon: Icons.brush,
                label: 'Brocha',
                onPressed: () => showBrushSheet(
                  context,
                  ref: ref,
                ),
              ),
              _FunctionButton(
                icon: Icons.music_note,
                label: 'Solfa',
                onPressed: () => showSolfaSheet(
                  context,
                  ref: ref,
                ),
              ),
              _FunctionButton(
                icon: Icons.audiotrack,
                label: 'Nota',
                onPressed: () => showNoteSheet(
                  context,
                  ref: ref,
                  himnoId: hymnId,
                  currentPistaId: null,
                  onPlayPista: (pistaId) =>
                      ref.read(audioRepositoryProvider).play(pistaId),
                  onStop: () => ref.read(audioRepositoryProvider).stop(),
                ),
              ),
              _FunctionButton(
                icon: Icons.search,
                label: 'Lupa',
                onPressed: () async {
                  final currentId = ref.read(activeHymnIdProvider);
                  final result = await showSearchSheet(
                    context,
                    ref: ref,
                    currentHimnoId: currentId ?? -1,
                  );
                  if (result != null && result > 0 && result != currentId) {
                    ref.read(activeHymnIdProvider.notifier).state = result;
                    // No hacer Navigator — el widget reacciona solo al provider
                  }
                },
              ),
            ],
          ),

          const Spacer(),

          // Botón salir
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Salir'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Envía el himno completo al display remoto vía gRPC.
Future<void> _sendHymnToDisplay(
    WidgetRef ref,
    Himno himno,
    List<Estrofa> estrofas,
  ) async {
    final dataSource = ref.read(controlDataSourceProvider);
    await dataSource.sendHymnContent(
      hymnId: himno.id,
      titulo: himno.titulo,
      numero: himno.numero,
      tipo: himno.tipo.name,
      versionPaisId: himno.primaryVersionPaisId,
      estrofas: estrofas
          .map((e) => <String, dynamic>{
                'id': e.id,
                'version_pais_id': e.versionPaisId,
                'tipo': e.tipo.name,
                'orden': e.orden,
                'contenido': e.contenido,
              })
          .toList(),
    );
    // NUEVO: Enviar apariencia actual al display remoto
    final appearance = ref.read(hymnAppearanceProvider);
    try {
      await dataSource.sendSetAppearance(
        textColor: _colorToHex(appearance.textColor),
        chordColor: _colorToHex(appearance.chordColor),
        fontFamily: appearance.fontFamily,
        isBold: appearance.isBold,
        showChords: appearance.showChords,
        cardOpacity: appearance.cardOpacity,
        projectionFontScale: appearance.projectionFontScale,
      );
    } catch (_) {
      // Fallo silencioso — el estado local persiste
    }
  }

/// Convierte un Color a string hex #AARRGGBB.
String _colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ControlButton({
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
          iconSize: 48,
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDisabled
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FunctionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _FunctionButton({
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
      children: <Widget>[
        IconButton(
          iconSize: 32,
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDisabled
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
