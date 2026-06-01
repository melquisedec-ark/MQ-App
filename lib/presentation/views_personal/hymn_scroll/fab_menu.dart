import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Menú FAB dinámico (SpeedDial) con 4 opciones: Brocha, Nota, Solfa, Lupa.
///
/// Cada opción acepta un callback que la pantalla padre usa para abrir
/// su respectivo ModalBottomSheet o diálogo.
class FabMenu extends StatefulWidget {
  /// Callback al pulsar "Brocha" — ajustes visuales (fuente, fondo).
  final VoidCallback? onBrushTap;

  /// Callback al pulsar "Nota" — panel de pistas de audio.
  final VoidCallback? onNoteTap;

  /// Callback al pulsar "Solfa" — panel de músico (transposición, acordes).
  final VoidCallback? onSolfaTap;

  /// Callback al pulsar "Lupa" — diálogo de búsqueda de himnos.
  final VoidCallback? onSearchTap;

  const FabMenu({
    super.key,
    this.onBrushTap,
    this.onNoteTap,
    this.onSolfaTap,
    this.onSearchTap,
  });

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _handleTap(VoidCallback? callback) {
    _toggle();
    callback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
      ),
      child: SizedBox(
        height: 56 + 4 * 64 + 8,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            if (_isOpen) ...[
              _FabOption(
                animation: _expandAnimation,
                icon: Icons.brush,
                label: 'Apariencia',
                offset: 0,
                color: colorScheme.tertiaryContainer,
                onTap: () => _handleTap(widget.onBrushTap),
              ),
              _FabOption(
                animation: _expandAnimation,
                icon: Icons.audiotrack,
                label: 'Pistas',
                offset: 1,
                color: colorScheme.secondaryContainer,
                onTap: () => _handleTap(widget.onNoteTap),
              ),
              _FabOption(
                animation: _expandAnimation,
                icon: Icons.music_note,
                label: 'Acordes',
                offset: 2,
                color: colorScheme.tertiaryContainer,
                onTap: () => _handleTap(widget.onSolfaTap),
              ),
              _FabOption(
                animation: _expandAnimation,
                icon: Icons.search,
                label: 'Buscar',
                offset: 3,
                color: colorScheme.secondaryContainer,
                onTap: () => _handleTap(widget.onSearchTap),
              ),
            ],
            // Botón principal
            FloatingActionButton(
              onPressed: _toggle,
              heroTag: 'fab_main',
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _expandAnimation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una opción individual dentro del menú FAB expandido.
///
/// Muestra una etiqueta textual a la izquierda del [FloatingActionButton.small]
/// y se anima mediante [SizeTransition].
class _FabOption extends StatelessWidget {
  final Animation<double> animation;
  final IconData icon;
  final String label;
  final int offset;
  final Color color;
  final VoidCallback onTap;

  const _FabOption({
    required this.animation,
    required this.icon,
    required this.label,
    required this.offset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Calcula color de icono con contraste optimo segun el fondo:
    // - Fondos oscuros → icono dorado (#CCA43B)
    // - Fondos claros → icono negro (#1A1A1A)
    final iconColor = color.computeLuminance() > 0.4
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFCCA43B);

    return Positioned(
      right: 8,
      bottom: 8 + (offset + 1) * 64.0,
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: 1.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'fab_$label',
              onPressed: onTap,
              backgroundColor: color,
              foregroundColor: iconColor,
              child: Icon(icon),
            ),
          ],
        ),
      ),
    );
  }
}
