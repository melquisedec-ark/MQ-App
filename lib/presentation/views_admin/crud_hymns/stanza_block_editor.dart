import 'package:flutter/material.dart';

import '../../../../core/enums/estrofa_tipo.dart';

/// Editor de un bloque de estrofa individual.
///
/// Widget reutilizable que permite editar el tipo, contenido ChordPro
/// y reordenar/eliminar una estrofa dentro de la lista dinámica.
class StanzaBlockEditor extends StatefulWidget {
  final int index;
  final int total;
  final EstrofaTipo tipo;
  final String contenido;
  final ValueChanged<EstrofaTipo> onTipoChanged;
  final ValueChanged<String> onContenidoChanged;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  const StanzaBlockEditor({
    super.key,
    required this.index,
    required this.total,
    required this.tipo,
    required this.contenido,
    required this.onTipoChanged,
    required this.onContenidoChanged,
    this.onMoveUp,
    this.onMoveDown,
    required this.onDelete,
  });

  @override
  State<StanzaBlockEditor> createState() => _StanzaBlockEditorState();
}

class _StanzaBlockEditorState extends State<StanzaBlockEditor> {
  late TextEditingController _controller;
  late String _lastContent;

  @override
  void initState() {
    super.initState();
    _lastContent = widget.contenido;
    _controller = TextEditingController(text: widget.contenido);
  }

  @override
  void didUpdateWidget(StanzaBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualizar el controlador si el contenido externo cambió
    // y es diferente de lo que tenemos (evita perder posición del cursor)
    if (widget.contenido != _lastContent) {
      _lastContent = widget.contenido;
      final wasFocused = FocusScope.of(context).hasFocus;
      if (!wasFocused) {
        _controller.text = widget.contenido;
      }
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
    final label = 'Estrofa ${widget.index + 1} (${widget.tipo.value})';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera ─────────────────────────────────────
            Row(
              children: [
                Icon(Icons.music_note, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _iconButton(
                  icon: Icons.keyboard_arrow_up,
                  tooltip: 'Mover arriba',
                  onPressed: widget.index > 0 ? widget.onMoveUp : null,
                ),
                _iconButton(
                  icon: Icons.keyboard_arrow_down,
                  tooltip: 'Mover abajo',
                  onPressed: widget.index < widget.total - 1 ? widget.onMoveDown : null,
                ),
                _iconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Eliminar',
                  color: colorScheme.error,
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Dropdown de tipo ─────────────────────────────
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tipo de estrofa',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<EstrofaTipo>(
                  value: widget.tipo,
                  isDense: true,
                  isExpanded: true,
                  items: EstrofaTipo.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.value));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) widget.onTipoChanged(v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Campo de contenido ChordPro ──────────────────
            TextField(
              controller: _controller,
              onChanged: (value) {
                _lastContent = value;
                widget.onContenidoChanged(value);
              },
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                labelText: 'Contenido (ChordPro)',
                hintText: '[C]Texto del acorde y letra...',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                suffixIcon: widget.contenido.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          widget.onContenidoChanged('');
                        },
                      )
                    : null,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 4),
            // ── Ayuda ChordPro ───────────────────────────────
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showChordProHelp(context),
                    child: Text(
                      '¿Cómo escribir acordes? Toca para ver la guía',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChordProHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.music_note, size: 24),
            SizedBox(width: 8),
            Text('Cómo escribir acordes'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Usa el formato ChordPro: el acorde entre corchetes [ ] justo antes de la sílaba donde se toca.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 16),
              Text('Ejemplos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 8),
              Text(
                '[G]Dios es [C]amor\n[Am]Grande es [G]Él\n[D]Santo, [G]Santo',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
              ),
              SizedBox(height: 16),
              Text('Acordes soportados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 8),
              Text(
                'Mayores: C D E F G A B\n'
                'Menores: Cm Dm Em Fm Gm Am Bm\n'
                'Sostenidos: C# D# F# G# A#\n'
                'Bemoles: Db Eb Gb Ab Bb\n'
                'Suspendidos: Csus4 Gsus Dsus\n'
                'Séptimas: C7 G7 D7 A7 E7',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Cada verso en una línea separada.\n'
                'Usa \\n para saltos de línea.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      color: color,
    );
  }
}
