import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/arreglo_musical.dart';
import '../providers/arreglo_providers.dart';

/// Pantalla que lista los arreglos musicales del usuario actual.
///
/// Muestra una tarjeta por cada [ArregloMusical] con su nombre,
/// tonalidad base, badge de versión y acciones de navegación/eliminación.
class ArrangementListScreen extends ConsumerStatefulWidget {
  const ArrangementListScreen({super.key});

  @override
  ConsumerState<ArrangementListScreen> createState() =>
      _ArrangementListScreenState();
}

class _ArrangementListScreenState
    extends ConsumerState<ArrangementListScreen> {
  Future<void> _deleteArreglo(ArregloMusical arreglo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar arreglo?'),
        content: Text(
          'Se eliminará "${arreglo.nombreArreglo}".\n'
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
      final repo = ref.read(arregloRepositoryProvider);
      final deleted = await repo.deleteArreglo(arreglo.id);
      if (mounted) {
        if (deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${arreglo.nombreArreglo}" eliminado'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No se pudo eliminar el arreglo'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        ref.invalidate(userArreglosProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final arreglosAsync = ref.watch(userArreglosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Arreglos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
            onPressed: () => ref.invalidate(userArreglosProvider),
          ),
        ],
      ),
      body: arreglosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Error al cargar arreglos',
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: () => ref.invalidate(userArreglosProvider),
              ),
            ],
          ),
        ),
        data: (arreglos) {
          if (arreglos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay arreglos',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Crea un arreglo desde la vista de un himno',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userArreglosProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: arreglos.length,
              itemBuilder: (context, index) {
                final arreglo = arreglos[index];
                return _ArrangementTile(
                  arreglo: arreglo,
                  onDelete: () => _deleteArreglo(arreglo),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Tarjeta individual para un arreglo musical en la lista.
///
/// Soporta deslizar para eliminar (Dismissible endToStart) y navegación
/// al editor de arreglos al tocar.
class _ArrangementTile extends StatelessWidget {
  final ArregloMusical arreglo;
  final VoidCallback onDelete;

  const _ArrangementTile({
    required this.arreglo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey('arrangement_${arreglo.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        // Mostrar diálogo de confirmación
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Eliminar arreglo?'),
            content: Text(
              'Se eliminará "${arreglo.nombreArreglo}".\n'
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
        return confirm == true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: colorScheme.onError,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.music_note,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            arreglo.nombreArreglo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Tonalidad: ${arreglo.tonalidadBase}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (arreglo.version > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'v${arreglo.version}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                  size: 20,
                ),
                tooltip: 'Eliminar arreglo',
                onPressed: onDelete,
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/arrangement-editor',
              arguments: arreglo.id,
            );
          },
        ),
      ),
    );
  }
}
