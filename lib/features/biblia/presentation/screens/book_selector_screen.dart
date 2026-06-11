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
import '../../application/providers/historial_provider.dart';
import '../../application/providers/notas_provider.dart';
import '../../data/models/favorito_versiculo.dart';
import '../../data/models/historial_item.dart';
import '../../data/models/libro.dart';
import '../../data/models/nota.dart';

/// Selector de libros con 5 tabs (AT / NT / Favoritos / Notas / Historial).
///
/// Referencia: `doc/wireframes/02_bible_module.md` (Pantalla 2a).
class BookSelectorScreen extends ConsumerStatefulWidget {
  const BookSelectorScreen({super.key});

  @override
  ConsumerState<BookSelectorScreen> createState() =>
      _BookSelectorScreenState();
}

class _BookSelectorScreenState extends ConsumerState<BookSelectorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblia'),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'AT'),
            Tab(text: 'NT'),
            Tab(text: '⭐ Favoritos'),
            Tab(text: '📝 Notas'),
            Tab(text: '🕐 Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LibrosTab(testamento: Testamento.at),
          _LibrosTab(testamento: Testamento.nt),
          _FavoritosTab(),
          _NotasTab(),
          _HistorialTab(),
        ],
      ),
    );
  }
}

/// Tab con lista de libros de un testamento.
class _LibrosTab extends ConsumerWidget {
  const _LibrosTab({required this.testamento});

  final Testamento testamento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionId = ref.watch(currentVersionIdProvider);
    final isDesktop = ref.watch(isDesktopModeProvider);
    final librosAsync = ref.watch(
      librosProvider(LibrosQuery(versionId: versionId, testamento: testamento)),
    );
    return librosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: 'Error al cargar libros: $e'),
      data: (libros) {
        if (libros.isEmpty) {
          return const _EmptyState(
            icon: Icons.menu_book_rounded,
            title: 'No hay libros disponibles',
            subtitle: '',
          );
        }
        // En desktop: grid responsivo de 3/2 columnas. En móvil: lista simple.
        if (isDesktop) {
          return _LibrosGrid(libros: libros);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: libros.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final libro = libros[index];
            return _LibroTile(libro: libro);
          },
        );
      },
    );
  }
}

/// Grid responsivo de libros para desktop.
///
/// Orden por columnas (vertical): la primera columna tiene Gén, Éxo, Lev...
/// la segunda Núm, Deu, Jos... etc. Se reorganiza la lista antes de pasarla
/// al GridView (que por defecto ordena por filas).
class _LibrosGrid extends ConsumerWidget {
  const _LibrosGrid({required this.libros});

  final List<Libro> libros;

  /// Reorganiza la lista para que el GridView (orden por filas) muestre
  /// los items en orden por columnas (vertical). Calcula correctamente
  /// cuántos items van en cada columna para grids irregulares.
  static List<T> _toColumnMajor<T>(List<T> items, int columns) {
    final n = items.length;
    if (n == 0) return items;
    final baseCount = n ~/ columns;
    final extraCols = n % columns;
    // Calcular inicio y cantidad de cada columna
    final colStarts = <int>[];
    final colCounts = <int>[];
    int offset = 0;
    for (int c = 0; c < columns; c++) {
      colStarts.add(offset);
      final count = baseCount + (c < extraCols ? 1 : 0);
      colCounts.add(count);
      offset += count;
    }
    // Llenar fila por fila
    final maxRows = baseCount + (extraCols > 0 ? 1 : 0);
    final result = <T>[];
    for (int r = 0; r < maxRows; r++) {
      for (int c = 0; c < columns; c++) {
        if (r < colCounts[c]) {
          result.add(items[colStarts[c] + r]);
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1200 ? 5 : width >= 900 ? 4 : width >= 600 ? 3 : 2;
        // Reorganizar para orden por columnas
        final reordered = _toColumnMajor(libros, crossAxisCount);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: crossAxisCount >= 5 ? 5.5 : crossAxisCount == 4 ? 5.0 : 6.0,
          ),
          itemCount: reordered.length,
          itemBuilder: (context, index) {
            final libro = reordered[index];
            return _LibroGridTile(libro: libro);
          },
        );
      },
    );
  }
}

