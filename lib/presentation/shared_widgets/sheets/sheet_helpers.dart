import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/window_manager/window_providers.dart';
import '../../views_projection/providers/connection_providers.dart';
import '../providers/appearance_provider.dart';

// =============================================================================
// Shared helpers used by multiple control sheets
// =============================================================================

/// Convierte un string hexadecimal (con o sin `#`) a [Color].
/// Retorna `null` si el string no es válido.
Color? parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final normalized = hex.replaceFirst('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('FF$normalized', radix: 16));
  }
  if (normalized.length == 8) {
    return Color(int.parse(normalized, radix: 16));
  }
  return null;
}

/// Convierte [Color] a string hexadecimal con prefijo `#`.
String colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

/// Mapea un [fontScale] numérico (0.7–1.8) al enum string legacy
/// `ProjectionFontSize` que el receptor de proyección aún consume.
///
/// Phase 2a.4: introducido para compatibilidad con la versión heredada
/// del subproceso de proyección que lee `fontSize` (string) en vez de
/// `fontScale` (double).
String fontScaleToLegacySize(double fontScale) {
  if (fontScale < 0.85) return 'small';
  if (fontScale < 1.15) return 'medium';
  if (fontScale < 1.5) return 'large';
  return 'extraLarge';
}

/// Envía el estado actual de [hymnAppearanceProvider] a la ventana
/// de proyección vía [WindowService.sendMessage] (silencioso).
///
/// FIX v2.1.7: NO envía bgColor, backgroundColor ni background en
/// SET_CONFIG para evitar que el fondo se resetee al cambiar
/// apariencia (texto, fuente, color, etc.). El fondo se maneja
/// exclusivamente vía mensajes SET_BACKGROUND dedicados.
void syncAppearanceToProjection(WidgetRef ref) {
  final appearance = ref.read(hymnAppearanceProvider);
  final message = <String, dynamic>{
    'type': 'SET_CONFIG',
    // Campos de apariencia (sin fondo)
    'textColor': colorToHex(appearance.textColor),
    'chordColor': colorToHex(appearance.chordColor),
    'fontFamily': appearance.fontFamily,
    'isBold': appearance.isBold,
    'fontScale': appearance.fontScale,
    'projectionFontScale': appearance.projectionFontScale,
    'showChords': appearance.showChords,
    'cardOpacity': appearance.cardOpacity,
    'glassBlurSigma': appearance.glassBlurSigma,
    'glassEnabled': appearance.glassEnabled,
    'glassOverlayColor': colorToHex(appearance.glassOverlayColor),
    // Campos legacy (sin backgroundColor ni background)
    'fontSize': fontScaleToLegacySize(appearance.fontScale),
    'transitionSpeed': 0.5,
  };
  // Fire-and-forget silencioso
  ref.read(windowServiceProvider).sendMessage(message);

  // NUEVO: Enviar por gRPC si estamos conectados como emisor
  final isConnected = ref.read(isConnectedProvider);
  if (isConnected) {
    final dataSource = ref.read(controlDataSourceProvider);
    dataSource.sendSetAppearance(
      textColor: colorToHex(appearance.textColor),
      chordColor: colorToHex(appearance.chordColor),
      fontFamily: appearance.fontFamily,
      isBold: appearance.isBold,
      showChords: appearance.showChords,
      cardOpacity: appearance.cardOpacity,
      projectionFontScale: appearance.projectionFontScale,
    ).catchError((_) => false);

    // NOTA: fontScale se envía en SET_CONFIG (WindowService → subproceso).
    // No se envía sendSetFontSize separado porque:
    // 1. El subproceso ya recibe fontScale vía SET_CONFIG
    // 2. sendSetFontSize en el proceso principal dispara _saveToDb()
    //    que sobreescribe bg_fondo_id = '' en la BD (contaminación)
  }
  // NOTA: El fondo NO se sincroniza aquí. El fondo solo debe enviarse
  // cuando el usuario cambia explícitamente el fondo (toca un fondo,
  // cambia color de fondo, o limpia fondo). Ver syncBackgroundToProjection().
}

/// Envía el fondo seleccionado actualmente a la ventana de proyección
/// (WindowService) y por gRPC (si estamos conectados como emisor).
///
/// Solo debe llamarse cuando el fondo CAMBIA explícitamente por acción
/// del usuario (seleccionar fondo, cambiar color de fondo, limpiar fondo).
/// NO debe llamarse al cambiar apariencia (fuente, color de letra, etc.).
void syncBackgroundToProjection(WidgetRef ref) {
  final appearance = ref.read(hymnAppearanceProvider);
  final bgId = appearance.selectedFondo?.id.toString();

  // Enviar a ventana de proyección local (WindowService)
  ref.read(windowServiceProvider).sendMessage({
    'type': 'SET_BACKGROUND',
    'bgFondoId': bgId ?? '0',
  });

  // Enviar por gRPC si conectado como emisor
  final isConnected = ref.read(isConnectedProvider);
  if (isConnected && bgId != null) {
    final dataSource = ref.read(controlDataSourceProvider);
    dataSource.sendSetBackground(bgId).catchError((_) => false);
  }
}