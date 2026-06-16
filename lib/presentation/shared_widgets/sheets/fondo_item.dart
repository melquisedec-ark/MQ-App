import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../../domain/entities/fondo_pantalla.dart';
import 'sheet_helpers.dart';

// =============================================================================
// FondoItem — Preview de fondo según su tipo (color o imagen)
// =============================================================================

/// Widget que muestra preview de un fondo según su tipo.
class FondoItem extends StatelessWidget {
  final FondoPantalla fondo;
  final bool isSelected;
  final VoidCallback onTap;

  const FondoItem({
    super.key,
    required this.fondo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (fondo.tipo) {
            FondoPantallaTipo.colorSolido => _buildColorPreview(colorScheme),
            FondoPantallaTipo.imagen => _buildImagePreview(colorScheme),
          },
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              fondo.nombre,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreview(ColorScheme colorScheme) {
    final color = parseHexColor(fondo.colorHex) ?? colorScheme.surfaceContainerHighest;
    return _previewContainer(
      colorScheme: colorScheme,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isSelected
            ? Icon(Icons.check, size: 20, color: colorScheme.primary)
            : null,
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    return _previewContainer(
      colorScheme: colorScheme,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          image: fondo.rutaArchivo != null
              ? DecorationImage(
                  image: FileImage(File(fondo.rutaArchivo!)),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : null,
        ),
        child: Center(
          child: Icon(
            Icons.image,
            size: 24,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _previewContainer({
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: child,
      ),
    );
  }
}