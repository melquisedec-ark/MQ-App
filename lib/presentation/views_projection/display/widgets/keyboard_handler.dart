import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/live_control_providers.dart';

/// Widget que captura atajos de teclado para el modo Display (PC/TV).
///
/// Atajos disponibles:
/// - Flecha Derecha / Espacio: Siguiente estrofa
/// - Flecha Izquierda: Estrofa anterior
/// - B: Blackout / Encender
/// - R: Ir al coro
/// - Inicio: Ir al inicio
/// - Escape: Salir de la aplicación
class KeyboardHandler extends ConsumerWidget {
  final Widget child;

  const KeyboardHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        // Solo procesar eventos KeyDown
        if (event is KeyRepeatEvent) return KeyEventResult.handled;

        if (event is KeyDownEvent) {
          final result = _handleKeyEvent(event.logicalKey, ref);
          if (result) {
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  bool _handleKeyEvent(LogicalKeyboardKey key, WidgetRef ref) {
    switch (key.keyLabel) {
      case 'Arrow Right':
      case ' ':
        ref.read(liveControlProvider.notifier).nextSlide();
        return true;

      case 'Arrow Left':
        ref.read(liveControlProvider.notifier).prevSlide();
        return true;

      case 'B':
      case 'b':
        ref.read(liveControlProvider.notifier).toggleBlackout();
        return true;

      case 'R':
      case 'r':
        ref.read(liveControlProvider.notifier).goToChorus();
        return true;

      case 'Home':
        ref.read(liveControlProvider.notifier).goToStart();
        return true;

      default:
        return false;
    }
  }
}
