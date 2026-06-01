import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../views_personal/providers/hymn_providers.dart' show catalogVersionProvider;
import '../../../domain/entities/categoria.dart';
import '../../views_admin/providers/admin_providers.dart'
    show
        getAllCategoriasUseCaseProvider,
        createCategoriaUseCaseProvider,
        updateCategoriaUseCaseProvider,
        deleteCategoriaUseCaseProvider;
import '../../views_admin/providers/auth_providers.dart' show currentUserProvider;

// ─────────────────────────────────────────────────────────────
// Provider local: lista de categorías
// ─────────────────────────────────────────────────────────────

final _categoriaListProvider =
    FutureProvider.autoDispose<List<Categoria>>((ref) {
  return ref.watch(getAllCategoriasUseCaseProvider).execute();
});

// ─────────────────────────────────────────────────────────────

/// Tab de administración de categorías.
///
/// Permite crear nuevas categorías (solo nombre) y eliminar existentes.
/// Muestra la lista completa ordenada alfabéticamente.
class CategoriaTab extends ConsumerStatefulWidget {
  const CategoriaTab({super.key});

  @override
  ConsumerState<CategoriaTab> createState() => _CategoriaTabState();
}

class _CategoriaTabState extends ConsumerState<CategoriaTab> {
  final _nombreController = TextEditingController();
  bool _loading = false;
  Categoria? _editando;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nombreController.clear();
      _editando = null;
    });
  }

  void _editarCategoria(Categoria cat) {
    setState(() {
      _editando = cat;
      _nombreController.text = cat.nombre;
    });
  }

  Future<void> _guardarCategoria() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) return;

    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    setState(() => _loading = true);
    try {
      if (_editando != null) {
        // Modo edición
        await ref.read(updateCategoriaUseCaseProvider).execute(
              _editando!.id,
              nombre,
              admin: admin,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Categoría renombrada a "$nombre"')),
          );
        }
      } else {
        // Modo creación
        await ref.read(createCategoriaUseCaseProvider).execute(
              nombre,
              admin: admin,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Categoría "$nombre" creada')),
          );
        }
      }
      _resetForm();
      ref.invalidate(_categoriaListProvider);
      ref.read(catalogVersionProvider.notifier).state++;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _eliminarCategoria(Categoria cat) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${cat.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(deleteCategoriaUseCaseProvider).execute(
            cat.id,
            admin: admin,
          );
      ref.invalidate(_categoriaListProvider);
      ref.read(catalogVersionProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoría "${cat.nombre}" eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(_categoriaListProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Formulario compacto ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _editando != null
                    ? 'Editar categoría'
                    : 'Nueva categoría',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        hintText: 'Nombre de la categoría',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _guardarCategoria(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _guardarCategoria,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _editando != null ? Icons.save : Icons.add,
                        size: 20,
                      ),
                label: Text(_editando != null ? 'Guardar' : 'Agregar'),
              ),
              if (_editando != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _resetForm,
                  child: const Text('Cancelar'),
                ),
              ],
              ],
            ),
          ],
        ),
        ),
        // ── Lista de categorías ──────────────────────────────────
        Expanded(
          child: categoriasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (categorias) {
              if (categorias.isEmpty) {
                return Center(
                  child: Text(
                    'No hay categorías',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: categorias.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cat = categorias[index];
                  return ListTile(
                    title: Text(cat.nombre),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _editarCategoria(cat),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarCategoria(cat),
                        ),
                      ],
                    ),
                    onTap: () => _editarCategoria(cat),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
