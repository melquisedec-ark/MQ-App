import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap/app_initializer.dart';
import '../../../data/datasources/remote/grpc_display_server.dart';
import '../providers/live_control_providers.dart';
import 'live_projection_screen.dart';
import 'standby_screen.dart';

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Indica si hay al menos un cliente controlador conectado al display.
final isClientConnectedProvider = StateProvider<bool>((ref) => false);

/// Provider que expone la instancia del servidor gRPC del display.
///
/// Retorna `null` si la plataforma actual no es desktop (Linux, macOS,
/// Windows) o si el servidor no pudo iniciarse (ver
/// [AppInitializer._initDisplayServer]).
///
/// Incluye manejo explícito de plataforma para evitar crashes en web
/// o plataformas sin soporte de `dart:io`.
final grpcDisplayServerProvider = Provider<GrpcDisplayServer?>((ref) {
  if (kIsWeb) return null;
  try {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return AppInitializer.displayServer;
    }
  } catch (_) {
    // Platform no disponible
  }
  return null;
});

/// Información del estado del servidor gRPC para la UI del modo Receptor.
class ReceptorInfo {
  /// Indica si el servidor está corriendo y aceptando conexiones.
  final bool isRunning;

  /// Puerto en el que escucha el servidor (por defecto 50051).
  final int port;

  /// Nombre identificador del display en la red.
  final String displayName;

  const ReceptorInfo({
    required this.isRunning,
    required this.port,
    required this.displayName,
  });
}

/// Provider derivado que combina el estado del servidor gRPC en un
/// objeto [ReceptorInfo] fácil de consumir desde la UI.
///
/// Se actualiza reactivamente cuando cambia la instancia del servidor.
/// Los widgets hijos ([StandbyScreen], [LiveProjectionScreen]) pueden
/// consultar este provider sin acoplarse directamente a [GrpcDisplayServer].
final receptorInfoProvider = Provider<ReceptorInfo>((ref) {
  final server = ref.watch(grpcDisplayServerProvider);
  return ReceptorInfo(
    isRunning: server?.isRunning ?? false,
    port: server?.port ?? GrpcDisplayServer.defaultPort,
    displayName: server?.displayName ?? 'Display Principal',
  );
});

// ─────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────

/// Provider que determina qué pantalla mostrar en modo Receptor.
///
/// Cuando hay un himno cargado ([liveControlProvider.hymn] no es `null`)
/// y no está en blackout, muestra [LiveProjectionScreen]; en caso
/// contrario, muestra [StandbyScreen].
final receptorDisplayProvider = Provider<Widget>((ref) {
  final liveState = ref.watch(liveControlProvider);
  if (liveState.hymn != null && !liveState.isBlackout) {
    return const LiveProjectionScreen();
  }
  return const StandbyScreen();
});

/// Widget que envuelve el contenido del modo Display (Receptor).
///
/// Provee acceso al [GrpcDisplayServer] a través de [grpcDisplayServerProvider]
/// y expone [receptorInfoProvider] para que los hijos consulten el estado del
/// servidor (puerto, nombre, ejecución).
///
/// También escucha cambios en [liveControlProvider] para coordinar la
/// navegación entre [StandbyScreen] y [LiveProjectionScreen] cuando se
/// recibe un comando `JUMP_TO_HYMN` desde el controlador remoto.
class ReceptorBinding extends ConsumerStatefulWidget {
  /// Widget hijo que será envuelto (normalmente [StandbyScreen]).
  final Widget child;

  const ReceptorBinding({super.key, required this.child});

  @override
  ConsumerState<ReceptorBinding> createState() => _ReceptorBindingState();
}

class _ReceptorBindingState extends ConsumerState<ReceptorBinding> {
  ProviderSubscription<LiveControlState>? _subscription;

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  /// Escucha el estado de proyección y coordina la UI del display.
  ///
  /// Cuando se carga un himno por primera vez (`hymn` pasa de `null` a
  /// un valor), se notifica para que el widget padre (p.ej.
  /// [HimnarioDualApp]) pueda transicionar de [StandbyScreen] a
  /// [LiveProjectionScreen].
  void _setupListener() {
    _subscription = ref.listenManual(liveControlProvider, (
      LiveControlState? previous,
      LiveControlState next,
    ) {
      if (next.hymn != null && previous?.hymn == null) {
        // Himno cargado — la capa superior maneja la navegación
        // hacia LiveProjectionScreen.
      }
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
