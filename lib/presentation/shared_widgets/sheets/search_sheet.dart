import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/flag_utils.dart';
import '../../../../domain/entities/himno.dart';
import '../../views_personal/providers/hymn_providers.dart';

// =============================================================================
// 4. Search (Lupa) — Hymn search sheet
// =============================================================================

/// Muestra el diálogo de búsqueda de himnos.
///
/// Retorna el ID del himno seleccionado, o `null` si se cancela la búsqueda.
Future<int?> showSearchSheet(
  BuildContext context, {
  required WidgetRef ref,
  required int currentHimnoId,
}) {
  return showSearch<int>(
    context: context,
    delegate: HymnSearchDelegate(
      ref: ref,
      currentHimnoId: currentHimnoId,
    ),
  );
}

// =============================================================================
// Search delegate used by showSearchSheet
// =============================================================================

/// Delegado de búsqueda para navegar entre himnos.
class HymnSearchDelegate extends SearchDelegate<int> {
  final WidgetRef ref;
  final int currentHimnoId;

  HymnSearchDelegate({
    required this.ref,
    required this.currentHimnoId,
  });

  @override
  String get searchFieldLabel => 'Buscar himno por título o número';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return <Widget>[
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, -1),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchList(context);

  Widget _buildSearchList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.search,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Escribe para buscar himnos',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Himno>>(
      future: ref.read(hymnRepositoryProvider).searchHymns(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final himnos = snapshot.data ?? <Himno>[];

        if (himnos.isEmpty) {
          return Center(
            child: Text(
              'No se encontraron himnos para "$query"',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: himnos.length,
          itemBuilder: (context, int index) {
            final himno = himnos[index];
            final isCurrent = himno.id == currentHimnoId;

            final paisCodigo = himno.paisCodigo;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isCurrent
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                child: Text(
                  '${himno.numero ?? '?'}',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCurrent
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      himno.titulo,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (paisCodigo != null && paisCodigo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FlagUtils.codeToFlag(paisCodigo).isNotEmpty
                          ? Text(
                              FlagUtils.codeToFlag(paisCodigo),
                              style: const TextStyle(fontSize: 24),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
              subtitle: (himno.categorias?.isNotEmpty ?? false)
                  ? Text(
                      himno.categorias!.take(4).map((c) => c.nombre).join(', '),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: isCurrent
                  ? Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 20,
                    )
                  : null,
              onTap: () => close(context, himno.id),
            );
          },
        );
      },
    );
  }
}