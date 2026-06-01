import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../domain/entities/himno.dart';
import '../../../../domain/usecases/himno/delete_hymn_usecase.dart';
import '../../views_personal/providers/hymn_providers.dart';
import 'hymn_form_screen.dart';

/// Pantalla de listado de himnos para el backoffice.
///
/// Muestra una barra de búsqueda con debounce, una lista de himnos
/// con acciones de editar/eliminar, y un FAB para crear nuevos.
class HymnListScreen extends ConsumerStatefulWidget {
  const HymnListScreen({super.key});

  @override
  ConsumerState<HymnListScreen> createState() => _HymnListScreenState();
}

class _HymnListScreenState extends ConsumerState<HymnListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchText = value.trim());
    });
  }

  Future<void> _deleteHymn(Himno himno) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar himno?'),
        content: Text(
          'Se eliminará "${himno.titulo}".\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final deleteUseCase = ref.read(deleteHymnUseCaseProvider);
      await deleteUseCase.execute(himno.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${himno.titulo}" eliminado')),
        );
        // Forzar rebuild limpiando la caché del provider
        ref.invalidate(hymnListProvider);
      }
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToForm({int? himnoId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HymnFormScreen(himnoId: himnoId),
      ),
    ).then((_) {
      // Refrescar al volver del formulario
      ref.invalidate(hymnListProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final queryParam = HymnQueryParam(text: _searchText);
    final hymnListAsync = ref.watch(hymnListProvider(queryParam));

    return Stack(
      children: [
        Column(
          children: [
            // ── Barra de búsqueda ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar por título o número...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
            ),

            // ── Lista de himnos ────────────────────────────────
            Expanded(
              child: hymnListAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar himnos',
                        style: TextStyle(color: colorScheme.error),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        onPressed: () => ref.invalidate(hymnListProvider),
                      ),
                    ],
                  ),
                ),
                data: (hymns) {
                  if (hymns.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.library_music_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchText.isNotEmpty
                                ? 'No se encontraron himnos para "$_searchText"'
                                : 'No hay himnos registrados',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_searchText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('Limpiar búsqueda'),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(hymnListProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: hymns.length,
                      itemBuilder: (context, index) {
                        final himno = hymns[index];
                        return _HymnListTile(
                          himno: himno,
                          onEdit: () => _navigateToForm(himnoId: himno.id),
                          onDelete: () => _deleteHymn(himno),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // ── FAB reposicionado ──
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _navigateToForm(),
            tooltip: 'Agregar himno',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Widget interno para el tile de cada himno en la lista.
class _HymnListTile extends StatelessWidget {
  final Himno himno;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HymnListTile({
    required this.himno,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeLabel = himno.tipo.label;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            himno.numero?.toString() ?? '?',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          himno.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              typeLabel,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (himno.categorias != null && himno.categorias!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: himno.categorias!.map((cat) {
                  return Chip(
                    label: Text(cat.nombre, style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              color: colorScheme.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
