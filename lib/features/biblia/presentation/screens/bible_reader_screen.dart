import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/ui/app_snackbar.dart';
import '../../../../presentation/shared_widgets/glass_card.dart';
import '../../../../proto/generated/hymn_control.pbgrpc.dart';
import '../../../../presentation/views_projection/providers/connection_providers.dart';
import '../../application/providers/bible_grpc_client_provider.dart';
import '../../application/providers/biblia_version_provider.dart';
import '../../application/providers/bible_appearance_provider.dart';
import '../../application/providers/biblia_config_provider.dart';
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
import '../widgets/verse_card.dart';
import '../widgets/reading_settings_sheet.dart';
import '../widgets/version_picker_sheet.dart';

/// Pantalla principal del Bible reader: muestra 1 versículo a la vez.
///
/// Referencia: `doc/wireframes/02_bible_module.md` (Pantalla 2c).
class BibleReaderScreen extends ConsumerStatefulWidget {
  const BibleReaderScreen({
    super.key,
    required this.libroId,
    required this.capitulo,
  });

  final int libroId;
  final int capitulo;

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  int? _lastRecordedVersiculo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(currentLibroIdProvider.notifier).state = widget.libroId;
      ref.read(currentCapituloProvider.notifier).state = widget.capitulo;
      final currentNum = ref.read(currentVersiculoNumeroProvider);
      if (currentNum == null) {
        ref.read(currentVersiculoNumeroProvider.notifier).state = 1;
      }
      // Inicializar currentVerseProvider (vista de capítulo) con el
      // versículo actual (default 1) para que el scroll programático
      // arranque en la posición correcta.
      ref.read(currentVerseProvider.notifier).state =
          ref.read(currentVersiculoNumeroProvider) ?? 1;
      // Resolver libroId → libroNumero (canónico) y cachearlo para el
      // cliente gRPC (BibleClientActions lo lee al enviar comandos).
      _syncLibroNumeroFromId(widget.libroId);
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

  @override
  Widget build(BuildContext context) {
    final versionId = ref.watch(currentVersionIdProvider);
    final libroId = ref.watch(currentLibroIdProvider) ?? widget.libroId;
    final capitulo = ref.watch(currentCapituloProvider) ?? widget.capitulo;
    final versiculoNum = ref.watch(currentVersiculoNumeroProvider) ?? 1;

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
    });

    return Scaffold(
      appBar: AppBar(
        title: _AppBarTitle(libroId: libroId, capitulo: capitulo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Atrás',
        ),
        actions: [
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
          // D6: alternar entre vista por versículo y vista de capítulo.
          const _ViewModeToggleButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
            _ReaderBottomBar(
              libroId: libroId,
              capitulo: capitulo,
              versiculoNum: versiculoNum,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón en el AppBar que alterna entre vista por versículo y vista de capítulo.
class _ViewModeToggleButton extends ConsumerWidget {
  const _ViewModeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(readerViewModeProvider);
    final isChapter = viewMode == BibleReaderViewMode.chapter;
    return IconButton(
      icon: Icon(
        isChapter ? Icons.view_agenda_outlined : Icons.view_headline_rounded,
      ),
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
    final versionId = ref.watch(currentVersionIdProvider);
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

    // O7b: mapa de número de versículo → color de nota para el capítulo actual.
    final notasAsync = ref.watch(notasStreamProvider);
    final notasEnCapitulo = notasAsync.maybeWhen(
      data: (notas) {
        final map = <int, Color>{};
        for (final n in notas) {
          if (n.libroId == libroId && n.capitulo == capitulo) {
            map[n.numero] = _colorForNota(n.color);
          }
        }
        return map;
      },
      orElse: () => <int, Color>{},
    );

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
                  return VerseCard(
                    numero: numero,
                    texto: texto,
                    esFoco: numero == currentVerse,
                    esFavorito: favoritosEnCapitulo.contains(numero),
                    notaIndicatorColor: notasEnCapitulo[numero],
                    fontFamily: appearance.fontFamily,
                    textColor: appearance.textColor,
                    lineHeight: appearance.lineHeight,
                    onTap: () {
                      ref.read(currentVerseProvider.notifier).state = numero;
                      ref
                          .read(currentVersiculoNumeroProvider.notifier)
                          .state = numero;
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

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copiar'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: current.texto));
                showAppSnackBar(context, 'Copiado al portapapeles');
              },
            ),
            ListTile(
              leading: Icon(
                existingNote != null
                    ? Icons.edit_rounded
                    : Icons.edit_note_rounded,
              ),
              title: Text(
                existingNote != null ? 'Editar nota' : 'Agregar nota',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _openNoteEditor(
                  context,
                  ref,
                  current,
                  existingNote: existingNote,
                );
              },
            ),
          ],
        ),
      ),
    );
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    versiculo.texto,
                    style: textStyle,
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
/// Renderiza un mini-card con borde izquierdo 3dp del color de la nota,
/// el texto truncado a 3 líneas, y un `GestureDetector` que abre el
/// editor al tap. Usa `GestureDetector` (no `InkWell`) para no robar
/// el `onLongPress` del wrapper de la card.
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
    return Semantics(
      label: 'Editar nota',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: color, width: 3),
            ),
          ),
          child: Text(
            nota.contenido,
            style: textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => _goPrevChapter(context, ref),
                    tooltip: 'Capítulo anterior',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
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
                    onPressed: () => _goNextVerse(ref),
                    tooltip: 'Versículo siguiente',
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () => _goNextChapter(context, ref),
                    tooltip: 'Capítulo siguiente',
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FavoriteToggle(
                    libroId: libroId,
                    capitulo: capitulo,
                    versiculoNum: versiculoNum,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded),
                    onPressed: () => _openNoteEditor(context, ref),
                    tooltip: 'Nota',
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => ReadingSettingsSheet.show(context),
                    tooltip: 'Ajustes de lectura',
                  ),
                ],
              ),
            ],
          ),
        ),
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

  void _openNoteEditor(BuildContext context, WidgetRef ref) {
    final versionId = ref.read(currentVersionIdProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorModal(
        versionId: versionId,
        libroId: libroId,
        capitulo: capitulo,
        versiculoNumero: versiculoNum,
      ),
    );
  }
}

class _FavoriteToggle extends ConsumerWidget {
  const _FavoriteToggle({
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
    final versionId = ref.watch(currentVersionIdProvider);
    final favoritosAsync = ref.watch(favoritosStreamProvider);
    final isFav = favoritosAsync.maybeWhen(
      data: (list) => list.any(
        (f) =>
            f.versionId == versionId &&
            f.libroId == libroId &&
            f.capitulo == capitulo &&
            f.numero == versiculoNum,
      ),
      orElse: () => false,
    );
    return IconButton(
      icon: Icon(
        isFav ? Icons.star_rounded : Icons.star_outline_rounded,
        color: isFav ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      onPressed: () async {
        final repo = ref.read(favoritosRepositoryProvider);
        if (isFav) {
          await repo.remove(versionId, libroId, capitulo, versiculoNum);
        } else {
          await repo.add(versionId, libroId, capitulo, versiculoNum);
        }
      },
      tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
    );
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
