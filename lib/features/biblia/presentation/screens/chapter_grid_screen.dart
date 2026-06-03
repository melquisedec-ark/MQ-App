import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/shared_widgets/glass_card.dart';
import '../../application/providers/biblia_version_provider.dart';
import '../../application/providers/current_libro_provider.dart';
import '../../application/providers/current_versiculo_provider.dart';
import '../../application/providers/derived_providers.dart';
import '../../data/models/capitulo.dart';
import '../../data/models/libro.dart';

/// Pantalla con el grid de capítulos de un libro.
///
/// Referencia: `doc/wireframes/02_bible_module.md` (Pantalla 2b).
///
/// O5 — Incluye un selector de número de versículo que permite al usuario
/// elegir un versículo específico antes de navegar al reader.
/// Si el campo está vacío o el valor no es válido, se usa 1 por defecto.
class ChapterGridScreen extends ConsumerStatefulWidget {
  const ChapterGridScreen({super.key, required this.libroId});

  final int libroId;

  @override
  ConsumerState<ChapterGridScreen> createState() => _ChapterGridScreenState();
}

class _ChapterGridScreenState extends ConsumerState<ChapterGridScreen> {
  final _verseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verseController.text = '';
  }

  @override
  void dispose() {
    _verseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChapterGridScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.libroId != widget.libroId) {
      _verseController.text = '';
    }
  }

  /// Parsea el texto del controlador y retorna un número válido de versículo.
  /// Si está vacío o inválido, retorna 1 por defecto.
  int get _verseNumber {
    final text = _verseController.text.trim();
    final parsed = int.tryParse(text);
    return (parsed != null && parsed > 0) ? parsed : 1;
  }

  void _decrementVerse() {
    final current = _verseNumber;
    if (current > 1) {
      _verseController.text = '${current - 1}';
    }
  }

  void _incrementVerse() {
    final current = _verseNumber;
    _verseController.text = '${current + 1}';
  }

  void _navigateToChapter(int chapterNum) {
    final verse = _verseNumber;
    ref.read(currentLibroIdProvider.notifier).state = widget.libroId;
    ref.read(currentCapituloProvider.notifier).state = chapterNum;
    ref.read(currentVersiculoNumeroProvider.notifier).state = verse;
    context.pushNamed(
      'biblia_reader',
      pathParameters: {
        'libroId': '${widget.libroId}',
        'capitulo': '$chapterNum',
      },
    );
    // Reiniciar selector tras navegar (O5)
    _verseController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final versionId = ref.watch(currentVersionIdProvider);

    // Cargar libro para mostrar el nombre en el AppBar
    final libroRepo = ref.read(bibliaRepositoryProvider);
    final libroFuture = libroRepo.getLibroById(widget.libroId);
    final capsFuture = ref.watch(capitulosProvider(widget.libroId));
    final lastReadCap = ref.watch(
      lastReadCapituloProvider(
        LastReadQuery(versionId: versionId, libroId: widget.libroId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Libro?>(
          future: libroFuture,
          builder: (context, snap) {
            if (snap.hasData && snap.data != null) {
              return Text(snap.data!.nombre);
            }
            return const Text('Libro');
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Atrás',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.pushNamed('biblia_search'),
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Selecciona un capítulo',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Selector de número de versículo (O5) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Versículo:',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: _verseController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'n°',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: _decrementVerse,
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Versículo anterior',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: _incrementVerse,
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Versículo siguiente',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: capsFuture.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text('Error al cargar capítulos: $e'),
                ),
                data: (caps) {
                  if (caps.isEmpty) {
                    return const Center(
                      child: Text('No hay capítulos disponibles'),
                    );
                  }
                  final lastRead = lastReadCap.valueOrNull;
                  return _ChapterGrid(
                    capitulos: caps,
                    lastReadCapitulo: lastRead,
                    onChapterTap: (cap) {
                      _navigateToChapter(cap.numero);
                    },
                  );
                },
              ),
            ),
            // Botón "Capítulo aleatorio"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final caps = capsFuture.valueOrNull;
                    if (caps == null || caps.isEmpty) return;
                    final random = caps[math.Random().nextInt(caps.length)];
                    _navigateToChapter(random.numero);
                  },
                  icon: const Icon(Icons.casino_rounded),
                  label: const Text('Capítulo aleatorio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid de capítulos (5 columnas).
class _ChapterGrid extends StatelessWidget {
  const _ChapterGrid({
    required this.capitulos,
    required this.lastReadCapitulo,
    required this.onChapterTap,
  });

  final List<Capitulo> capitulos;
  final int? lastReadCapitulo;
  final void Function(Capitulo) onChapterTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: capitulos.length,
      itemBuilder: (context, index) {
        final cap = capitulos[index];
        return _ChapterCell(
          capitulo: cap,
          isLastRead: cap.numero == lastReadCapitulo,
          onTap: () => onChapterTap(cap),
        );
      },
    );
  }
}

/// Celda individual de capítulo.
class _ChapterCell extends StatelessWidget {
  const _ChapterCell({
    required this.capitulo,
    required this.isLastRead,
    required this.onTap,
  });

  final Capitulo capitulo;
  final bool isLastRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isVisited = isLastRead; // Por ahora solo resaltamos el último

    return Semantics(
      label: 'Capítulo ${capitulo.numero}, ${capitulo.totalVersiculos} versículos',
      button: true,
      child: GlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        backgroundColor: isLastRead
            ? colorScheme.primary
            : (isVisited
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : null),
        child: Center(
          child: Text(
            '${capitulo.numero}',
            style: textTheme.titleMedium?.copyWith(
              color: isLastRead
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
              fontWeight: isLastRead ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
