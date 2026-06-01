import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_mode.dart';
import 'dual_mode_providers.dart';

/// Botón flotante para cambiar entre modo PC y Celular.
///
/// Solo visible en modo debug (`kDebugMode`). Se posiciona en la
/// esquina inferior izquierda usando [Positioned] (debe usarse
/// dentro de un [Stack]).
///
/// Al presionarlo conmuta entre [DeviceMode.phone] y
/// [DeviceMode.desktop] a través de [DualModeNotifier.toggleMode].
class DeviceSwitch extends ConsumerWidget {
  const DeviceSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo visible en debug mode
    if (!kDebugMode) return const SizedBox.shrink();

    final mode = ref.watch(deviceModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: 16,
      bottom: 16,
      child: FloatingActionButton.small(
        onPressed: () => ref.read(deviceModeProvider.notifier).toggleMode(),
        backgroundColor: colorScheme.tertiaryContainer,
        child: Icon(
          mode == DeviceMode.phone
              ? Icons.phone_android
              : Icons.desktop_windows,
        ),
      ),
    );
  }
}