/// Tile compacto para el grid de libros en desktop.
///
/// Horizontal: número a la izquierda, nombre + capítulos a la derecha.
class _LibroGridTile extends ConsumerWidget {
  const _LibroGridTile({required this.libro});

  final Libro libro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasFavoritosAsync = ref.watch(favoritosPorLibroProvider);
    final hasFavoritos =
        hasFavoritosAsync.valueOrNull?.contains(libro.id) ?? false;

    return GlassCard(
      onTap: () {
        ref.read(currentLibroIdProvider.notifier).state = libro.id;
        context.pushNamed(
          'biblia_libro',
          pathParameters: {'libroId': '${libro.id}'},
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          // Número canónico
          SizedBox(
            width: 28,
            child: Text(
              libro.numero.toString().padLeft(2, '0'),
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Nombre
          Expanded(
            child: Text(
              libro.nombre,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasFavoritos)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.star_rounded, size: 13,
                  color: Color(0xFFF59E0B),),
            ),
        ],
      ),
    );
  }
}

/// Tile individual de libro con glassmorphism (modo móvil).
class _LibroTile extends ConsumerWidget {
  const _LibroTile({required this.libro});

  final Libro libro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Verificar si este libro tiene versículos favoritos.
    final hasFavoritosAsync = ref.watch(favoritosPorLibroProvider);
    final hasFavoritos =
        hasFavoritosAsync.valueOrNull?.contains(libro.id) ?? false;

