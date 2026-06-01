import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/window_manager/window_providers.dart';
import '../../../domain/entities/projection_slide.dart';
import '../../../domain/repositories/control_repository.dart';
import '../providers/connection_providers.dart';
import '../providers/live_control_providers.dart';
import '../providers/presentation_providers.dart';
import '../providers/projection_providers.dart';
import '../../shared_widgets/providers/appearance_provider.dart';

/// Pantalla de Control en Vivo (Live Control).
/// Botonera táctica diseñada para operar sin mirar la pantalla.
/// Totalmente conectada a los providers de Riverpod.
/// Cada botón envía comandos vía [ControlRepository] además de actualizar
/// el estado local.
class LiveControlScreen extends ConsumerWidget {
  const LiveControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final liveState = ref.watch(liveControlProvider);
    final isConnected = ref.watch(isConnectedProvider);

    // Slide actual y sus metadatos para la UI
    final currentSlide = liveState.currentSlide;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(liveState.hymn?.titulo ?? 'Control en Vivo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref),
        ),
        actions: [
          // Indicador de conexión
          Icon(
            isConnected ? Icons.cast_connected_rounded : Icons.cast_rounded,
            color: isConnected ? colorScheme.primary : colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          // Indicador de slide actual
          if (currentSlide != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentSlide.displayLabel} ${liveState.currentSlideIndex + 1}',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Panel de vista previa y configuración
          _buildPreviewPanel(context, ref, liveState),

          // Botonera principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Botón GIGANTE de Siguiente (40% de la pantalla)
                  Expanded(
                    flex: 4,
                    child: _buildGiantButton(
                      context,
                      icon: Icons.arrow_forward_rounded,
                      label: 'SIGUIENTE',
                      onTap: () {
                        _sendCommand(
                          ref,
                          () => ref
                              .read(liveControlProvider.notifier)
                              .nextSlide(),
                          (repo) => repo.sendNextStanza(),
                        );
                      },
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fila de botones: Anterior + Accesos rápidos
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        // Botón Anterior
                        Expanded(
                          child: _buildLargeButton(
                            context,
                            icon: Icons.arrow_back_rounded,
                            label: 'Anterior',
                            onTap: () {
                              _sendCommand(
                                ref,
                                () => ref
                                    .read(liveControlProvider.notifier)
                                    .prevSlide(),
                                (repo) => repo.sendPrevStanza(),
                              );
                            },
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            foregroundColor: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botones de acceso rápido
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: _buildQuickButton(
                                  context,
                                  label: 'Ir al Coro',
                                  onTap: () {
                                    _sendCommand(
                                      ref,
                                      () => ref
                                          .read(liveControlProvider.notifier)
                                          .goToChorus(),
                                      (repo) => repo.sendGoToStanza(
                                        _findChorusIndex(ref),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildQuickButton(
                                  context,
                                  label: 'Ir al Inicio',
                                  onTap: () {
                                    _sendCommand(
                                      ref,
                                      () => ref
                                          .read(liveControlProvider.notifier)
                                          .goToStart(),
                                      (repo) => repo.sendGoToStanza(0),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _buildQuickButton(
                                  context,
                                  label: liveState.isBlackout
                                      ? 'Encender'
                                      : 'Apagar',
                                  onTap: () {
                                    _sendCommand(
                                      ref,
                                      () => ref
                                          .read(liveControlProvider.notifier)
                                          .toggleBlackout(),
                                      (repo) => repo.sendBlackout(
                                        !liveState.isBlackout,
                                      ),
                                    );
                                  },
                                  isDestructive: !liveState.isBlackout,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Maneja el cierre de la pantalla de control.
  ///
  /// Si el modo presentación está activo ([isPresentingProvider] es `true`),
  /// detiene la presentación (cierra la ventana de proyección y resetea el
  /// estado). En caso contrario, simplemente retrocede en la navegación.
  void _handleClose(BuildContext context, WidgetRef ref) {
    final isPresenting = ref.read(isPresentingProvider);
    if (isPresenting) {
      ref.read(windowServiceProvider).closeProjectionWindow();
      ref.read(isPresentingProvider.notifier).state = false;
    } else {
      Navigator.pop(context);
    }
  }

  /// Envía un comando tanto al estado local como al repositorio remoto.
  void _sendCommand(
    WidgetRef ref,
    VoidCallback localAction,
    Future<bool> Function(ControlRepository repo) remoteAction,
  ) {
    // Actualizar estado local
    localAction();

    // Enviar al repositorio remoto si hay conexión
    final isConnected = ref.read(isConnectedProvider);
    if (isConnected) {
      final repo = ref.read(controlRepositoryProvider);
      remoteAction(repo).then((success) {
        if (!success) {
          // Fallback: el estado local ya se actualizó
        }
      });
    }
  }

  /// Encuentra el índice del primer coro en la lista de estrofas.
  int _findChorusIndex(WidgetRef ref) {
    final liveState = ref.read(liveControlProvider);
    final chorusIndex = liveState.slides.indexWhere(
      (s) => s is LyricsSlide && s.estrofa.isChorus,
    );
    return chorusIndex >= 0 ? chorusIndex : 0;
  }

  // ─────────────────────────────────────────────────────────────
  // Preview Panel
  // ─────────────────────────────────────────────────────────────

  Widget _buildPreviewPanel(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentSlide = liveState.currentSlide;
    final nextSlide = liveState.hasNextSlide
        ? liveState.slides[liveState.currentSlideIndex + 1]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista Previa',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Slide actual
              Expanded(
                child: _buildSlidePreview(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  label: 'Actual',
                  slide: currentSlide,
                  isCurrent: true,
                ),
              ),
              const SizedBox(width: 12),
              // Siguiente slide
              Expanded(
                child: _buildSlidePreview(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  label: 'Siguiente',
                  slide: nextSlide,
                  isCurrent: false,
                ),
              ),
              // Botón de configuración
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showConfigSheet(context, ref),
                icon: const Icon(Icons.tune_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Renderiza una tarjeta de preview para un [ProjectionSlide].
  Widget _buildSlidePreview({
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String label,
    required ProjectionSlide? slide,
    required bool isCurrent,
  }) {
    final bgColor = isCurrent
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final fgColor = isCurrent
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: fgColor),
          ),
          const SizedBox(height: 4),
          if (slide == null)
            Text(
              'Fin',
              style: textTheme.bodyMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            ...switch (slide) {
              TitleSlide(:final himno) => [
                  Text(
                    slide.displayLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${himno.titulo}${himno.numero != null ? ' (#${himno.numero})' : ''}',
                    style: textTheme.bodySmall?.copyWith(color: fgColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              LyricsSlide(:final estrofa) => [
                  Text(
                    slide.displayLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    estrofa.contenido.split('\n').first,
                    style: textTheme.bodySmall?.copyWith(color: fgColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              AmenSlide() => [
                  Text(
                    slide.displayLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
            },
        ],
      ),
    );
  }

  void _showConfigSheet(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        // Usar un Consumer para que el sheet se actualice en tiempo real
        return Consumer(
          builder: (sheetContext, ref, _) {
            final currentConfig = ref.watch(projectionConfigProvider);
            final appearance = ref.watch(hymnAppearanceProvider);

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración de Presentación',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),

                  // Selector de fondo
                  Text(
                    'Fondo',
                    style: Theme.of(sheetContext).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ProjectionBackground.values.map((bg) {
                      return ChoiceChip(
                        label: Text(_backgroundLabel(bg)),
                        selected: currentConfig.background == bg,
                        onSelected: (_) {
                          ref
                              .read(projectionConfigProvider.notifier)
                              .setBackground(bg);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Selector de tamaño de fuente
                  Text(
                    'Tamaño de Fuente',
                    style: Theme.of(sheetContext).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ProjectionFontSize.values.map((fs) {
                      return ChoiceChip(
                        label: Text(_fontSizeLabel(fs)),
                        selected: currentConfig.fontSize == fs,
                        onSelected: (_) {
                          ref
                              .read(projectionConfigProvider.notifier)
                              .setFontSize(fs);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Selector de velocidad de transición
                  Text(
                    'Velocidad de Transición',
                    style: Theme.of(sheetContext).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Lenta'),
                      Expanded(
                        child: Slider(
                          value: currentConfig.transitionSpeed,
                          onChanged: (value) {
                            ref
                                .read(projectionConfigProvider.notifier)
                                .setTransitionSpeed(value);
                          },
                        ),
                      ),
                      const Text('Rápida'),
                    ],
                  ),

                  // ─────────────────────────────────────────
                  // Efecto Glass (solo visible en fondo Imagen)
                  // ─────────────────────────────────────────
                  if (currentConfig.background == ProjectionBackground.image) ...[
                    const SizedBox(height: 24),
                    const Divider(
                      color: Color(0xFF4A4A4A),
                    ),
                    const SizedBox(height: 16),

                    // Toggle principal
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        Icons.blur_on_rounded,
                        color: const Color(0xFFCCA43B),
                      ),
                      title: const Text('Efecto Glass'),
                      subtitle: Text(
                        'Panel semitransparente con blur',
                        style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: appearance.glassEnabled,
                      onChanged: (value) {
                        ref
                            .read(hymnAppearanceProvider.notifier)
                            .setGlassEnabled(value);
                      },
                    ),

                    if (appearance.glassEnabled) ...[
                      const SizedBox(height: 16),

                      // Opacidad del panel
                      Text(
                        'Opacidad del panel',
                        style: Theme.of(sheetContext).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.opacity, size: 18),
                          Expanded(
                            child: Slider(
                              value: appearance.cardOpacity,
                              min: 0.05,
                              max: 0.60,
                              divisions: 55,
                              label:
                                  '${(appearance.cardOpacity * 100).round()}%',
                              onChanged: (value) {
                                ref
                                    .read(hymnAppearanceProvider.notifier)
                                    .setCardOpacity(value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${(appearance.cardOpacity * 100).round()}%',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Intensidad de blur
                      Text(
                        'Intensidad de blur',
                        style: Theme.of(sheetContext).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.blur_circular, size: 18),
                          Expanded(
                            child: Slider(
                              value: appearance.glassBlurSigma,
                              min: 0.0,
                              max: 20.0,
                              divisions: 40,
                              label:
                                  '${appearance.glassBlurSigma.toStringAsFixed(1)}px',
                              onChanged: (value) {
                                ref
                                    .read(hymnAppearanceProvider.notifier)
                                    .setGlassBlurSigma(value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${appearance.glassBlurSigma.toStringAsFixed(1)}px',
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _backgroundLabel(ProjectionBackground bg) {
    switch (bg) {
      case ProjectionBackground.black:
        return 'Negro';
      case ProjectionBackground.color:
        return 'Color';
      case ProjectionBackground.image:
        return 'Imagen';
    }
  }

  String _fontSizeLabel(ProjectionFontSize fs) {
    switch (fs) {
      case ProjectionFontSize.small:
        return 'Pequeño';
      case ProjectionFontSize.medium:
        return 'Mediano';
      case ProjectionFontSize.large:
        return 'Grande';
      case ProjectionFontSize.extraLarge:
        return 'Extra Grande';
    }
  }

  Widget _buildGiantButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor,
                backgroundColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: foregroundColor,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor, size: 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isDestructive
          ? colorScheme.errorContainer
          : colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isDestructive
                      ? colorScheme.onErrorContainer
                      : colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
