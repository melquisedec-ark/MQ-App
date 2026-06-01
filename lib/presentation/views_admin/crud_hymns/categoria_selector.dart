import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/categoria.dart';
import '../providers/admin_providers.dart';
import '../providers/auth_providers.dart';

/// Selector de categorías multi-select con chips.
///
/// Muestra todas las categorías disponibles. Las categorías seleccionadas
/// aparecen resaltadas. Incluye un botón para crear una nueva categoría
/// inline a través del [CreateCategoriaUseCase].
class CategoriaSelector extends ConsumerStatefulWidget {
  final List<int> selectedIds;
  final ValueChanged<List<int>> onSelectionChanged;

  const CategoriaSelector({
    super.key,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<CategoriaSelector> createState() => _CategoriaSelectorState();
}

class _CategoriaSelectorState extends ConsumerState<CategoriaSelector> {
  List<Categoria> _categorias = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  Future<void> _loadCategorias() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final useCase = ref.read(getAllCategoriasUseCaseProvider);
      final categorias = await useCase.execute();
      if (mounted) {
        setState(() {
          _categorias = categorias;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar categorías: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _crearCategoria() async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
            hintText: 'Ej: Alabanza, Adoración...',
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (nombre != null && nombre.isNotEmpty) {
      try {
        final admin = ref.read(currentUserProvider);
        if (admin == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Debe iniciar sesión como administrador')),
            );
          }
          return;
        }
        final useCase = ref.read(createCategoriaUseCaseProvider);
        await useCase.execute(nombre, admin: admin);
        await _loadCategorias();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }

  void _toggleCategoria(int id) {
    final selected = List<int>.from(widget.selectedIds);
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    widget.onSelectionChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Título ──────────────────────────────────────────
        Row(
          children: [
            Text(
              'Categorías',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.selectedIds.isNotEmpty)
              Text(
                '(${widget.selectedIds.length} seleccionadas)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva'),
              onPressed: _crearCategoria,
            ),
          ],
        ),
        const SizedBox(height: 4),

        // ── Contenido ───────────────────────────────────────
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
          )
        else if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: colorScheme.error, fontSize: 12),
          )
        else if (_categorias.isEmpty)
          Text(
            'No hay categorías disponibles. Crea una nueva.',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _categorias.map((cat) {
              final selected = widget.selectedIds.contains(cat.id);
              return FilterChip(
                label: Text(cat.nombre),
                selected: selected,
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.onPrimaryContainer,
                onSelected: (_) => _toggleCategoria(cat.id),
              );
            }).toList(),
          ),
      ],
    );
  }
}
