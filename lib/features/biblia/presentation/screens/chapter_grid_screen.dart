import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/shared_widgets/glass_card.dart';
import '../../../../presentation/dual_mode_wrapper/dual_mode_providers.dart';
import '../../application/providers/biblia_version_provider.dart';
import '../../application/providers/current_libro_provider.dart';
import '../../application/providers/current_versiculo_provider.dart';
import '../../application/providers/derived_providers.dart';
import '../../application/providers/favoritos_provider.dart';
import '../../data/models/capitulo.dart';
import '../../data/models/libro.dart';

/// Pantalla con el grid de capítulos de un libro.
///
/// Referencia: `doc/wireframes/02_bible_module.md` (Pantalla 2b).
///
/// Al tap en un capítulo, navega al [BibleReaderScreen] en modo `chapter`
/// (default desde v1.0.2), donde el usuario puede ver todos los versículos
/// y tocar el que quiera (auto-scroll + foco automático vía
/// `currentVerseProvider`).
class ChapterGridScreen extends ConsumerWidget {
  const ChapterGridScreen({super.key, required this.libroId});

  final int libroId;

  void _navigateToChapter(BuildContext context, WidgetRef ref, int chapterNum) {
    ref.read(currentLibroIdProvider.notifier).state = libroId;
    ref.read(currentCapituloProvider.notifier).state = chapterNum;
    // Resetear versículo a 1 al cambiar de capítulo — si no se resetea,
    // el reader hereda el versículo del capítulo anterior y hace focus
    // en el mismo número en vez de empezar desde el versículo 1.
    ref.read(currentVersiculoNumeroProvider.notifier).state = 1;
    // El reader abre en modo `chapter` (default) y muestra todos los
    // versículos del capítulo. El usuario hace tap en el que quiere leer;
    // `_ChapterVerseList` hace auto-scroll al versículo target vía
    // `currentVerseProvider`.
    context.pushNamed(
      'biblia_reader',
      pathParameters: {
        'libroId': '$libroId',
        'capitulo': '$chapterNum',
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final versionId = ref.watch(currentVersionIdProvider);

    // Cargar libro para mostrar el nombre en el AppBar
    final libroRepo = ref.read(bibliaRepositoryProvider);
    final libroFuture = libroRepo.getLibroById(libroId);
    final capsFuture = ref.watch(capitulosProvider(libroId));
    final lastReadCap = ref.watch(
      lastReadCapituloProvider(
        LastReadQuery(versionId: versionId, libroId: libroId),
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
            const SizedBox(height: 12),
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
                    onChapterTap: (cap) =>
                        _navigateToChapter(context, ref, cap.numero),
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
                    _navigateToChapter(context, ref, random.numero);
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

/// Grid de capítulos responsivo.
///
/// Desktop: hasta 10 columnas según ancho. Móvil: 5 columnas fijas.
/// Padding y espaciado reducidos a la mitad en desktop.
class _ChapterGrid extends ConsumerWidget {
  const _ChapterGrid({
    required this.capitulos,
    required this.lastReadCapitulo,
    required this.onChapterTap,
  });

  final List<Capitulo> capitulos;
  final int? lastReadCapitulo;
  final void Function(Capitulo) onChapterTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libroId = capitulos.first.libroId;
    final favChaptersAsync =
        ref.watch(favoritosPorCapituloProvider(libroId));
    final favChapters = favChaptersAsync.valueOrNull ?? const <int>{};
    final isDesktop = ref.watch(isDesktopModeProvider);

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 2 : 16, 8, isDesktop ? 2 : 16, 8,),
      gridDelegate: isDesktop
          ? const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 52,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 0.85,
            )
          : const SliverGridDelegateWithFixedCrossAxisCount(
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
          hasFavorite: favChapters.contains(cap.numero),
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
    required this.hasFavorite,
    required this.onTap,
  });

  final Capitulo capitulo;
  final bool isLastRead;
  final bool hasFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // El favorito tiene prioridad sobre última lectura.
    final isHighlighted = hasFavorite || isLastRead;

    return Semantics(
      label: 'Capítulo ${capitulo.numero}, ${capitulo.totalVersiculos} versículos',
      button: true,
      child: GlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        backgroundColor: hasFavorite
            ? colorScheme.primary
            : (isLastRead
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : null),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${capitulo.numero}',
              style: textTheme.bodyLarge?.copyWith(
                color: isHighlighted
                    ? (hasFavorite
                        ? colorScheme.onPrimary
                        : colorScheme.onPrimaryContainer)
                    : colorScheme.onSurface,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
