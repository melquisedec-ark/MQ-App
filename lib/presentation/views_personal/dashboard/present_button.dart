import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/window_manager/window_providers.dart';
import '../../../core/window_manager/window_service.dart';
import '../../views_projection/providers/presentation_providers.dart';

/// Botón toggle para iniciar/detener el modo proyección en desktop.
///
/// Muestra "Presentar" / "Detener Presentación" según el estado actual
/// del provider [isPresentingProvider].
///
/// Al presionar "Presentar":
///  1. Abre la ventana de proyección vía [WindowService.openProjectionWindow]
///  2. Marca [isPresentingProvider] como `true`
///
/// Al presionar "Detener":
///  1. Cierra la ventana de proyección vía [WindowService.closeProjectionWindow]
///  2. Marca [isPresentingProvider] como `false`
///
/// Colores: fondo dorado intenso (#CCA43B), icono/texto negro (#1A1A1A).
class PresentButton extends ConsumerWidget {
  const PresentButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPresenting = ref.watch(isPresentingProvider);

    return FloatingActionButton.extended(
      heroTag: 'present_button',
      onPressed: () => _togglePresentation(context, ref, isPresenting),
      backgroundColor: isPresenting
          ? Theme.of(context).colorScheme.errorContainer
          : const Color(0xFFCCA43B),
      foregroundColor: const Color(0xFF1A1A1A),
      icon: Icon(
        isPresenting ? Icons.stop_screen_share : Icons.screen_share,
      ),
      label: Text(isPresenting ? 'Detener Presentación' : 'Presentar'),
    );
  }

  /// Alterna entre modo presentación y modo normal.
  Future<void> _togglePresentation(
    BuildContext context,
    WidgetRef ref,
    bool isPresenting,
  ) async {
    final windowService = ref.read(windowServiceProvider);
    try {
      if (isPresenting) {
        await windowService.closeProjectionWindow();
        ref.read(isPresentingProvider.notifier).state = false;
      } else {
        await windowService.openProjectionWindow({
          'mode': 'local',
          'source': 'dashboard',
        });
        ref.read(isPresentingProvider.notifier).state = true;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
