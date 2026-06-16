import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/datasources/remote/grpc_control_datasource.dart';
import '../../../../domain/entities/fondo_pantalla.dart';
import '../../views_projection/providers/connection_providers.dart';
import '../../dual_mode_wrapper/dual_mode_providers.dart';
import '../providers/appearance_provider.dart';
import '../providers/fondo_options_provider.dart';
import 'sheet_helpers.dart';
import 'fondo_item.dart';
import 'font_option.dart';

// =============================================================================
// 1. Brush (Brocha) — Visual configuration sheet
// =============================================================================

/// Colores predefinidos para el texto de la letra.
const List<Color> _textColors = [
  Color(0xFF000000), // negro puro
  Color(0xFFFFFFFF), // blanco
  Color(0xFFB3261E), // rojo
  Color(0xFF1D6F42), // verde
  Color(0xFF1A6B8A), // azul
  Color(0xFF6750A4), // púrpura
];

/// Colores predefinidos para los acordes musicales.
/// El dorado (#CCA43B) es el color por defecto (paleta corporativa).
const List<Color> _chordColors = [
  Color(0xFFCCA43B), // dorado (default) — paleta corporativa
  Color(0xFFB3261E), // rojo
  Color(0xFF1A6B8A), // azul
  Color(0xFF1D6F42), // verde
  Color(0xFFFF8F00), // naranja
  Color(0xFF1C1B1F), // negro
];

/// Widget reutilizable para un selector de color circular.
class ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const ColorCircle({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check, size: 20, color: colorScheme.primary)
            : null,
      ),
    );
  }
}