    return GlassCard(
      onTap: () {
        ref.read(currentLibroIdProvider.notifier).state = libro.id;
        context.pushNamed(
          'biblia_libro',
          pathParameters: {'libroId': '${libro.id}'},
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Número canónico
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              libro.numero.toString().padLeft(2, '0'),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        libro.nombre,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasFavoritos) ...[
                      const SizedBox(width: 6),
                      const Tooltip(
                        message: 'Tiene versículos favoritos',
                        child: Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${libro.totalCapitulos} ${libro.totalCapitulos == 1 ? "capítulo" : "capítulos"}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Tab de favoritos.
class _FavoritosTab extends ConsumerWidget {
  const _FavoritosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritosAsync = ref.watch(favoritosStreamProvider);

    return favoritosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: 'Error: $e'),
      data: (favoritos) {
        if (favoritos.isEmpty) {
          return _EmptyState(
            icon: Icons.star_outline_rounded,
            title: 'Aún no tienes favoritos',
            subtitle: 'Marca versículos con ⭐ para verlos aquí.',
            actionLabel: 'Ir a la Biblia',
            onAction: () => GoRouter.of(context).goNamed('biblia'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: favoritos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final fav = favoritos[index];
            return _FavoritoTile(favorito: fav);
          },
        );
      },
    );
  }
}

/// Tile individual de favorito.
class _FavoritoTile extends ConsumerWidget {
  const _FavoritoTile({required this.favorito});

  final FavoritoVersiculo favorito;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bibliaRepo = ref.read(bibliaRepositoryProvider);

    return GlassCard(
      onTap: () async {
        // Navegar al reader con esta referencia
        final libro =
            await bibliaRepo.getLibroById(favorito.libroId);
        if (libro == null || !context.mounted) return;
        ref.read(currentLibroIdProvider.notifier).state = libro.id;
        ref.read(currentCapituloProvider.notifier).state = favorito.capitulo;
        ref.read(currentVersiculoNumeroProvider.notifier).state =
            favorito.numero;
        if (context.mounted) {
          context.pushNamed(
            'biblia_reader',
            pathParameters: {
              'libroId': '${libro.id}',
              'capitulo': '${favorito.capitulo}',
            },
          );
        }
      },
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder(
              future: bibliaRepo.getLibroById(favorito.libroId),
              builder: (context, snap) {
                final libro = snap.data;
                final refText = libro == null
                    ? 'Libro #${favorito.libroId}'
                    : '${libro.abreviatura} ${favorito.capitulo}:${favorito.numero}';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      refText,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agregado ${_formatFecha(favorito.fechaAgregado)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.star_rounded,
              color: colorScheme.primary,
            ),
            onPressed: () async {
              await ref.read(favoritosRepositoryProvider).remove(
                    favorito.versionId,
                    favorito.libroId,
                    favorito.capitulo,
                    favorito.numero,
                  );
            },
            tooltip: 'Quitar de favoritos',
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);
    if (diff.inDays == 0) return 'hoy';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    if (diff.inDays < 30) return 'hace ${(diff.inDays / 7).floor()}sem';
    return 'hace ${(diff.inDays / 30).floor()}m';
  }
}

/// Tab de notas.
class _NotasTab extends ConsumerWidget {
  const _NotasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notasAsync = ref.watch(notasStreamProvider);

    return notasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: 'Error: $e'),
      data: (notas) {
        if (notas.isEmpty) {
          return _EmptyState(
            icon: Icons.edit_note_outlined,
            title: 'Aún no tienes notas',
            subtitle: 'Crea notas desde el Bible reader.',
            actionLabel: 'Ir a la Biblia',
            onAction: () => GoRouter.of(context).goNamed('biblia'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: notas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final nota = notas[index];
            return _NotaTile(nota: nota);
          },
        );
      },
    );
  }
}

/// Tile individual de nota.
class _NotaTile extends ConsumerWidget {
  const _NotaTile({required this.nota});

  final Nota nota;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bibliaRepo = ref.read(bibliaRepositoryProvider);

    return GlassCard(
      onTap: () async {
        final libro = await bibliaRepo.getLibroById(nota.libroId);
        if (libro == null || !context.mounted) return;
        ref.read(currentLibroIdProvider.notifier).state = libro.id;
        ref.read(currentCapituloProvider.notifier).state = nota.capitulo;
        ref.read(currentVersiculoNumeroProvider.notifier).state = nota.numero;
        if (context.mounted) {
          context.pushNamed(
            'biblia_reader',
            pathParameters: {
              'libroId': '${libro.id}',
              'capitulo': '${nota.capitulo}',
            },
          );
        }
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Border lateral del color
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _colorForNota(nota.color, colorScheme),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FutureBuilder(
                future: bibliaRepo.getLibroById(nota.libroId),
                builder: (context, snap) {
                  final libro = snap.data;
                  final refText = libro == null
                      ? 'Libro #${nota.libroId}'
                      : '${libro.abreviatura} ${nota.capitulo}:${nota.numero}';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        refText,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nota.contenido,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFecha(nota.fechaModificacion),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForNota(NotaColor color, ColorScheme scheme) {
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

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final diff = now.difference(fecha);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

/// Tab de historial.
class _HistorialTab extends ConsumerWidget {
  const _HistorialTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialStreamProvider);

    return historialAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(message: 'Error: $e'),
      data: (historial) {
        if (historial.isEmpty) {
          return _EmptyState(
            icon: Icons.history_rounded,
            title: 'Tu historial está vacío',
            subtitle: 'Los versículos que leas aparecerán aquí.',
            actionLabel: 'Ir a la Biblia',
            onAction: () => GoRouter.of(context).goNamed('biblia'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: historial.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = historial[index];
            return _HistorialTile(item: item);
          },
        );
      },
    );
  }
}

/// Tile individual de historial.
class _HistorialTile extends ConsumerWidget {
  const _HistorialTile({required this.item});

  final HistorialItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      onTap: () {
        ref.read(currentLibroIdProvider.notifier).state = item.libroId;
        ref.read(currentCapituloProvider.notifier).state = item.capitulo;
        ref.read(currentVersiculoNumeroProvider.notifier).state = item.numero;
        context.pushNamed(
          'biblia_reader',
          pathParameters: {
            'libroId': '${item.libroId}',
            'capitulo': '${item.capitulo}',
          },
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formatFecha(item.fechaLectura),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${item.libroNombre} ${item.capitulo}:${item.numero}',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.texto != null) ...[
            const SizedBox(height: 4),
            Text(
              item.texto!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fechaDay = DateTime(fecha.year, fecha.month, fecha.day);
    final diff = today.difference(fechaDay).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';
    if (diff < 30) return 'Hace ${(diff / 7).floor()}sem';
    return '${fecha.day}/${fecha.month}';
  }
}

/// Estado vacío genérico.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
