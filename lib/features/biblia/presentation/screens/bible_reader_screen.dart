import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/network/connection_state.dart';
import '../../../../core/window_manager/window_providers.dart';
import '../../../../presentation/shared_widgets/glass_card.dart';
import '../../../../proto/generated/hymn_control.pbgrpc.dart';
import '../../../../presentation/views_projection/providers/connection_providers.dart';
import '../../../../presentation/views_projection/providers/live_control_providers.dart';
import '../../../../presentation/views_projection/providers/presentation_providers.dart';
import '../../../../data/datasources/remote/grpc_control_datasource.dart';
import '../../../../presentation/dual_mode_wrapper/dual_mode_providers.dart';
import '../../../../presentation/providers/fullscreen_mode_provider.dart';
import '../../application/providers/bible_grpc_client_provider.dart';
import '../../application/providers/biblia_version_provider.dart';
import '../../application/providers/bible_appearance_provider.dart';
import '../../application/providers/biblia_config_provider.dart';
import '../../application/providers/cross_referencias_provider.dart';
import '../../application/providers/current_libro_provider.dart';
import '../../application/providers/current_versiculo_provider.dart';
import '../../application/providers/derived_providers.dart';
import '../../application/providers/notas_provider.dart';
import '../../application/providers/favoritos_provider.dart';
import '../../application/providers/historial_provider.dart';
import '../../application/providers/reader_providers.dart';
import '../../data/models/capitulo.dart';
import '../../data/models/libro.dart';
import '../../data/models/nota.dart';
import '../../data/models/versiculo.dart';
import '../widgets/note_editor_modal.dart';
import '../widgets/referencias_cruzadas_section.dart';
import '../widgets/verse_card.dart';
import '../widgets/reading_settings_sheet.dart';
import '../widgets/version_picker_sheet.dart';

/// Pantalla principal del Bible reader: muestra 1 versículo a la vez.
///
/// Referencia: `doc/wireframes/02_bible_module.md` (Pantalla 2c).
///
/// C8: acepta `initialVersiculo` (de query param `?v=N`) para abrir
/// directamente en un versículo concreto. Si es `null`, se usa 1
/// (default).
class BibleReaderScreen extends ConsumerStatefulWidget {
  const BibleReaderScreen({
    super.key,
    required this.libroId,
    required this.capitulo,
    this.initialVersiculo,
  });

  final int libroId;
  final int capitulo;

  /// Versículo inicial opcional (de query param `?v=N` en la URL).
  /// Si es `null`, se inicializa en 1.
  final int? initialVersiculo;

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  int? _lastRecordedVersiculo;

