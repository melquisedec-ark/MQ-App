import 'package:flutter/material.dart';
import '../../core/utils/flag_utils.dart';
import '../../domain/entities/himno.dart';
import 'glass_card.dart';

/// Widget de tarjeta de himno para listas.
/// Recibe una entidad [Himno] del dominio.
/// Compatible con tema claro y oscuro.
class HymnCard extends StatelessWidget {
  final Himno himno;
  final VoidCallback? onTap;

  const HymnCard({
    super.key,
    required this.himno,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      onTap: onTap,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Número del himno
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${himno.numero ?? ''}',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Título y primera línea
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  himno.titulo,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (himno.primeraLinea != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    himno.primeraLinea!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    // Bandera del país
                    if (himno.paisCodigo != null &&
                        himno.paisCodigo!.isNotEmpty)
                      FlagUtils.codeToFlag(himno.paisCodigo).isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                FlagUtils.codeToFlag(himno.paisCodigo),
                                style: const TextStyle(fontSize: 20),
                              ),
                            )
                          : const SizedBox.shrink(),
                    // Categorías (sin límite, Wrap maneja el overflow)
                    ...(himno.categorias?.map((cat) {
                      return _buildChip(
                        context,
                        cat.nombre,
                        colorScheme.tertiaryContainer,
                        colorScheme.onTertiaryContainer,
                      );
                    }).toList() ?? []),
                    if (!himno.esOficial)
                      _buildChip(
                        context,
                        'Personal',
                        colorScheme.secondaryContainer,
                        colorScheme.onSecondaryContainer,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Icono de chevron
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
