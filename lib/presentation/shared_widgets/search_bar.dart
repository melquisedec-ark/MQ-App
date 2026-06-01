import 'package:flutter/material.dart';

/// Widget de barra de búsqueda reutilizable
/// Adaptado para tema claro y oscuro
class HymnSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  const HymnSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Buscar himno por número o título...',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: controller != null
          ? ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              builder: (context, value, child) {
                final isNotEmpty = value.text.isNotEmpty;
                return TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              controller!.clear();
                              onClear?.call();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                );
              },
            )
          : TextField(
              onChanged: onChanged,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
    );
  }
}
