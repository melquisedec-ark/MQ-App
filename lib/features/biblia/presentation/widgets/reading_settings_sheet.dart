import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/bible_appearance_provider.dart';
import '../../application/providers/reader_providers.dart';
import '../widgets/verse_card.dart' show BibleReaderViewMode;

/// Bottom sheet con ajustes de apariencia para el lector bíblico.
///
/// Controles:
/// - Slider de tamaño de letra (0.8 – 1.5)
/// - Selector de fuente (system / serif / monospace)
/// - Ajuste de color de texto (blanco / negro / sepia / azul)
/// - Slider de interlineado (1.4 – 2.0)
/// - Toggle modo lectura (verse / chapter)
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
    final viewMode = ref.watch(readerViewModeProvider);

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

            // ── Color de texto ──
            const _SectionLabel(label: 'Color de texto'),
            const SizedBox(height: 8),
            _TextColorSelector(
              current: appearance.textColor,
              onChanged: (v) =>
                  ref.read(bibleAppearanceProvider.notifier).setTextColor(v),
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

            // ── Modo de lectura ──
            const _SectionLabel(label: 'Modo de lectura'),
            const SizedBox(height: 8),
            _ViewModeSelector(
              current: viewMode,
              onChanged: (mode) {
                ref.read(readerViewModeProvider.notifier).setViewMode(mode);
              },
            ),
            const SizedBox(height: 8),
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

/// Selector de color de texto con 4 opciones predefinidas.
class _TextColorSelector extends StatelessWidget {
  const _TextColorSelector({
    required this.current,
    required this.onChanged,
  });

  final Color current;
  final ValueChanged<Color> onChanged;

  static const _colors = [
    (_ColorOptionData(Colors.white, 'Blanco')),
    (_ColorOptionData(Colors.black, 'Negro')),
    (_ColorOptionData(Color(0xFF3E2723), 'Sepia')),
    (_ColorOptionData(Color(0xFF1565C0), 'Azul')),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: _colors.map((data) {
        final isSelected = current.toARGB32() == data.color.toARGB32();
        return GestureDetector(
          onTap: () => onChanged(data.color),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: data.color == Colors.white
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: data.color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
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

/// Data class para opciones de color.
class _ColorOptionData {
  final Color color;
  final String label;

  const _ColorOptionData(this.color, this.label);
}

/// Selector de modo de vista (verse / chapter).
class _ViewModeSelector extends StatelessWidget {
  const _ViewModeSelector({
    required this.current,
    required this.onChanged,
  });

  final BibleReaderViewMode current;
  final ValueChanged<BibleReaderViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ViewModeOption(
            icon: Icons.view_headline_rounded,
            label: 'Versículo',
            isSelected: current == BibleReaderViewMode.verse,
            onTap: () => onChanged(BibleReaderViewMode.verse),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ViewModeOption(
            icon: Icons.view_agenda_outlined,
            label: 'Capítulo',
            isSelected: current == BibleReaderViewMode.chapter,
            onTap: () => onChanged(BibleReaderViewMode.chapter),
          ),
        ),
      ],
    );
  }
}

class _ViewModeOption extends StatelessWidget {
  const _ViewModeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
