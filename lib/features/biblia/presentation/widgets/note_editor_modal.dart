import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_snackbar.dart';
import '../../../../presentation/shared_widgets/glass_card.dart';
import '../../application/providers/biblia_config_provider.dart';
import '../../application/providers/derived_providers.dart';
import '../../application/providers/notas_provider.dart';
import '../../data/models/nota.dart';

/// Modal para crear/editar/borrar una nota en un versículo.
///
/// Referencia: `doc/wireframes/02_bible_module.md` (Pantalla 2c - modal de nota).
class NoteEditorModal extends ConsumerStatefulWidget {
  const NoteEditorModal({
    super.key,
    required this.versionId,
    required this.libroId,
    required this.capitulo,
    required this.versiculoNumero,
    this.existingNote,
  });

  final int versionId;
  final int libroId;
  final int capitulo;
  final int versiculoNumero;

  /// Nota existente a editar. Si es `null`, el modal carga la nota desde
  /// el provider (o crea una nueva si no existe).
  final Nota? existingNote;

  @override
  ConsumerState<NoteEditorModal> createState() => _NoteEditorModalState();
}

class _NoteEditorModalState extends ConsumerState<NoteEditorModal> {
  late final TextEditingController _controller;
  // Se inicializa con un default seguro y se actualiza al cargar la nota.
  NotaColor _selectedColor = NotaColor.amarillo;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    if (widget.existingNote != null) {
      // Si ya tenemos la nota (ej. desde long-press), precargar al instante.
      _controller.text = widget.existingNote!.contenido;
      _selectedColor = widget.existingNote!.color;
      _initialized = true;
    } else {
      // Sin nota pasada → cargar sincrónicamente el color default del provider.
      _selectedColor = ref.read(notaColorDefaultProvider);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    final defaultColor = ref.watch(notaColorDefaultProvider);

    // Escuchar cambios en el provider de nota para cargar datos asíncronos
    // (cuando existingNote es null, ej. desde el bottom bar).
    ref.listen<AsyncValue<Nota?>>(
      currentNotaProvider(
        NotaQuery(
          versionId: widget.versionId,
          libroId: widget.libroId,
          capitulo: widget.capitulo,
          numero: widget.versiculoNumero,
        ),
      ),
      (prev, next) {
        if (!_initialized) {
          next.whenData((nota) {
            if (!mounted || _initialized) return;
            _initialized = true;
            if (nota != null) {
              _controller.text = nota.contenido;
              _selectedColor = nota.color;
            } else {
              // Leer color actual del provider (puede haber cambiado desde build)
              final colorFromProvider = ref.read(notaColorDefaultProvider);
              if (colorFromProvider != NotaColor.ninguno) {
                _selectedColor = colorFromProvider;
              }
            }
          });
        }
      },
    );

    final isEditing = widget.existingNote != null ||
        (_initialized && _controller.text.isNotEmpty);

    // Watch para saber si hay nota existente (delete button).
    final Nota? existingNote;
    if (widget.existingNote != null) {
      existingNote = widget.existingNote;
    } else {
      existingNote = ref.watch(
        currentNotaProvider(
          NotaQuery(
            versionId: widget.versionId,
            libroId: widget.libroId,
            capitulo: widget.capitulo,
            numero: widget.versiculoNumero,
          ),
        ),
      ).valueOrNull;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Título
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? 'Editar nota' : 'Agregar nota',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'v. ${widget.versiculoNumero}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Color picker
                Text(
                  'Color',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _ColorPicker(
                  selected: _selectedColor,
                  onSelected: (c) {
                    setState(() => _selectedColor = c);
                  },
                ),
                const SizedBox(height: 16),
                // Campo de texto
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _controller,
                    maxLines: 5,
                    minLines: 3,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Escribe tu nota...',
                    ),
                    style: textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                // Botones
                Row(
                  children: [
                    if (existingNote != null)
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _delete(existingNote),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Eliminar'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      showAppSnackBar(
        context,
        'La nota no puede estar vacía',
        type: AppSnackBarType.warning,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(notasRepositoryProvider).upsert(
            widget.versionId,
            widget.libroId,
            widget.capitulo,
            widget.versiculoNumero,
            content,
            _selectedColor,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(
          context,
          'Error al guardar: $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }

  Future<void> _delete(Nota? existing) async {
    if (existing == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(notasRepositoryProvider).delete(existing.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnackBar(
          context,
          'Error al eliminar: $e',
          type: AppSnackBarType.error,
        );
      }
    }
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selected,
    required this.onSelected,
  });

  final NotaColor selected;
  final ValueChanged<NotaColor> onSelected;

  @override
  Widget build(BuildContext context) {
    const entries = NotaColor.values;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final color in entries)
          _ColorOption(
            color: color,
            isSelected: color == selected,
            onTap: () => onSelected(color),
          ),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final NotaColor color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dot = switch (color) {
      NotaColor.amarillo => const Color(0xFFF59E0B),
      NotaColor.verde => const Color(0xFF10B981),
      NotaColor.azul => const Color(0xFF3B82F6),
      NotaColor.ninguno => Colors.grey,
    };
    const _ = null; // no-op to keep const-capable body
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dot,
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }
}
