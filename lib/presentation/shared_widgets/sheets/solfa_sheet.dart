import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dual_mode_wrapper/dual_mode_providers.dart';
import '../../views_personal/providers/transpose_providers.dart';
import '../providers/appearance_provider.dart';
import 'sheet_helpers.dart';

// =============================================================================
// 3. Solfa — Musician panel sheet (transposition, chords toggle)
// =============================================================================

/// Muestra el sheet del panel de músico (transposición y toggle de acordes).
void showSolfaSheet(
  BuildContext context, {
  required WidgetRef ref,
  VoidCallback? onCreateArrangement,
}) {
  final isDesktop = ref.read(isDesktopModeProvider);

  if (isDesktop) {
    // ── Desktop: Dialog sin drag handle ──
    showDialog<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final currentTranspose = ref.watch(transposeValueProvider);
            final currentKey = ref.watch(transposedKeyProvider);
            final showChords = ref.watch(hymnAppearanceProvider).showChords;

            return Dialog(
              backgroundColor: colorScheme.surfaceContainerHigh,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: _solfaSheetContent(
                    context: context,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    currentTranspose: currentTranspose,
                    currentKey: currentKey,
                    showChords: showChords,
                    onCreateArrangement: onCreateArrangement,
                    ref: ref,
                    setSheetState: setSheetState,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } else {
    // ── Móvil: ModalBottomSheet ──
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final currentTranspose = ref.watch(transposeValueProvider);
            final currentKey = ref.watch(transposedKeyProvider);
            final showChords = ref.watch(hymnAppearanceProvider).showChords;

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Handle (solo móvil)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _solfaSheetContent(
                    context: context,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    currentTranspose: currentTranspose,
                    currentKey: currentKey,
                    showChords: showChords,
                    onCreateArrangement: onCreateArrangement,
                    ref: ref,
                    setSheetState: setSheetState,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Contenido compartido del sheet Solfa (título, acordes toggle, transposición).
Widget _solfaSheetContent({
  required BuildContext context,
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  required int currentTranspose,
  required String currentKey,
  required bool showChords,
  VoidCallback? onCreateArrangement,
  required WidgetRef ref,
  required void Function(void Function()) setSheetState,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Icon(
            Icons.music_note,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Text(
            'Panel de músico',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      // Toggle de acordes
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Mostrar acordes',
          style: textTheme.bodyLarge,
        ),
        subtitle: Text(
          'Muestra u oculta los acordes en la letra',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        value: showChords,
        onChanged: (bool value) {
          setSheetState(() {
            ref.read(hymnAppearanceProvider.notifier).setShowChords(value);
            syncAppearanceToProjection(ref);
          });
        },
      ),
      const Divider(),
      // Transposición
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Transposición',
          style: textTheme.bodyLarge,
        ),
        subtitle: Text(
          'Tono actual: $currentKey',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              onPressed: () {
                ref.read(transposeValueProvider.notifier).state =
                    (currentTranspose - 1).clamp(-6, 6);
              },
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: 'Bajar tono',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$currentTranspose',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(transposeValueProvider.notifier).state =
                    (currentTranspose + 1).clamp(-6, 6);
              },
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Subir tono',
            ),
          ],
        ),
      ),
      if (onCreateArrangement != null)
        const Divider(),
      if (onCreateArrangement != null)
        ListTile(
          leading: Icon(Icons.edit_note, color: colorScheme.tertiary),
          title: const Text('Crear Arreglo Personalizado'),
          subtitle: const Text('Fork del himno con tus propios acordes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pop(context);
            onCreateArrangement();
          },
        ),
    ],
  );
}