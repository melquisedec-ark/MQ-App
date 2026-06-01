import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indica si el modo presentación (proyección) está activo.
///
/// Cuando es `true`, la ventana principal está configurada en modo
/// proyección (fullscreen, always-on-top, fondo negro) a través de
/// [DesktopWindowService], y la interfaz muestra [LiveControlScreen]
/// para controlar la navegación entre estrofas.
///
/// Se escribe desde [PresentButton] al presionar "Presentar"/"Detener".
final isPresentingProvider = StateProvider<bool>((ref) => false);
