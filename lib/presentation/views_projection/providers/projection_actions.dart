import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../../views_personal/providers/hymn_providers.dart';
import '../providers/live_control_providers.dart';
import '../../../core/window_manager/window_providers.dart';

/// Proyecta un himno en la ventana secundaria.
///
/// Carga el himno completo + estrofas desde el repositorio, actualiza
/// [liveControlProvider] y envía el mensaje [LOAD_HYMN] a la ventana
/// de proyección vía [WindowService.sendMessage].
///
/// Retorna `null` en éxito, o un mensaje de error en fallo.
///
/// NO abre la ventana de proyección ni muestra SnackBars.
/// Esas responsabilidades pertenecen al caller.
Future<String?> projectHymn(WidgetRef ref, Himno himno) async {
  try {
    final repo = ref.read(hymnRepositoryProvider);
    final himnoCompleto = await repo.getHymnById(himno.id);
    final versionPaisId = himnoCompleto.primaryVersionPaisId;
    final estrofas = await repo.getStanzas(versionPaisId);

    // 1. Actualizar estado local (liveControlProvider)
    ref.read(liveControlProvider.notifier).loadHymn(
          himnoCompleto,
          estrofas,
          versionPaisId: versionPaisId,
        );

    // 2. Enviar a la 2da ventana vía WindowService.sendMessage()
    final windowService = ref.read(windowServiceProvider);
    await windowService.sendMessage(
      _buildLoadHymnMessage(himnoCompleto, estrofas),
    );

    // 3. Sincronizar apariencia actual con la ventana de proyección
    final appearance = ref.read(hymnAppearanceProvider);
    await windowService.sendMessage(_buildSetConfigMessage(appearance));

    return null; // éxito
  } catch (e) {
    return e.toString();
  }
}

/// Construye el payload del mensaje [LOAD_HYMN].
Map<String, dynamic> _buildLoadHymnMessage(
  Himno himno,
  List<Estrofa> estrofas,
) {
  // totalSlides = título + N estrofas + "Amén"
  final totalSlides = 1 + estrofas.length + 1;
  return {
    'type': 'LOAD_HYMN',
    'himno_id': himno.id,
    'titulo': himno.titulo,
    'numero': himno.numero,
    'tipo': himno.tipo.name,
    'estrofas': estrofas
        .map((e) => {
              'id': e.id,
              'version_pais_id': e.versionPaisId,
              'tipo': e.tipo.name,
              'orden': e.orden,
              'contenido': e.contenido,
            },)
        .toList(),
    'currentIndex': 0,
    'totalSlides': totalSlides,
  };
}

/// Convierte [Color] a string hexadecimal con prefijo `#`.
String _colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

/// Construye el payload del mensaje [SET_CONFIG] con la apariencia actual.
Map<String, dynamic> _buildSetConfigMessage(HymnAppearanceState appearance) {
  return {
    'type': 'SET_CONFIG',
    // Nuevos campos de apariencia
    'textColor': _colorToHex(appearance.textColor),
    'chordColor': _colorToHex(appearance.chordColor),
    'fontFamily': appearance.fontFamily,
    'isBold': appearance.isBold,
    'fontScale': appearance.fontScale,
    'showChords': appearance.showChords,
    'cardOpacity': appearance.cardOpacity,
  };
}