/// Muestra el sheet de configuración visual (fondo, tamaño fuente,
/// color de letra, color de acordes).
void showBrushSheet(
  BuildContext context, {
  required WidgetRef ref,
}) {
  final isDesktop = ref.read(isDesktopModeProvider);

  if (isDesktop) {
    // ── Desktop: Dialog sin drag handle ──
    showDialog<void>(
      context: context,
      builder: (_) {
        return Consumer(
          builder: (context, ref, _) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final appearance = ref.watch(hymnAppearanceProvider);
            final fondosAsync = ref.watch(fondosActivosProvider);

            return Dialog(
              backgroundColor: colorScheme.surfaceContainerHigh,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: _brushSheetChildren(
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    appearance: appearance,
                    fondosAsync: fondosAsync,
                    ref: ref,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } else {
    // ── Móvil: ModalBottomSheet + DraggableScrollableSheet ──
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Consumer(
          builder: (context, ref, _) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final appearance = ref.watch(hymnAppearanceProvider);
            final fondosAsync = ref.watch(fondosActivosProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: <Widget>[
                    // ---- Handle (solo móvil) ----
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
                    ..._brushSheetChildren(
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      appearance: appearance,
                      fondosAsync: fondosAsync,
                      ref: ref,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Contenido compartido del sheet Brocha (sin handle, sin wrapper).
List<Widget> _brushSheetChildren({
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  required HymnAppearanceState appearance,
  required AsyncValue<List<FondoPantalla>> fondosAsync,
  required WidgetRef ref,
}) {
  // Si estamos conectados como emisor, los fondos son remotos (desde el PC)
  final isConnected = ref.watch(isConnectedProvider);
  final remoteFondosAsync = ref.watch(remoteBackgroundsProvider);

  return [
    // ---- Title ----
    Row(
      children: <Widget>[
        Icon(
          Icons.brush,
          color: colorScheme.tertiary,
        ),
        const SizedBox(width: 8),
        Text(
          'Configuración visual',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (ref.watch(isDesktopModeProvider)) ...[
          const SizedBox(width: 8),
          Chip(
            label: const Text('Personal + Proyección'),
            visualDensity: VisualDensity.compact,
            labelStyle: textTheme.labelSmall?.copyWith(
              color: colorScheme.tertiary,
            ),
            backgroundColor: colorScheme.tertiaryContainer,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ],
    ),
    const SizedBox(height: 20),

    // ==========================================
    // 1. Fondos (remotos si conectado, locales si no)
    // ==========================================
    if (isConnected) ..._remoteBackgroundSection(
      colorScheme,
      textTheme,
      remoteFondosAsync,
      ref,
    ) else ...[
      Text(
        'Fondos guardados',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 8),
      fondosAsync.when(
        loading: () => const SizedBox(
          height: 60,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Error al cargar fondos',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
        data: (fondos) {
          if (fondos.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No hay fondos guardados',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return Wrap(
            spacing: 16,
            runSpacing: 12,
            children: fondos.map((FondoPantalla fondo) {
              final isSelected = appearance.selectedFondo?.id == fondo.id;
              return FondoItem(
                fondo: fondo,
                isSelected: isSelected,
                onTap: () {
                  ref.read(hymnAppearanceProvider.notifier).setFondo(fondo);
                  syncBackgroundToProjection(ref);
                },
              );
            }).toList(),
          );
        },
      ),
    ],
    const SizedBox(height: 20),

    // ==========================================
    // 2. Efecto Glass (vidrio full-screen)
    // ==========================================
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(
        Icons.blur_on_rounded,
        color: Color(0xFFCCA43B),
      ),
      title: const Text('Efecto Glass'),
      subtitle: Text(
        'Fondo full-screen con blur y overlay de color',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      value: appearance.glassEnabled,
      onChanged: (value) {
        ref.read(hymnAppearanceProvider.notifier).setGlassEnabled(value);
        syncAppearanceToProjection(ref);
      },
    ),

    if (appearance.glassEnabled) ...[
      const SizedBox(height: 16),

      // Opacidad del vidrio
      Text(
        'Opacidad del vidrio',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Controla qué tanto se ve la imagen a través del vidrio',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: <Widget>[
          const Icon(Icons.opacity, size: 18),
          Expanded(
            child: Slider(
              value: appearance.cardOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '${(appearance.cardOpacity * 100).round()}%',
              onChanged: (value) {
                ref
                    .read(hymnAppearanceProvider.notifier)
                    .setCardOpacity(value);
                syncAppearanceToProjection(ref);
              },
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${(appearance.cardOpacity * 100).round()}%',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),

      // Intensidad de blur
      Text(
        'Intensidad de blur',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: <Widget>[
          const Icon(Icons.blur_circular, size: 18),
          Expanded(
            child: Slider(
              value: appearance.glassBlurSigma,
              min: 0.0,
              max: 20.0,
              divisions: 40,
              label: '${appearance.glassBlurSigma.toStringAsFixed(1)}px',
              onChanged: (value) {
                ref
                    .read(hymnAppearanceProvider.notifier)
                    .setGlassBlurSigma(value);
                syncAppearanceToProjection(ref);
              },
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${appearance.glassBlurSigma.toStringAsFixed(1)}px',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),

      // Color del overlay del vidrio
      Text(
        'Color del overlay',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Tonalidad del vidrio (elige el color que se mezcla con el fondo)',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Colors.white,
          Colors.black,
          const Color(0xFFB3261E), // rojo
          const Color(0xFF1D6F42), // verde
          const Color(0xFF1A6B8A), // azul
          const Color(0xFF6750A4), // púrpura
          const Color(0xFFCCA43B), // dorado
          const Color(0xFFFF8F00), // naranja
        ].map((color) {
          final isSelected = color.toARGB32() == appearance.glassOverlayColor.toARGB32();
          return ColorCircle(
            color: color,
            isSelected: isSelected,
            onTap: () {
              ref
                  .read(hymnAppearanceProvider.notifier)
                  .setGlassOverlayColor(color);
              syncAppearanceToProjection(ref);
            },
          );
        }).toList(),
      ),
    ],

    const SizedBox(height: 20),

    // ==========================================
    // 3. Tamaño de letra
    // ==========================================
    Text(
      'Tamaño de letra',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 4),
    Row(
      children: <Widget>[
        const Icon(Icons.text_fields, size: 18),
        Expanded(
          child: Slider(
            // Phase 2a.4: key para que los tests puedan identificar este
            // slider específico. El BrushSheet muestra varios sliders
            // (cardOpacity, glassBlurSigma, fontScale) y los tests
            // necesitan uno estable para interactuar.
            key: const Key('brush.font_scale_slider'),
            value: appearance.fontScale,
            min: 0.7,
            max: 1.8,
            divisions: 11,
            label:
                '${(appearance.fontScale * 100).round()}%',
            onChanged: (value) {
              ref
                  .read(hymnAppearanceProvider.notifier)
                  .setFontScale(value);
              syncAppearanceToProjection(ref);
              
            },
          ),
        ),
        const Icon(Icons.text_fields, size: 26),
      ],
    ),
    const SizedBox(height: 20),

    // ==========================================
    // 3b. Tamaño de letra — Proyección (desktop o emisor conectado)
    // ==========================================
    if (ref.watch(isDesktopModeProvider) || ref.watch(isConnectedProvider)) ...[
      const SizedBox(height: 16),
      Text(
        'Tamaño de letra — Proyección',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.tertiary,
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: <Widget>[
          const Icon(Icons.tv, size: 18),
          Expanded(
            child: Slider(
              value: appearance.projectionFontScale,
              min: 0.5,
              max: 4.5,
              divisions: 16,
              label:
                  '${(appearance.projectionFontScale * 100).round()}%',
              onChanged: (value) {
                ref
                    .read(hymnAppearanceProvider.notifier)
                    .setProjectionFontScale(value);
                syncAppearanceToProjection(ref);
                
              },
            ),
          ),
          const Icon(Icons.tv, size: 26),
        ],
      ),
      Text(
        'Escala independiente para la ventana de proyección',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ],
    const SizedBox(height: 20),

    // ==========================================
    // 4. Color de letra
    // ==========================================
    Text(
      'Color de letra',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _textColors.map((Color color) {
        final isSelected =
            appearance.textColor.toARGB32() == color.toARGB32();
        return ColorCircle(
          color: color,
          isSelected: isSelected,
          onTap: () {
            ref
                .read(hymnAppearanceProvider.notifier)
                .setTextColor(color);
            syncAppearanceToProjection(ref);
            
          },
        );
      }).toList(),
    ),
    const SizedBox(height: 20),

    // ==========================================
    // 5. Color de acordes
    // ==========================================
    Text(
      'Color de acordes',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _chordColors.map((Color color) {
        final isSelected =
            appearance.chordColor.toARGB32() == color.toARGB32();
        return ColorCircle(
          color: color,
          isSelected: isSelected,
          onTap: () {
            ref
                .read(hymnAppearanceProvider.notifier)
                .setChordColor(color);
            syncAppearanceToProjection(ref);
            
          },
        );
      }).toList(),
    ),
    const SizedBox(height: 24),

    // ==========================================
    // 6. Tipo de letra
    // ==========================================
    Text(
      'Tipo de letra',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      'Elige la tipografía para el texto de los himnos',
      style: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 12),

    const SizedBox(height: 12),
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FontOption(
          family: 'Merriweather',
          label: 'Merriweather',
          previewText: 'Texto',
          isSelected: appearance.fontFamily == 'Merriweather',
          onTap: () {
            ref.read(hymnAppearanceProvider.notifier).setFontFamily('Merriweather');
            syncAppearanceToProjection(ref);
            
          },
        ),
        FontOption(
          family: 'Lora',
          label: 'Lora',
          previewText: 'Texto',
          isSelected: appearance.fontFamily == 'Lora',
          onTap: () {
            ref.read(hymnAppearanceProvider.notifier).setFontFamily('Lora');
            syncAppearanceToProjection(ref);
            
          },
        ),
        FontOption(
          family: 'Playfair Display',
          label: 'Playfair Display',
          previewText: 'Texto',
          isSelected: appearance.fontFamily == 'Playfair Display',
          onTap: () {
            ref.read(hymnAppearanceProvider.notifier).setFontFamily('Playfair Display');
            syncAppearanceToProjection(ref);
            
          },
        ),
        FontOption(
          family: 'Cinzel',
          label: 'Cinzel',
          previewText: 'Texto',
          isSelected: appearance.fontFamily == 'Cinzel',
          onTap: () {
            ref.read(hymnAppearanceProvider.notifier).setFontFamily('Cinzel');
            syncAppearanceToProjection(ref);
            
          },
        ),
      ],
    ),
    const SizedBox(height: 16),

    // ── Negritas ──
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Negritas',
        style: textTheme.bodyLarge,
      ),
      subtitle: Text(
        'Aplicar negritas al texto del himno',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      value: appearance.isBold,
      onChanged: (bool value) {
        ref.read(hymnAppearanceProvider.notifier).setIsBold(value);
        syncAppearanceToProjection(ref);
        
      },
    ),
    const SizedBox(height: 24),

    // ==========================================
    // 7. Restablecer
    // ==========================================
    Center(
      child: TextButton.icon(
        onPressed: () {
          ref
              .read(hymnAppearanceProvider.notifier)
              .reset();
          syncAppearanceToProjection(ref);
          syncBackgroundToProjection(ref);
        },
        icon: const Icon(Icons.restart_alt),
        label: const Text('Restablecer valores'),
      ),
    ),
  ];
}

/// Construye la sección de Fondos Remotos (PC) para el sheet Brocha.
///
/// Muestra los fondos disponibles en el display remoto como [FilterChip]s.
/// Al seleccionar uno, envía [GrpcControlDataSource.sendSetBackground].
List<Widget> _remoteBackgroundSection(
  ColorScheme colorScheme,
  TextTheme textTheme,
  AsyncValue<List<Map<String, dynamic>>> remoteFondosAsync,
  WidgetRef ref,
) {
  return [
    Row(
      children: [
        Icon(Icons.desktop_windows, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Fondos del PC remoto',
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    ...remoteFondosAsync.when(
      loading: () => [
        const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ],
      error: (_, __) => [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Error al cargar fondos remotos',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ),
      ],
      data: (fondos) {
        if (fondos.isEmpty) {
          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No hay fondos disponibles en el PC',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ];
        }
        return [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: fondos.map((bg) {
              final bgId = bg['id'] as int;
              final nombre = bg['nombre'] as String;
              return FilterChip(
                label: Text(nombre, style: textTheme.labelSmall),
                selected: false,
                onSelected: (_) {
                  ref
                      .read(controlDataSourceProvider)
                      .sendSetBackground(bgId.toString());
                },
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ];
      },
    ),
    const SizedBox(height: 12),
  ];
}