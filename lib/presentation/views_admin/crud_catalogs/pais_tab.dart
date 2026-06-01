import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/pais_model.dart';
import '../../views_admin/providers/admin_providers.dart'
    show
        getAllPaisesUseCaseProvider,
        createPaisUseCaseProvider,
        updatePaisUseCaseProvider,
        deletePaisUseCaseProvider;
import '../../views_admin/providers/auth_providers.dart' show currentUserProvider;

// ─────────────────────────────────────────────────────────────
// Provider local: lista de países
// ─────────────────────────────────────────────────────────────

final _paisListProvider =
    FutureProvider.autoDispose<List<PaisModel>>((ref) {
  return ref.watch(getAllPaisesUseCaseProvider).execute();
});

// ─────────────────────────────────────────────────────────────

/// Tab de administración de países.
///
/// CRUD completo: crear, editar, listar y eliminar países.
/// Cada país tiene: nombre (obligatorio) y código opcional (ej. SV, US, MX).
class PaisTab extends ConsumerStatefulWidget {
  const PaisTab({super.key});

  @override
  ConsumerState<PaisTab> createState() => _PaisTabState();
}

class _PaisTabState extends ConsumerState<PaisTab> {
  // ── Formulario ─────────────────────────────────────────────
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();

  // Modo edición
  PaisModel? _editando;

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nombreController.clear();
      _codigoController.clear();
      _editando = null;
    });
  }

  void _cargarEnFormulario(PaisModel pais) {
    setState(() {
      _editando = pais;
      _nombreController.text = pais.nombre;
      _codigoController.text = pais.codigo ?? '';
    });
  }

  // ── Guardar (crear / actualizar) ──────────────────────────

  Future<void> _guardar() async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final codigo = _codigoController.text.trim().isEmpty
        ? null
        : _codigoController.text.trim().toUpperCase();

    try {
      if (_editando != null) {
        // ── Actualizar ────────────────────────────────────
        await ref.read(updatePaisUseCaseProvider).execute(
              id: _editando!.id,
              nombre: nombre,
              codigo: codigo,
              admin: admin,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('País "$nombre" actualizado')),
          );
        }
      } else {
        // ── Crear ─────────────────────────────────────────
        await ref.read(createPaisUseCaseProvider).execute(
              nombre: nombre,
              codigo: codigo,
              admin: admin,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('País "$nombre" creado')),
          );
        }
      }
      _resetForm();
      ref.invalidate(_paisListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Eliminar con confirmación ────────────────────────────

  Future<void> _eliminarPais(PaisModel pais) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar país'),
        content: Text('¿Eliminar país "${pais.nombre}"?'),
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
      await ref.read(deletePaisUseCaseProvider).execute(pais.id, admin: admin);
      if (_editando?.id == pais.id) _resetForm();
      ref.invalidate(_paisListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('País "${pais.nombre}" eliminado')),
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

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Formulario ──────────────────────────────────────────
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
            children: [
              Text(
                _editando != null ? 'Editar país' : 'Nuevo país',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: El Salvador',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código (opcional)',
                  hintText: 'Ej: SV, US, MX',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _guardar,
                      icon: Icon(
                        _editando != null ? Icons.save : Icons.add,
                        size: 20,
                      ),
                      label: Text(_editando != null ? 'Actualizar' : 'Crear'),
                    ),
                  ),
                  if (_editando != null) ...[
                    const SizedBox(width: 12),
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

        // ── Lista de países ─────────────────────────────────────
        Expanded(
          child: ref.watch(_paisListProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (paises) {
              if (paises.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public_off,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay países registrados',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea el primer país usando el formulario de arriba.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: paises.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final pais = paises[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.flag_outlined,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: Text(pais.nombre),
                    subtitle: pais.codigo != null ? Text(pais.codigo!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _cargarEnFormulario(pais),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarPais(pais),
                        ),
                      ],
                    ),
                    onTap: () => _cargarEnFormulario(pais),
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
