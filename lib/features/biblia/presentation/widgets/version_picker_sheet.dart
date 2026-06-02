import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/biblia_version.dart';
import '../../application/providers/current_libro_provider.dart';

/// Bottom sheet para seleccionar la versión bíblica.
///
/// Se usa en:
/// - [HomeScreen] (versículo del día)
/// - [BibleReaderScreen] (cambio rápido de versión)
///
/// Al cambiar, se actualiza [currentVersionIdProvider] y se muestra un
/// mensaje al usuario sobre la referencia que se mantiene.
///
/// Es un [showModalBottomSheet] con handle bar arriba y glass background.
class VersionPickerSheet extends ConsumerWidget {
  const VersionPickerSheet({
    super.key,
    required this.versions,
    required this.currentVersionId,
  });

  final List<BibliaVersion> versions;
  final int currentVersionId;

  /// Helper para mostrar el sheet y devolver la versión seleccionada
  /// (o `null` si el usuario canceló).
  static Future<BibliaVersion?> show({
    required BuildContext context,
    required List<BibliaVersion> versions,
    required int currentVersionId,
  }) async {
    return showModalBottomSheet<BibliaVersion>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => VersionPickerSheet(
        versions: versions,
        currentVersionId: currentVersionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Título
            Text(
              'Seleccionar versión',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Al cambiar, el versículo actual se mantiene.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // Opciones
            ...versions.map(
              (v) => _VersionOption(
                version: v,
                isSelected: v.id == currentVersionId,
                onTap: () {
                  ref.read(currentVersionIdProvider.notifier).state = v.id;
                  Navigator.of(context).pop(v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionOption extends StatelessWidget {
  const _VersionOption({
    required this.version,
    required this.isSelected,
    required this.onTap,
  });

  final BibliaVersion version;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.nombre,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (version.anioPublicacion != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Año ${version.anioPublicacion} · '
                        '${version.esDominioPublico ? "Dominio público" : "Protegida"}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
