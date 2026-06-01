import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Provider que controla si el wakelock (mantener PC despierta) está activo.
/// Se usa en modo desktop para evitar que la PC entre en suspensión.
final wakelockProvider = StateNotifierProvider<WakelockNotifier, bool>((ref) {
  return WakelockNotifier();
});

class WakelockNotifier extends StateNotifier<bool> {
  WakelockNotifier() : super(false);

  /// Activa el wakelock: evita suspensión y apagado de pantalla.
  Future<void> enable() async {
    await WakelockPlus.enable();
    state = true;
  }

  /// Desactiva el wakelock: restaura comportamiento normal.
  Future<void> disable() async {
    await WakelockPlus.disable();
    state = false;
  }

  @override
  void dispose() {
    WakelockPlus.disable(); // Cleanup al destruir el provider
    super.dispose();
  }
}