  /// Guard flag that prevents the verse-level sync listener from firing
  /// while a chapter-level auto-sync is in progress. This avoids duplicate
  /// LOAD_VERSE messages and race conditions when the user navigates
  /// between chapters/books.
  bool _isSyncingChapter = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(currentLibroIdProvider.notifier).state = widget.libroId;
      ref.read(currentCapituloProvider.notifier).state = widget.capitulo;
      // C8: si la ruta trae `?v=N` (deep link desde cross-ref), abrir
      // directamente en ese versículo. Si no, preservar el actual
      // (compatibilidad con navegación interna) o default 1.
      final currentNum = ref.read(currentVersiculoNumeroProvider);
      final initialVerse = widget.initialVersiculo ?? currentNum ?? 1;
      if (currentNum != initialVerse) {
        ref.read(currentVersiculoNumeroProvider.notifier).state = initialVerse;
      }
      // Inicializar currentVerseProvider (vista de capítulo) con el
      // versículo actual para que el scroll programático arranque en
      // la posición correcta.
      ref.read(currentVerseProvider.notifier).state = initialVerse;
      // Resolver libroId → libroNumero (canónico) y cachearlo para el
      // cliente gRPC (BibleClientActions lo lee al enviar comandos).
      _syncLibroNumeroFromId(widget.libroId);
      // 🔁 Proactive sync: si ya estamos presentando al llegar a esta
      // pantalla, enviar el capítulo actual a la ventana de proyección.
      if (ref.read(isPresentingProvider)) {
        _isSyncingChapter = true;
        _sendChapterToProjection(ref).then((_) {
          if (mounted) _isSyncingChapter = false;
        });
      }
    });
  }

  /// Resuelve el `libroId` a su número canónico y lo cachea.
  Future<void> _syncLibroNumeroFromId(int libroId) async {
    try {
      final repo = ref.read(bibliaRepositoryProvider);
      final libro = await repo.getLibroById(libroId);
      if (libro != null && mounted) {
        ref.read(currentLibroNumeroProvider.notifier).state = libro.numero;
      }
    } catch (_) {
      // Ignorar: el default (1 = Génesis) ya está en el provider.
    }
  }

  /// Proyecta el capítulo bíblico actual en la ventana de proyección.
  Future<void> _projectCurrentChapter(BuildContext context, WidgetRef ref) async {
    await _sendChapterToProjection(ref);
  }

  /// Fetches the current chapter and sends LOAD_VERSE to the projection.
  ///
  /// Does NOT open the projection window or wait for readiness — it just
  /// fetches the current chapter data and sends it to the subprocess.
  /// Used both by the Presentar button flow and by the auto-sync listener
  /// on [currentBibleAnchorProvider].
  Future<void> _sendChapterToProjection(WidgetRef ref) async {
    final repo = ref.read(bibliaRepositoryProvider);
    final libroId = ref.read(currentLibroIdProvider) ?? widget.libroId;
    final capitulo = ref.read(currentCapituloProvider) ?? widget.capitulo;

    final libro = await repo.getLibroById(libroId);
    if (libro == null) return;

    final cap = await repo.getCapitulo(libroId, capitulo);
    if (cap == null) return;

    final versiculos = await repo.getVersiculosByCapitulo(cap.id);
    if (versiculos.isEmpty) return;

    final textos = versiculos.map((v) => v.texto).toList();

    // Actualizar estado de proyección local
    ref.read(liveControlProvider.notifier).loadBibleChapter(
      libroNombre: libro.nombre,
      capitulo: capitulo,
      versiculos: textos,
    );

    // Enviar al subproceso de proyección
    try {
      await ref.read(windowServiceProvider).sendMessage({
        'type': 'LOAD_VERSE',
        'libroNombre': libro.nombre,
        'capitulo': capitulo,
        'versiculos': textos,
      });
    } catch (_) {
      // Subproceso no disponible
    }
    // En modo emisor: enviar GO_TO_VERSE al display remoto vía gRPC
    _sendChapterToRemoteDisplay(ref, libro, capitulo);
  }

  /// Envía el capítulo actual al display remoto vía gRPC si estamos en
  /// modo emisor. El servidor gRPC carga el capítulo completo al recibir
  /// GO_TO_VERSE y navega al versículo indicado.
  void _sendChapterToRemoteDisplay(WidgetRef ref, Libro libro, int capitulo) {
    final role = ref.read(connectionRoleProvider);
    if (role != ConnectionRole.emitter) return;
    try {
      final versionId = ref.read(currentVersionIdProvider);
      final versiculo = ref.read(currentVersiculoNumeroProvider) ?? 1;
      ref.read(controlDataSourceProvider).sendGoToVerse(
        versionId: versionId,
        libroNumero: libro.numero,
        capitulo: capitulo,
        versiculo: versiculo,
      );
    } catch (_) {}
  }

  /// Sincroniza el versículo actual con la proyección (envía NEXT/PREV_SLIDE).
  Future<void> _syncVerseToProjection(WidgetRef ref, int nuevoVersiculo) async {
    final liveState = ref.read(liveControlProvider);
    // Si no hay slides bíblicos cargados, no hacer nada
    if (liveState.module != ProjectionModule.bible || liveState.slides.isEmpty) return;
    // El slide del versículo N está en el índice N (slide 0 = título)
    final targetIndex = nuevoVersiculo;
    if (targetIndex >= 0 && targetIndex < liveState.slides.length) {
      ref.read(liveControlProvider.notifier).goToSlide(targetIndex);
      try {
        await ref.read(windowServiceProvider).sendMessage({
          'type': 'GO_TO_SLIDE',
          'index': targetIndex,
        });
      } catch (_) {}
      // En modo emisor: enviar GO_TO_VERSE al display remoto
      _syncVerseToRemoteDisplay(ref, nuevoVersiculo);
    }
  }

  /// Envía el versículo actual al display remoto vía gRPC (modo emisor).
  void _syncVerseToRemoteDisplay(WidgetRef ref, int nuevoVersiculo) {
    final role = ref.read(connectionRoleProvider);
    if (role != ConnectionRole.emitter) return;
    try {
      final versionId = ref.read(currentVersionIdProvider);
      final libroNumero = ref.read(currentLibroNumeroProvider) ?? 1;
      final capitulo = ref.read(currentCapituloProvider) ?? 1;
      ref.read(controlDataSourceProvider).sendGoToVerse(
        versionId: versionId,
        libroNumero: libroNumero,
        capitulo: capitulo,
        versiculo: nuevoVersiculo,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isFullscreen = ref.watch(fullscreenModeProvider);
    final isPresenting = ref.watch(isPresentingProvider);
    final isDesktop = ref.watch(isDesktopModeProvider);
    final versionId = ref.watch(currentVersionIdProvider);
    final libroId = ref.watch(currentLibroIdProvider) ?? widget.libroId;
    final capitulo = ref.watch(currentCapituloProvider) ?? widget.capitulo;
    final versiculoNum = ref.watch(currentVersiculoNumeroProvider) ?? 1;

    // NEW listener: auto-sync chapter changes to projection
    ref.listen<String>(currentBibleAnchorProvider, (prev, next) async {
      final isPresenting = ref.read(isPresentingProvider);
      if (!isPresenting || next == prev) return;
      _isSyncingChapter = true;
      try {
        await _sendChapterToProjection(ref);
      } finally {
        _isSyncingChapter = false;
      }
    });

    ref.listen<int?>(currentVersiculoNumeroProvider, (prev, next) {
      if (next != null) {
        // Mantener currentVerseProvider sincronizado para la vista de
        // capítulo. Al alternar entre verse/chapter se preserva.
        ref.read(currentVerseProvider.notifier).state = next;
      }
      if (next != null && next != _lastRecordedVersiculo) {
        // B2: respetar el toggle "Auto-registrar historial" en Configuración.
        final autoHist = ref.read(autoHistorialProvider);
        if (!autoHist) return;
        _lastRecordedVersiculo = next;
        ref.read(historialRepositoryProvider).record(
              versionId,
              libroId,
              capitulo,
              next,
            );
      }
      // Si está presentando, sincronizar el versículo actual con la proyección.
      // Skip verse-level sync while a chapter-level sync is in progress to
      // avoid race conditions and duplicate LOAD_VERSE messages.
      if (_isSyncingChapter) return;
      final isPresenting = ref.read(isPresentingProvider);
      if (isPresenting && next != null && next != prev) {
        _syncVerseToProjection(ref, next).ignore();
      }
    });

    return Scaffold(
      appBar: isFullscreen ? null : AppBar(
        title: _AppBarTitle(libroId: libroId, capitulo: capitulo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Atrás',
        ),
        actions: [
          // Botón Presentar (proyección local) — solo desktop y sin presentación activa
          Consumer(
            builder: (context, ref, _) {
              final isDesktop = ref.watch(isDesktopModeProvider);
              if (!isDesktop) return const SizedBox.shrink();
              final isPresenting = ref.watch(isPresentingProvider);
              if (isPresenting) return const SizedBox.shrink();
              final btnColorScheme = Theme.of(context).colorScheme;
              return IconButton(
                icon: const Icon(Icons.screen_share_outlined),
                color: btnColorScheme.primary,
                tooltip: 'Presentar',
                onPressed: () async {
                  final windowService = ref.read(windowServiceProvider);
                  try {
                    await windowService.openProjectionWindow({
                      'mode': 'local',
                      'source': 'bible_reader',
                    });
                    ref.read(isPresentingProvider.notifier).state = true;
                    // Esperar a que el subproceso esté listo antes de enviar
                    await Future<void>.delayed(const Duration(milliseconds: 800));
                    // NO usamos context.mounted: el botón se oculta al
                    // activar isPresenting, desmontando este Consumer.
                    await _projectCurrentChapter(context, ref);
                  } catch (e) {
                    if (context.mounted) {
                      showAppSnackBar(context, 'Error: $e', type: AppSnackBarType.error);
                    }
                  }
                },
              );
            },
          ),
          _EnviarButton(
            libroId: libroId,
            capitulo: capitulo,
            versiculoNum: versiculoNum,
          ),
          _VersionSelector(versionId: versionId),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.pushNamed('biblia_search'),
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: SafeArea(
        top: !isFullscreen,
        child: Column(
          children: [
            if (!isFullscreen)
              _ChapterProgress(
                libroId: libroId,
                capitulo: capitulo,
                versiculoNum: versiculoNum,
              ),
            Expanded(
              // D6: alternar entre vista por versículo y vista de capítulo.
              child: Consumer(
                builder: (context, ref, _) {
                  final viewMode = ref.watch(readerViewModeProvider);
                  if (viewMode == BibleReaderViewMode.chapter) {
                    return _ChapterVerseList(
                      libroId: libroId,
                      capitulo: capitulo,
                    );
                  }
                  return _VerseDisplay(
                    libroId: libroId,
                    capitulo: capitulo,
                    versiculoNum: versiculoNum,
                  );
                },
              ),
            ),
            if (!isFullscreen && !(isPresenting && isDesktop))
              _ReaderBottomBar(
                libroId: libroId,
                capitulo: capitulo,
                versiculoNum: versiculoNum,
              ),
          ],
        ),
      ),
      // Botón flotante para salir de pantalla completa (todos los dispositivos)
      floatingActionButton: isFullscreen
          ? FloatingActionButton.small(
              onPressed: () =>
                  ref.read(fullscreenModeProvider.notifier).exitFullscreen(),
              tooltip: 'Salir de pantalla completa',
              child: const Icon(Icons.fullscreen_exit_rounded),
            )
          : null,
    );
  }
}

/// Botón que alterna entre vista por versículo y vista de capítulo.
///
/// A1+A2: migrado del AppBar al bottom bar. Usa el estilo compacto
/// (iconSize 20, padding 0) para caber en 360dp.
class _ViewModeToggleButton extends ConsumerWidget {
  const _ViewModeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(readerViewModeProvider);
    final isChapter = viewMode == BibleReaderViewMode.chapter;
    return IconButton(
      icon: Icon(
        isChapter ? Icons.view_agenda_outlined : Icons.view_headline_rounded,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: isChapter ? 'Vista por versículo' : 'Vista de capítulo',
      onPressed: () {
        // NO resetear currentVerseProvider al alternar: la posición
        // de lectura se preserva entre modos.
        ref.read(readerViewModeProvider.notifier).setViewMode(
            isChapter ? BibleReaderViewMode.verse : BibleReaderViewMode.chapter);
      },
    );
  }
}

/// Vista de capítulo completo: lista de [VerseCard] con scroll programático
/// al [currentVerseProvider].
class _ChapterVerseList extends ConsumerStatefulWidget {
  const _ChapterVerseList({
    required this.libroId,
    required this.capitulo,
  });

  final int libroId;
  final int capitulo;

  @override
  ConsumerState<_ChapterVerseList> createState() => _ChapterVerseListState();
}

class _ChapterVerseListState extends ConsumerState<_ChapterVerseList> {
  final ItemScrollController _itemController = ItemScrollController();
  int? _lastScrolledVerse;

  @override
  Widget build(BuildContext context) {
    final libroId = widget.libroId;
    final capitulo = widget.capitulo;
    final bibliaRepo = ref.read(bibliaRepositoryProvider);
    final currentVerse = ref.watch(currentVerseProvider);
    final appearance = ref.watch(bibleAppearanceProvider);

    // A4: set de números de versículo favoritos en el capítulo actual.
    final favoritosAsync = ref.watch(favoritosStreamProvider);
    final favoritosEnCapitulo = favoritosAsync.maybeWhen(
      data: (list) {
        final set = <int>{};
        for (final f in list) {
          if (f.libroId == libroId && f.capitulo == capitulo) {
            set.add(f.numero);
          }
        }
        return set;
      },
      orElse: () => <int>{},
    );

    // O7b: mapa de número de versículo → nota completa para el capítulo actual.
    final notasAsync = ref.watch(notasStreamProvider);
    final notasEnCapitulo = notasAsync.maybeWhen(
      data: (notas) {
        final map = <int, Nota>{};
        for (final n in notas) {
          if (n.libroId == libroId && n.capitulo == capitulo) {
            map[n.numero] = n;
          }
        }
        return map;
      },
      orElse: () => <int, Nota>{},
    );

    // C5+C6: batch de conteos de cross-refs para el capítulo actual.
    // Una sola query retorna `Map<versiculo, count>` para todos los
    // versículos con refs. Versículos sin refs NO aparecen en el
    // mapa (el caller trata ausencia como 0). Esto evita las 176
    // queries individuales que tendríamos con un loop por versículo.
    final refCountsAsync = ref.watch(
      crossRefCountsProvider(ChapterQuery(libroId: libroId, capitulo: capitulo)),
    );
    final refCountsEnCapitulo = refCountsAsync.valueOrNull ?? const <int, int>{};

    return FutureBuilder<Capitulo?>(
      future: bibliaRepo.getCapitulo(libroId, capitulo),
      builder: (context, capSnap) {
        if (!capSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cap = capSnap.data!;
        return FutureBuilder<List<Versiculo>>(
          future: bibliaRepo.getVersiculosByCapitulo(cap.id),
          builder: (context, versSnap) {
            if (!versSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final versiculos = versSnap.data!;
            final total = cap.totalVersiculos;

            // Auto-scroll al versículo actual la primera vez (o si cambia).
            if (currentVerse != _lastScrolledVerse &&
                _itemController.isAttached &&
                currentVerse >= 1 &&
                currentVerse <= total) {
              _lastScrolledVerse = currentVerse;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _itemController.scrollTo(
                  index: currentVerse - 1,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                );
              });
            }

            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(appearance.fontScale),
              ),
              child: ScrollablePositionedList.builder(
                itemCount: total,
                itemScrollController: _itemController,
                itemBuilder: (context, index) {
                  final numero = index + 1;
                  // Si getVersiculos devuelve menos, fallback al texto vacío.
                  final texto = index < versiculos.length
                      ? versiculos[index].texto
                      : '';
                  // Feature #3: swipe-to-reveal para cambiar a verse mode.
                  return _SwipeableVerseCard(
                    numero: numero,
                    texto: texto,
                    esFoco: numero == currentVerse,
                    esFavorito: favoritosEnCapitulo.contains(numero),
                    nota: notasEnCapitulo[numero],
                    crossRefCount: refCountsEnCapitulo[numero],
                    fontFamily: appearance.fontFamily,
                    textColor: appearance.textColor,
                    backgroundColor: appearance.backgroundColor,
                    lineHeight: appearance.lineHeight,
                    onTap: () {
                      ref.read(currentVerseProvider.notifier).state = numero;
                      ref
                          .read(currentVersiculoNumeroProvider.notifier)
                          .state = numero;
                    },
                    onLongPress: () {
                      _openNoteEditorForVerse(context, ref, numero, libroId, capitulo, notasEnCapitulo[numero]);
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// Feature #3: VerseCard envuelto en Dismissible para swipe-to-reveal.
///
/// Swipe izquierda → cambia a verse mode en ese versículo (si tiene refs).
/// Swipe en versículo sin refs → snap back (sin acción).
/// Doble tap → toggle favorito. Long press → abrir NoteEditorModal.
class _SwipeableVerseCard extends ConsumerWidget {
  const _SwipeableVerseCard({
    required this.numero,
    required this.texto,
    required this.esFoco,
    required this.esFavorito,
    this.nota,
    this.crossRefCount,
    this.fontFamily,
    this.textColor,
    this.backgroundColor,
    this.lineHeight,
    this.onTap,
    this.onLongPress,
  });

  final int numero;
  final String texto;
  final bool esFoco;
  final bool esFavorito;
  final Nota? nota;
  final int? crossRefCount;
  final String? fontFamily;
  final Color? textColor;
  final Color? backgroundColor;
  final double? lineHeight;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onDoubleTap: () => _toggleFavorito(context, ref),
      child: Dismissible(
        key: ValueKey('verse_$numero'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: colorScheme.primaryContainer,
          child: Icon(
            Icons.arrow_forward_ios,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        confirmDismiss: (direction) async {
          // Solo cambiar a verse mode si el versículo tiene cross-refs.
          if (crossRefCount == null || crossRefCount == 0) return false;
          // Actualizar providers y cambiar a verse mode.
          ref.read(currentVersiculoNumeroProvider.notifier).state = numero;
          ref.read(currentVerseProvider.notifier).state = numero;
          ref.read(readerViewModeProvider.notifier).setViewMode(
                BibleReaderViewMode.verse,
              );
          // Retornar false para que NO se elimine (solo cambia de modo).
          return false;
        },
        child: VerseCard(
          numero: numero,
          texto: texto,
          esFoco: esFoco,
          esFavorito: esFavorito,
          notaIndicatorColor: nota != null ? _colorForNota(nota!.color) : null,
          crossRefCount: crossRefCount,
          fontFamily: fontFamily,
          textColor: textColor,
          backgroundColor: backgroundColor,
          lineHeight: lineHeight,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    );
  }

  /// Toggle favorito con feedback háptico.
  Future<void> _toggleFavorito(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(favoritosRepositoryProvider);
    final versionId = ref.read(currentVersionIdProvider);
    final libroId = ref.read(currentLibroIdProvider)!;
    final capitulo = ref.read(currentCapituloProvider)!;
    final isFav = await repo.isFavorito(
      versionId,
      libroId,
      capitulo,
      numero,
    );
    if (isFav) {
      await repo.remove(versionId, libroId, capitulo, numero);
    } else {
      await repo.add(versionId, libroId, capitulo, numero);
    }
    HapticFeedback.mediumImpact();
  }
}

/// Abre el NoteEditorModal para un versículo en chapter mode.
void _openNoteEditorForVerse(
  BuildContext context,
  WidgetRef ref,
  int numero,
  int libroId,
  int capitulo,
  Nota? existingNote,
) {
  final versionId = ref.read(currentVersionIdProvider);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => NoteEditorModal(
      versionId: versionId,
      libroId: libroId,
      capitulo: capitulo,
      versiculoNumero: numero,
      existingNote: existingNote,
    ),
  );
}

class _AppBarTitle extends ConsumerWidget {
  const _AppBarTitle({required this.libroId, required this.capitulo});

  final int libroId;
  final int capitulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bibliaRepo = ref.read(bibliaRepositoryProvider);
    return FutureBuilder<Libro?>(
      future: bibliaRepo.getLibroById(libroId),
      builder: (context, snap) {
        final libro = snap.data;
        if (libro == null) {
          return const Text('...');
        }
        return Text('${libro.nombre} $capitulo');
      },
    );
  }
}

class _VersionSelector extends ConsumerWidget {
  const _VersionSelector({required this.versionId});

  final int versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final versionsAsync = ref.watch(activeBibliaVersionsProvider);
    return versionsAsync.maybeWhen(
      data: (versions) {
        final current = versions.firstWhere(
          (v) => v.id == versionId,
          orElse: () => versions.first,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => VersionPickerSheet.show(
                context: context,
                versions: versions,
                currentVersionId: versionId,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      current.abreviatura,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ChapterProgress extends ConsumerWidget {
  const _ChapterProgress({
    required this.libroId,
    required this.capitulo,
    required this.versiculoNum,
  });

  final int libroId;
  final int capitulo;
  final int versiculoNum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsAsync = ref.watch(capitulosProvider(libroId));
    final totalVersiculos = capsAsync.maybeWhen(
      data: (caps) {
        final cap = caps.firstWhere(
          (c) => c.numero == capitulo,
          orElse: () => Capitulo(
            id: 0,
            libroId: libroId,
            numero: capitulo,
            totalVersiculos: 1,
          ),
        );
        return cap.totalVersiculos;
      },
      orElse: () => 1,
    );
    final progress = totalVersiculos == 0
        ? 0.0
        : (versiculoNum / totalVersiculos).clamp(0.0, 1.0);
    return LinearProgressIndicator(
      value: progress,
      minHeight: 3,
      backgroundColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      valueColor: AlwaysStoppedAnimation<Color>(
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }
}

class _VerseDisplay extends ConsumerWidget {
  const _VerseDisplay({
    required this.libroId,
    required this.capitulo,
    required this.versiculoNum,
  });

  final int libroId;
  final int capitulo;
  final int versiculoNum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final versionId = ref.watch(currentVersionIdProvider);
    final appearance = ref.watch(bibleAppearanceProvider);
    final bibliaRepo = ref.read(bibliaRepositoryProvider);
    final capsAsync = ref.watch(capitulosProvider(libroId));
    final totalVersiculos = capsAsync.maybeWhen(
      data: (caps) {
        final cap = caps.firstWhere(
          (c) => c.numero == capitulo,
          orElse: () => Capitulo(
            id: 0,
            libroId: libroId,
            numero: capitulo,
            totalVersiculos: 1,
          ),
        );
        return cap.totalVersiculos;
      },
      orElse: () => 1,
    );

    return FutureBuilder<Capitulo?>(
      future: bibliaRepo.getCapitulo(libroId, capitulo),
      builder: (context, capSnap) {
        if (!capSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cap = capSnap.data;
        if (cap == null) {
          return const Center(child: Text('Capítulo no encontrado'));
        }
        return FutureBuilder<List<Versiculo>>(
          future: bibliaRepo.getVersiculosByCapitulo(cap.id),
          builder: (context, versSnap) {
            if (!versSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final versiculos = versSnap.data!;
            if (versiculos.isEmpty) {
              return const Center(child: Text('Sin versículos'));
            }
            final current = versiculos.firstWhere(
              (v) => v.numero == versiculoNum,
              orElse: () => versiculos.first,
            );
            return GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < -200) {
                  _goNext(ref);
                } else if (v > 200) {
                  _goPrev(ref);
                }
              },
              onLongPress: () => _showLongPressMenu(context, ref, current),
              onDoubleTap: () => _toggleFavorito(context, ref, current),
              child: Container(
                color: appearance.backgroundColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capítulo $capitulo',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        backgroundColor: appearance.backgroundColor,
                        child: _VerseCard(
                          versionId: versionId,
                          libroId: libroId,
                          capitulo: capitulo,
                          versiculo: current,
                          totalVersiculos: totalVersiculos,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (versiculoNum == totalVersiculos)
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _goNextChapter(context, ref, libroId),
                            icon: const Icon(Icons.skip_next_rounded),
                            label: const Text('Siguiente capítulo'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _goNext(WidgetRef ref) {
    final caps = ref.read(capitulosProvider(libroId)).valueOrNull;
    if (caps == null) return;
    final cap = caps.firstWhere(
      (c) => c.numero == capitulo,
      orElse: () => caps.first,
    );
    if (versiculoNum < cap.totalVersiculos) {
      ref.read(currentVersiculoNumeroProvider.notifier).state =
          versiculoNum + 1;
    } else {
      _goNextChapter(ref.context, ref, libroId);
    }
  }

  void _goPrev(WidgetRef ref) {
    if (versiculoNum > 1) {
      ref.read(currentVersiculoNumeroProvider.notifier).state =
          versiculoNum - 1;
    }
  }

  Future<void> _goNextChapter(
    BuildContext context,
    WidgetRef ref,
    int currentLibroId,
  ) async {
    final caps = ref.read(capitulosProvider(currentLibroId)).valueOrNull;
    if (caps == null) return;
    final maxCap = caps.map((c) => c.numero).reduce((a, b) => a > b ? a : b);
    if (capitulo < maxCap) {
      ref.read(currentCapituloProvider.notifier).state = capitulo + 1;
      ref.read(currentVersiculoNumeroProvider.notifier).state = 1;
      return;
    }
    // Último capítulo del libro → siguiente libro
    final biblia = ref.read(bibliaRepositoryProvider);
    final libro = await biblia.getLibroById(currentLibroId);
    if (libro == null || !context.mounted) return;
    final allLibros = await biblia.getLibrosByVersion(libro.versionId);
    final idx = allLibros.indexWhere((l) => l.id == libro.id);
    if (idx == -1 || idx + 1 >= allLibros.length) return;
    final nextLibro = allLibros[idx + 1];
    if (!context.mounted) return;
    ref.read(currentLibroIdProvider.notifier).state = nextLibro.id;
    ref.read(currentLibroNumeroProvider.notifier).state = nextLibro.numero;
    ref.read(currentCapituloProvider.notifier).state = 1;
    ref.read(currentVersiculoNumeroProvider.notifier).state = 1;
  }

  void _showLongPressMenu(
    BuildContext context,
    WidgetRef ref,
    Versiculo current,
  ) {
    // v1.0.4b: abrir NoteEditorModal directamente sin menú intermedio.
    final versionId = ref.read(currentVersionIdProvider);
    final notaAsync = ref.read(
      currentNotaProvider(
        NotaQuery(
          versionId: versionId,
          libroId: libroId,
          capitulo: capitulo,
          numero: current.numero,
        ),
      ),
    );
    final existingNote = notaAsync.valueOrNull;
    _openNoteEditor(context, ref, current, existingNote: existingNote);
  }

  Future<void> _toggleFavorito(
    BuildContext context,
    WidgetRef ref,
    Versiculo current,
  ) async {
    final repo = ref.read(favoritosRepositoryProvider);
    final versionId = ref.read(currentVersionIdProvider);
    final isFav = await repo.isFavorito(
      versionId,
      libroId,
      capitulo,
      current.numero,
    );
    if (isFav) {
      await repo.remove(versionId, libroId, capitulo, current.numero);
    } else {
      await repo.add(versionId, libroId, capitulo, current.numero);
    }
    HapticFeedback.mediumImpact();
  }

  void _openNoteEditor(
    BuildContext context,
    WidgetRef ref,
    Versiculo current, {
    Nota? existingNote,
  }) {
    final versionId = ref.read(currentVersionIdProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorModal(
        versionId: versionId,
        libroId: libroId,
        capitulo: capitulo,
        versiculoNumero: current.numero,
        existingNote: existingNote,
      ),
    );
  }
}

class _VerseCard extends ConsumerWidget {
  const _VerseCard({
    required this.versionId,
    required this.libroId,
    required this.capitulo,
    required this.versiculo,
    required this.totalVersiculos,
  });

  final int versionId;
  final int libroId;
  final int capitulo;
  final Versiculo versiculo;
  final int totalVersiculos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appearance = ref.watch(bibleAppearanceProvider);

    final notaAsync = ref.watch(
      currentNotaProvider(
        NotaQuery(
          versionId: versionId,
          libroId: libroId,
          capitulo: capitulo,
          numero: versiculo.numero,
        ),
      ),
    );
    final nota = notaAsync.valueOrNull;

    // Verificar si el versículo actual es favorito.
    final favoritosAsync = ref.watch(favoritosStreamProvider);
    final esFavorito = favoritosAsync.maybeWhen(
      data: (list) => list.any(
        (f) =>
            f.libroId == libroId &&
            f.capitulo == capitulo &&
            f.numero == versiculo.numero,
      ),
      orElse: () => false,
    );

    final showBorder = nota != null && nota.color != NotaColor.ninguno;

    final textStyle = textTheme.bodyLarge?.copyWith(
      fontSize: 18,
      height: appearance.lineHeight,
      color: appearance.textColor,
      fontFamily: appearance.fontFamily == 'system'
          ? null
          : appearance.fontFamily,
    );

    final numeroStyle = textTheme.titleLarge?.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w800,
      fontSize: 24,
      fontFamily: appearance.fontFamily == 'system'
          ? null
          : appearance.fontFamily,
    );

    final progressStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontFamily: appearance.fontFamily == 'system'
          ? null
          : appearance.fontFamily,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(appearance.fontScale),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showBorder) ...[
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _colorForNota(nota.color),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${versiculo.numero}',
                        style: numeroStyle,
                      ),
                      const SizedBox(width: 12),
                      if (nota != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _colorForNota(nota.color)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: _colorForNota(nota.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tiene nota',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _colorForNota(nota.color),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Indicador de favorito en modo versículo.
                      if (esFavorito) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    versiculo.texto,
                    style: textStyle,
                  ),
                  // C4: cross-references inline (verse mode).
                  // Se muestra ENTRE el texto y la nota, con loading
                  // silencioso (no spinner) y fallback silencioso en
                  // error para no romper la lectura.
                  ReferenciasCruzadasSection(
                    libroId: libroId,
                    capitulo: capitulo,
                    versiculo: versiculo.numero,
                  ),
                  // B1: preview de nota inline (verse mode).
                  if (nota != null) ...[
                    const SizedBox(height: 12),
                    _NotaPreview(
                      key: ValueKey('nota_preview_${versiculo.numero}'),
                      nota: nota,
                      onTap: () => _openNoteEditorInline(context, ref, nota),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${versiculo.numero}/$totalVersiculos',
                    style: progressStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre el modal de edición de nota con la nota existente precargada.
  void _openNoteEditorInline(
    BuildContext context,
    WidgetRef ref,
    Nota nota,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorModal(
        versionId: versionId,
        libroId: libroId,
        capitulo: capitulo,
        versiculoNumero: versiculo.numero,
        existingNote: nota,
      ),
    );
  }
}

/// Preview inline de una nota en verse mode.
///
/// A5: Card con tinted background del color de la nota (alpha 0.12),
/// borde lateral 2dp, botón 'Editar' visible, y max 5 líneas con
/// ellipsis. Usa `GestureDetector` (no `InkWell`) para no robar el
/// `onLongPress` del wrapper de la card.
class _NotaPreview extends StatelessWidget {
  const _NotaPreview({
    super.key,
    required this.nota,
    required this.onTap,
  });

  final Nota nota;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorForNota(nota.color);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Editar nota',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Card(
          // A5: tinted background en vez de borde-only.
          color: color.withValues(alpha: 0.12),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tu nota',
                      style: textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Editar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  nota.contenido,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Convierte [NotaColor] a [Color] de Flutter.
Color _colorForNota(NotaColor color) {
  switch (color) {
    case NotaColor.amarillo:
      return const Color(0xFFF59E0B);
    case NotaColor.verde:
      return const Color(0xFF10B981);
    case NotaColor.azul:
      return const Color(0xFF3B82F6);
    case NotaColor.ninguno:
      return Colors.transparent;
  }
}

class _ReaderBottomBar extends ConsumerWidget {
  const _ReaderBottomBar({
    required this.libroId,
    required this.capitulo,
    required this.versiculoNum,
  });

  final int libroId;
  final int capitulo;
  final int versiculoNum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          // v1.0.4b: 2 filas — navegación arriba, acción abajo.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila 1: navegación (Anterior | Capítulo | Siguiente | Tabla)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () => _goPrevChapter(context, ref),
                    tooltip: 'Capítulo anterior',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () {
                      if (versiculoNum > 1) {
                        ref
                            .read(currentVersiculoNumeroProvider.notifier)
                            .state = versiculoNum - 1;
                      }
                    },
                    tooltip: 'Versículo anterior',
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$versiculoNum',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () => _goNextVerse(ref),
                    tooltip: 'Versículo siguiente',
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () => _goNextChapter(context, ref),
                    tooltip: 'Capítulo siguiente',
                  ),
                  // Toggle verse/chapter mode.
                  const _ViewModeToggleButton(),
                ],
              ),
              const Divider(height: 4, thickness: 0.5),
              // Fila 2: acción (Nota | Configuración | Pantalla completa)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nota: acceso directo al NoteEditorModal.
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () => _openNoteFromBottomBar(context, ref),
                    tooltip: 'Agregar nota',
                  ),
                  // Configuración.
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () => ReadingSettingsSheet.show(context),
                    tooltip: 'Ajustes de lectura',
                  ),
                  // Fullscreen toggle.
                  Consumer(
                    builder: (context, ref, _) {
                      final isFullscreen = ref.watch(fullscreenModeProvider);
                      return IconButton(
                        icon: Icon(
                          isFullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          size: 20,
                        ),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: isFullscreen
                            ? 'Salir de pantalla completa'
                            : 'Pantalla completa',
                        onPressed: () {
                          if (isFullscreen) {
                            ref
                                .read(fullscreenModeProvider.notifier)
                                .exitFullscreen();
                          } else {
                            ref
                                .read(fullscreenModeProvider.notifier)
                                .enterFullscreen();
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abre NoteEditorModal desde el bottom bar (accesibilidad).
  void _openNoteFromBottomBar(BuildContext context, WidgetRef ref) {
    final versionId = ref.read(currentVersionIdProvider);
    final notaAsync = ref.read(
      currentNotaProvider(
        NotaQuery(
          versionId: versionId,
          libroId: libroId,
          capitulo: capitulo,
          numero: versiculoNum,
        ),
      ),
    );
    final existingNote = notaAsync.valueOrNull;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorModal(
        versionId: versionId,
        libroId: libroId,
        capitulo: capitulo,
        versiculoNumero: versiculoNum,
        existingNote: existingNote,
      ),
    );
  }

  void _goNextVerse(WidgetRef ref) {
    final caps = ref.read(capitulosProvider(libroId)).valueOrNull;
    if (caps == null) return;
    final cap = caps.firstWhere(
      (c) => c.numero == capitulo,
      orElse: () => caps.first,
    );
    if (versiculoNum < cap.totalVersiculos) {
      ref.read(currentVersiculoNumeroProvider.notifier).state =
          versiculoNum + 1;
    } else {
      ref.read(currentCapituloProvider.notifier).state = capitulo + 1;
      ref.read(currentVersiculoNumeroProvider.notifier).state = 1;
    }
  }

  Future<void> _goNextChapter(BuildContext context, WidgetRef ref) async {
    final caps = ref.read(capitulosProvider(libroId)).valueOrNull;
    if (caps == null) return;
    final maxCap = caps.map((c) => c.numero).reduce((a, b) => a > b ? a : b);
    if (capitulo < maxCap) {
      ref.read(currentCapituloProvider.notifier).state = capitulo + 1;
      ref.read(currentVersiculoNumeroProvider.notifier).state = 1;
      return;
    }
    final biblia = ref.read(bibliaRepositoryProvider);
    final libro = await biblia.getLibroById(libroId);
    if (libro == null || !context.mounted) return;
    final allLibros = await biblia.getLibrosByVersion(libro.versionId);
    final idx = allLibros.indexWhere((l) => l.id == libro.id);
    if (idx == -1 || idx + 1 >= allLibros.length) return;
    final nextLibro = allLibros[idx + 1];
    if (!context.mounted) return;
    ref.read(currentLibroIdProvider.notifier).state = nextLibro.id;
    ref.read(currentLibroNumeroProvider.notifier).state = nextLibro.numero;
    ref.read(currentCapituloProvider.notifier).state = 1;
    ref.read(currentVersiculoNumeroProvider.notifier).state = 1;
  }

  Future<void> _goPrevChapter(BuildContext context, WidgetRef ref) async {
    if (capitulo > 1) {
      ref.read(currentCapituloProvider.notifier).state = capitulo - 1;
      ref.read(currentVersiculoNumeroProvider.notifier).state = 1;
      return;
    }
    final biblia = ref.read(bibliaRepositoryProvider);
    final libro = await biblia.getLibroById(libroId);
    if (libro == null || !context.mounted) return;
    final allLibros = await biblia.getLibrosByVersion(libro.versionId);
    final idx = allLibros.indexWhere((l) => l.id == libro.id);
    if (idx <= 0 || !context.mounted) return;
    final prevLibro = allLibros[idx - 1];
    final prevCaps = await biblia.getCapitulosByLibro(prevLibro.id);
    if (prevCaps.isEmpty || !context.mounted) return;
    ref.read(currentLibroIdProvider.notifier).state = prevLibro.id;
    ref.read(currentLibroNumeroProvider.notifier).state = prevLibro.numero;
    ref.read(currentCapituloProvider.notifier).state = prevCaps.last.numero;
    ref.read(currentVersiculoNumeroProvider.notifier).state = 1;
  }
}

/// Botón "ENVIAR" en el AppBar: envía el versículo actual al display
/// remoto. Solo es visible cuando hay un emisor conectado.
class _EnviarButton extends ConsumerWidget {
  const _EnviarButton({
    required this.libroId,
    required this.capitulo,
    required this.versiculoNum,
  });

  final int libroId;
  final int capitulo;
  final int versiculoNum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedProvider);
    if (!isConnected) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: () async {
          // Asegurar que el libroNumero cacheado corresponde al libroId actual.
          final repo = ref.read(bibliaRepositoryProvider);
          final libro = await repo.getLibroById(libroId);
          if (libro != null) {
            ref.read(currentLibroNumeroProvider.notifier).state = libro.numero;
          }
          try {
            final actions = ref.read(bibleClientActionsProvider);
            final ok = await actions.sendCurrentVerse();
            showAppSnackBar(
              context,
              ok ? 'Enviado al display' : 'Display rechazó el envío',
              duration: const Duration(seconds: 2),
              type: ok ? AppSnackBarType.success : AppSnackBarType.warning,
            );
          } catch (e) {
            showAppSnackBar(
              context,
              'Error al enviar: $e',
              type: AppSnackBarType.error,
            );
          }
        },
        icon: Icon(
          Icons.cast_rounded,
          color: colorScheme.primary,
          size: 18,
        ),
        label: const Text('ENVIAR'),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Menú overflow del Bible reader: modo de vista del emisor y
/// cross-module "Ir a Himnario".
class _ReaderOverflowMenu extends ConsumerWidget {
  const _ReaderOverflowMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_ReaderMenuAction>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Más opciones',
      onSelected: (action) => _handleAction(context, ref, action),
      itemBuilder: (ctx) {
        final currentMode = ref.watch(currentEmitterViewModeProvider);
        return [
          const PopupMenuItem(
            value: _ReaderMenuAction.modeCompact,
            child: ListTile(
              leading: Icon(Icons.short_text_rounded),
              title: Text('Modo Compact'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: _ReaderMenuAction.modePreview,
            child: ListTile(
              leading: Icon(Icons.article_outlined),
              title: Text('Modo Preview'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (currentMode == 'compact')
            const PopupMenuItem(
              enabled: false,
              child: ListTile(
                leading: Icon(Icons.short_text_rounded, color: Colors.grey),
                title: Text(
                  'Modo Compact (actual)',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (currentMode == 'preview')
            const PopupMenuItem(
              enabled: false,
              child: ListTile(
                leading: Icon(Icons.article_outlined, color: Colors.grey),
                title: Text(
                  'Modo Preview (actual)',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _ReaderMenuAction.goHymnal,
            child: ListTile(
              leading: Icon(Icons.music_note_rounded),
              title: Text('Ir a Himnario'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ];
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _ReaderMenuAction action,
  ) async {
    switch (action) {
      case _ReaderMenuAction.modeCompact:
        ref.read(currentEmitterViewModeProvider.notifier).state = 'compact';
        // Notificar al display si hay conexión.
        if (ref.read(isConnectedProvider)) {
          try {
            await ref
                .read(bibleClientActionsProvider)
                .setViewMode(EmitterViewMode.VIEW_MODE_COMPACT);
          } catch (_) {}
        }
        if (context.mounted) {
          showAppSnackBar(
            context,
            'Modo Compact',
            duration: const Duration(seconds: 1),
          );
        }
        break;
      case _ReaderMenuAction.modePreview:
        ref.read(currentEmitterViewModeProvider.notifier).state = 'preview';
        if (ref.read(isConnectedProvider)) {
          try {
            await ref
                .read(bibleClientActionsProvider)
                .setViewMode(EmitterViewMode.VIEW_MODE_PREVIEW);
          } catch (_) {}
        }
        if (context.mounted) {
          showAppSnackBar(
            context,
            'Modo Preview',
            duration: const Duration(seconds: 1),
          );
        }
        break;
      case _ReaderMenuAction.goHymnal:
        // Cross-module: switch al himnario y, si hay display conectado,
        // enviar SWITCH_TO_HIMNAL.
        if (ref.read(isConnectedProvider)) {
          try {
            await ref.read(bibleClientActionsProvider).switchToHymnal();
          } catch (_) {}
        }
        if (context.mounted) context.goNamed('himnario');
        break;
    }
  }
}

enum _ReaderMenuAction { modeCompact, modePreview, goHymnal }
