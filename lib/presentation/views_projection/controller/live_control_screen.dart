import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/window_manager/window_providers.dart';
import '../../../domain/entities/projection_slide.dart';
import '../../../domain/repositories/control_repository.dart';
import '../../../features/biblia/application/providers/biblia_version_provider.dart';
import '../providers/bible_appearance_provider.dart';
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
        title: _buildAppBarTitle(liveState, textTheme),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _handleClose(context, ref),
        ),
        actions: [
          // Botón de cambio de módulo
          IconButton(
            icon: Icon(
              liveState.module == ProjectionModule.bible
                  ? Icons.menu_book_outlined
                  : Icons.music_note_outlined,
            ),
            tooltip: liveState.module == ProjectionModule.bible
                ? 'Cambiar a Himnario'
                : 'Cambiar a Biblia',
            onPressed: () {
              final newModule = liveState.module == ProjectionModule.bible
                  ? ProjectionModule.hymnal
                  : ProjectionModule.bible;
              ref.read(liveControlProvider.notifier).switchToModule(newModule);

              // Notificar al subprocess que limpie la pantalla
              try {
                ref.read(windowServiceProvider).sendMessage({
                  'type': 'SWITCH_MODULE',
                  'module': newModule.name,
                });
              } catch (_) {
                // Subprocess no disponible
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    newModule == ProjectionModule.bible
                        ? 'Módulo Biblia activado'
                        : 'Módulo Himnario activado',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          // Indicador de módulo
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              liveState.module == ProjectionModule.bible ? '📖' : '🎵',
              style: const TextStyle(fontSize: 18),
            ),
          ),
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

          // Botonera principal según módulo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: liveState.module == ProjectionModule.bible
                  ? _buildBibleControls(context, ref, liveState, colorScheme)
                  : _buildHymnalControls(context, ref, liveState, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el título del AppBar según el módulo activo.
  Widget _buildAppBarTitle(LiveControlState liveState, TextTheme? textTheme) {
    switch (liveState.module) {
      case ProjectionModule.bible:
        final title = liveState.libroNombre.isNotEmpty
            ? '${liveState.libroNombre} ${liveState.capitulo}'
            : 'Biblia';
        return Text(title);
      case ProjectionModule.hymnal:
        return Text(liveState.hymn?.titulo ?? 'Control en Vivo');
    }
  }

  /// Botonera principal para modo Himnario.
  Widget _buildHymnalControls(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
    ColorScheme colorScheme,
  ) {
    return Column(
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
                () => ref.read(liveControlProvider.notifier).nextSlide(),
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
                      () => ref.read(liveControlProvider.notifier).prevSlide(),
                      (repo) => repo.sendPrevStanza(),
                    );
                  },
                  backgroundColor: colorScheme.surfaceContainerHighest,
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
                            () => ref.read(liveControlProvider.notifier).goToChorus(),
                            (repo) => repo.sendGoToStanza(_findChorusIndex(ref)),
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
                            () => ref.read(liveControlProvider.notifier).goToStart(),
                            (repo) => repo.sendGoToStanza(0),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildQuickButton(
                        context,
                        label: liveState.isBlackout ? 'Encender' : 'Apagar',
                        onTap: () {
                          _sendCommand(
                            ref,
                            () => ref.read(liveControlProvider.notifier).toggleBlackout(),
                            (repo) => repo.sendBlackout(!liveState.isBlackout),
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
    );
  }

  /// Botonera principal para modo Biblia.
  Widget _buildBibleControls(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Fila 1: Navegación principal (SIGUIENTE / ANTERIOR)
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: _buildGiantButton(
                  context,
                  icon: Icons.arrow_forward_rounded,
                  label: 'SIGUIENTE',
                  onTap: () {
                    _sendCommand(
                      ref,
                      () => ref.read(liveControlProvider.notifier).nextSlide(),
                      (repo) => repo.sendNextStanza(),
                    );
                  },
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGiantButton(
                  context,
                  icon: Icons.arrow_back_rounded,
                  label: 'ANTERIOR',
                  onTap: () {
                    _sendCommand(
                      ref,
                      () => ref.read(liveControlProvider.notifier).prevSlide(),
                      (repo) => repo.sendPrevStanza(),
                    );
                  },
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Fila 2: Acciones rápidas
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: _buildQuickButton(
                  context,
                  label: 'Ir al Inicio',
                  onTap: () {
                    _sendCommand(
                      ref,
                      () => ref.read(liveControlProvider.notifier).goToStart(),
                      (repo) => repo.sendGoToStanza(0),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickButton(
                  context,
                  label: 'Ir a Versículo',
                  onTap: () => _showGoToVerseDialog(context, ref, liveState),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickButton(
                  context,
                  label: liveState.isBlackout ? 'Encender' : 'Apagar',
                  onTap: () {
                    _sendCommand(
                      ref,
                      () => ref.read(liveControlProvider.notifier).toggleBlackout(),
                      (repo) => repo.sendBlackout(!liveState.isBlackout),
                    );
                  },
                  isDestructive: !liveState.isBlackout,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Fila 3: Navegación de capítulos
        _buildChapterNavigation(context, ref, liveState, colorScheme),
        const SizedBox(height: 12),

        // Fila 4: Controles de apariencia bíblica
        _buildBibleAppearanceInline(context, ref, liveState, colorScheme),
      ],
    );
  }

  /// Navegación de capítulos anterior/siguiente.
  Widget _buildChapterNavigation(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
    ColorScheme colorScheme,
  ) {
    return Consumer(
      builder: (ctx, ref, _) {
        final prevEnabled = liveState.capitulo > 1;
        // El siguiente capítulo se habilita si hay más versículos o si el libro tiene más capítulos
        final nextEnabled = liveState.versiculos.isNotEmpty || liveState.capitulo >= 1;

        return Row(
          children: [
            Expanded(
              child: _buildLargeButton(
                context,
                icon: Icons.skip_previous_rounded,
                label: 'Cap. Anterior',
                onTap: prevEnabled
                    ? () => _handlePrevChapter(context, ref, liveState)
                    : () {},
                backgroundColor: prevEnabled
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                foregroundColor: prevEnabled
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLargeButton(
                context,
                icon: Icons.skip_next_rounded,
                label: 'Cap. Siguiente',
                onTap: nextEnabled
                    ? () => _handleNextChapter(context, ref, liveState)
                    : () {},
                backgroundColor: nextEnabled
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                foregroundColor: nextEnabled
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Maneja la carga del capítulo anterior.
  Future<void> _handlePrevChapter(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
  ) async {
    final notifier = ref.read(liveControlProvider.notifier);
    notifier.requestAdjacentChapter(false);

    // Buscar el libro por nombre para obtener su ID
    final bibliaRepo = ref.read(bibliaRepositoryProvider);
    final versiones = await bibliaRepo.getActiveVersions();
    if (versiones.isEmpty) return;

    final versionId = versiones.first.id;
    final libros = await bibliaRepo.getLibrosByVersion(versionId);
    final libro = libros.firstWhere(
      (l) => l.nombre == liveState.libroNombre,
      orElse: () => libros.first,
    );

    final caps = await bibliaRepo.getCapitulosByLibro(libro.id);
    final prevCap = caps.where((c) => c.numero < liveState.capitulo).lastOrNull;
    if (prevCap != null) {
      // Recargar el capítulo anterior
      final windowService = ref.read(windowServiceProvider);
      final versiculos = await bibliaRepo.getVersiculosByCapitulo(prevCap.id);
      final textos = versiculos.map((v) => v.texto).toList();

      if (textos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capítulo sin versículos')),
        );
        // Restaurar el estado anterior
        notifier.loadBibleChapter(
          libroNombre: liveState.libroNombre,
          capitulo: liveState.capitulo,
          versiculos: liveState.versiculos,
        );
        return;
      }

      notifier.loadBibleChapter(
        libroNombre: libro.nombre,
        capitulo: prevCap.numero,
        versiculos: textos,
      );

      await windowService.sendMessage({
        'type': 'LOAD_VERSE',
        'libroNombre': libro.nombre,
        'capitulo': prevCap.numero,
        'versiculos': textos,
      });

      // Sincronizar apariencia bíblica
      final bibleAppearance = ref.read(bibleAppearanceProvider);
      await windowService.sendMessage({
        'type': 'SET_BIBLE_THEME',
        'theme': bibleAppearance.theme,
      });
      await windowService.sendMessage({
        'type': 'SET_BIBLE_FONT_SIZE',
        'scale': bibleAppearance.fontScale,
      });
    }
  }

  /// Maneja la carga del capítulo siguiente.
  Future<void> _handleNextChapter(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
  ) async {
    final notifier = ref.read(liveControlProvider.notifier);
    notifier.requestAdjacentChapter(true);

    final bibliaRepo = ref.read(bibliaRepositoryProvider);
    final versiones = await bibliaRepo.getActiveVersions();
    if (versiones.isEmpty) return;

    final versionId = versiones.first.id;
    final libros = await bibliaRepo.getLibrosByVersion(versionId);
    final libro = libros.firstWhere(
      (l) => l.nombre == liveState.libroNombre,
      orElse: () => libros.first,
    );

    final caps = await bibliaRepo.getCapitulosByLibro(libro.id);
    final nextCap = caps.where((c) => c.numero > liveState.capitulo).firstOrNull;

    if (nextCap != null) {
      // Hay siguiente capítulo en el mismo libro
      final windowService = ref.read(windowServiceProvider);
      final versiculos = await bibliaRepo.getVersiculosByCapitulo(nextCap.id);
      final textos = versiculos.map((v) => v.texto).toList();

      if (textos.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capítulo sin versículos')),
        );
        // Restaurar el estado anterior
        notifier.loadBibleChapter(
          libroNombre: liveState.libroNombre,
          capitulo: liveState.capitulo,
          versiculos: liveState.versiculos,
        );
        return;
      }

      notifier.loadBibleChapter(
        libroNombre: libro.nombre,
        capitulo: nextCap.numero,
        versiculos: textos,
      );

      await windowService.sendMessage({
        'type': 'LOAD_VERSE',
        'libroNombre': libro.nombre,
        'capitulo': nextCap.numero,
        'versiculos': textos,
      });

      final bibleAppearance = ref.read(bibleAppearanceProvider);
      await windowService.sendMessage({
        'type': 'SET_BIBLE_THEME',
        'theme': bibleAppearance.theme,
      });
      await windowService.sendMessage({
        'type': 'SET_BIBLE_FONT_SIZE',
        'scale': bibleAppearance.fontScale,
      });
    } else {
      // Intentar ir al primer capítulo del siguiente libro
      final libroIndex = libros.indexWhere((l) => l.nombre == liveState.libroNombre);
      if (libroIndex >= 0 && libroIndex < libros.length - 1) {
        final nextLibro = libros[libroIndex + 1];
        final nextLibroCaps = await bibliaRepo.getCapitulosByLibro(nextLibro.id);
        if (nextLibroCaps.isNotEmpty) {
          final firstCap = nextLibroCaps.first;
          final windowService = ref.read(windowServiceProvider);
          final versiculos = await bibliaRepo.getVersiculosByCapitulo(firstCap.id);
          final textos = versiculos.map((v) => v.texto).toList();

      if (textos.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Capítulo sin versículos')),
        );
        // Restaurar el estado anterior
        notifier.loadBibleChapter(
          libroNombre: liveState.libroNombre,
          capitulo: liveState.capitulo,
          versiculos: liveState.versiculos,
        );
        return;
      }

          notifier.loadBibleChapter(
            libroNombre: nextLibro.nombre,
            capitulo: firstCap.numero,
            versiculos: textos,
          );

          await windowService.sendMessage({
            'type': 'LOAD_VERSE',
            'libroNombre': nextLibro.nombre,
            'capitulo': firstCap.numero,
            'versiculos': textos,
          });

          final bibleAppearance = ref.read(bibleAppearanceProvider);
          await windowService.sendMessage({
            'type': 'SET_BIBLE_THEME',
            'theme': bibleAppearance.theme,
          });
          await windowService.sendMessage({
            'type': 'SET_BIBLE_FONT_SIZE',
            'scale': bibleAppearance.fontScale,
          });
        }
      }
    }
  }

  /// Controles de apariencia bíblica inline (tema + escala de fuente).
  Widget _buildBibleAppearanceInline(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
    ColorScheme colorScheme,
  ) {
    final themes = const [
      ('papel', 'Papel', Colors.white),
      ('sepia', 'Sepia', Color(0xFFF5E6D3)),
      ('noche', 'Noche', Color(0xFF1A1A2E)),
      ('dark', 'Dark', Color(0xFF121212)),
      ('azulNoche', 'Azul Noche', Color(0xFF0D1B2A)),
      ('altoContraste', 'Alto Contraste', Colors.black),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de tema
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: themes.map((t) {
              final isSelected = liveState.bibleTheme == t.$1;
              return ChoiceChip(
                label: Text(
                  t.$2,
                  style: TextStyle(
                    color: (t.$3.computeLuminance() > 0.5)
                        ? Colors.black
                        : Colors.white,
                    fontSize: 11,
                  ),
                ),
                selected: isSelected,
                selectedColor: colorScheme.primary,
                backgroundColor: t.$3,
                onSelected: (_) {
                  ref.read(liveControlProvider.notifier).setBibleTheme(t.$1);
                  ref.read(bibleAppearanceProvider.notifier).setTheme(t.$1);
                  // Enviar al receptor
                  ref.read(windowServiceProvider).sendMessage({
                    'type': 'SET_BIBLE_THEME',
                    'theme': t.$1,
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Slider de escala de fuente
          Row(
            children: [
              const Icon(Icons.text_fields_rounded, size: 18),
              const SizedBox(width: 4),
              Text(
                '${liveState.bibleFontScale.toStringAsFixed(1)}x',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Expanded(
                child: Slider(
                  value: liveState.bibleFontScale,
                  min: 0.8,
                  max: 4.0,
                  divisions: 32,
                  label: '${liveState.bibleFontScale.toStringAsFixed(1)}x',
                  onChanged: (value) {
                    final clamped = value.clamp(0.8, 4.0);
                    ref.read(liveControlProvider.notifier).setBibleFontScale(clamped);
                    ref.read(bibleAppearanceProvider.notifier).setFontScale(clamped);
                    ref.read(windowServiceProvider).sendMessage({
                      'type': 'SET_BIBLE_FONT_SIZE',
                      'scale': clamped,
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Diálogo para saltar a un versículo específico.
  void _showGoToVerseDialog(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
  ) {
    final controller = TextEditingController();
    final totalVerses = liveState.versiculos.length;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ir a Versículo'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Versículo (1-$totalVerses)',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final verseNum = int.tryParse(controller.text);
                if (verseNum != null &&
                    verseNum >= 1 &&
                    verseNum <= totalVerses) {
                  ref.read(liveControlProvider.notifier).goToVerse(verseNum);
                  ref.read(windowServiceProvider).sendMessage({
                    'type': 'GO_TO_VERSE',
                    'verse': verseNum,
                  });
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Ir'),
            ),
          ],
        );
      },
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
              BibleTitleSlide(:final libroNombre, :final capitulo) => [
                  Text(
                    slide.displayLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$libroNombre $capitulo',
                    style: textTheme.bodySmall?.copyWith(color: fgColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              VerseSlide(:final numero, :final referencia) => [
                  Text(
                    slide.displayLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$referencia (v. $numero)',
                    style: textTheme.bodySmall?.copyWith(color: fgColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              BibleEndSlide(:final libroNombre, :final capitulo) => [
                  Text(
                    slide.displayLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$libroNombre $capitulo',
                    style: textTheme.bodySmall?.copyWith(color: fgColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            final liveState = ref.watch(liveControlProvider);

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

                  // ─────────────────────────────────────────
                  // Controles de Biblia (cuando módulo = bible)
                  // ─────────────────────────────────────────
                  if (liveState.module == ProjectionModule.bible) ...[
                    Text(
                      'Tema Bíblico',
                      style: Theme.of(sheetContext).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bibleThemeEntries.map((t) {
                        final isSelected = liveState.bibleTheme == t.$1;
                        return ChoiceChip(
                          label: Text(
                            t.$2,
                            style: TextStyle(
                              color: (t.$3.computeLuminance() > 0.5)
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: colorScheme.primary,
                          backgroundColor: t.$3,
                          onSelected: (_) {
                            ref
                                .read(liveControlProvider.notifier)
                                .setBibleTheme(t.$1);
                            ref
                                .read(bibleAppearanceProvider.notifier)
                                .setTheme(t.$1);
                            ref.read(windowServiceProvider).sendMessage({
                              'type': 'SET_BIBLE_THEME',
                              'theme': t.$1,
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Escala de fuente bíblica
                    Text(
                      'Escala de Fuente',
                      style: Theme.of(sheetContext).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.text_fields_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${liveState.bibleFontScale.toStringAsFixed(1)}x',
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                        Expanded(
                          child: Slider(
                            value: liveState.bibleFontScale,
                            min: 0.8,
                            max: 4.0,
                            divisions: 32,
                            label:
                                '${liveState.bibleFontScale.toStringAsFixed(1)}x',
                            onChanged: (value) {
                              final clamped = value.clamp(0.8, 4.0);
                              ref
                                  .read(liveControlProvider.notifier)
                                  .setBibleFontScale(clamped);
                              ref
                                  .read(bibleAppearanceProvider.notifier)
                                  .setFontScale(clamped);
                              ref.read(windowServiceProvider).sendMessage({
                                'type': 'SET_BIBLE_FONT_SIZE',
                                'scale': clamped,
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],

                  // ─────────────────────────────────────────
                  // Controles de Himnario (siempre visibles)
                  // ─────────────────────────────────────────

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

  /// Entradas de temas bíblicos: (id, label, bgColor).
  static const _bibleThemeEntries = [
    ('papel', 'Papel', Colors.white),
    ('sepia', 'Sepia', Color(0xFFF5E6D3)),
    ('noche', 'Noche', Color(0xFF1A1A2E)),
    ('dark', 'Dark', Color(0xFF121212)),
    ('azulNoche', 'Azul Noche', Color(0xFF0D1B2A)),
    ('altoContraste', 'Alto Contraste', Colors.black),
  ];

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
