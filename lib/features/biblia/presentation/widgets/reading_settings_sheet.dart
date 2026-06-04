import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/bible_appearance_provider.dart';

/// Bottom sheet con ajustes de apariencia para el lector bíblico.
///
/// Controles:
/// - Slider de tamaño de letra (0.8 – 1.5)
/// - Selector de fuente (system / serif / monospace)
/// - Selector de tema de lectura (5 temas predefinidos)
/// - Slider de interlineado (1.4 – 2.0)
///
/// El modo de lectura (verse/chapter) se controla desde el bottom bar
/// del Bible reader (A1+A2), no desde este sheet (A3).
///
/// Los cambios se aplican EN VIVO mientras se interactúa con los controles.
class ReadingSettingsSheet extends ConsumerStatefulWidget {
  const ReadingSettingsSheet({super.key});

  /// Helper para mostrar el sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ReadingSettingsSheet(),
    );
  }

  @override
  ConsumerState<ReadingSettingsSheet> createState() =>
      _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends ConsumerState<ReadingSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appearance = ref.watch(bibleAppearanceProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Título
            Row(
              children: [
                Icon(Icons.tune_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ajustes de lectura',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Tamaño de letra ──
            const _SectionLabel(label: 'Tamaño de letra'),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.text_fields, size: 16),
                Expanded(
                  child: Slider(
                    value: appearance.fontScale,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: '${appearance.fontScale.toStringAsFixed(1)}x',
                    onChanged: (v) =>
                        ref.read(bibleAppearanceProvider.notifier).setFontScale(v),
                  ),
                ),
                const Icon(Icons.text_fields, size: 24),
              ],
            ),

            // ── Familia tipográfica ──
            const _SectionLabel(label: 'Tipo de letra'),
            const SizedBox(height: 8),
            _FontFamilySelector(
              current: appearance.fontFamily,
              onChanged: (v) =>
                  ref.read(bibleAppearanceProvider.notifier).setFontFamily(v),
            ),
            const SizedBox(height: 16),

            // ── Tema de lectura ──
            const _SectionLabel(label: 'Tema de lectura'),
            const SizedBox(height: 8),
            _ThemeSelector(
              current: appearance.themeId,
              onChanged: (theme) =>
                  ref.read(bibleAppearanceProvider.notifier).setTheme(theme),
            ),
            const SizedBox(height: 16),

            // ── Interlineado ──
            const _SectionLabel(label: 'Interlineado'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '1.4',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: appearance.lineHeight,
                    min: 1.4,
                    max: 2.0,
                    divisions: 6,
                    label: appearance.lineHeight.toStringAsFixed(1),
                    onChanged: (v) => ref
                        .read(bibleAppearanceProvider.notifier)
                        .setLineHeight(v),
                  ),
                ),
                Text(
                  '2.0',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de sección.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

/// Selector de familia tipográfica.
class _FontFamilySelector extends StatelessWidget {
  const _FontFamilySelector({
    required this.current,
    required this.onChanged,
  });

  final String current;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('system', 'Sistema'),
    ('serif', 'Serif'),
    ('monospace', 'Monoespaciado'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      children: _options.map((option) {
        final (value, label) = option;
        final isSelected = current == value;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(value),
          selectedColor: colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        );
      }).toList(),
    );
  }
}

/// Selector de tema de lectura con 5 opciones predefinidas.
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.current,
    required this.onChanged,
  });

  final String current;
  final ValueChanged<ReadingTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReadingTheme.values.map((theme) {
        final isSelected = current == theme.id;
        return GestureDetector(
          onTap: () => onChanged(theme),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                theme.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
