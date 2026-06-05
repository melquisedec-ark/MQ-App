import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../../features/biblia/application/providers/biblia_version_provider.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../../views_personal/providers/hymn_providers.dart';
import '../providers/bible_appearance_provider.dart';
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

/// Mapea un [fontScale] numérico (0.7–1.8) a un [ProjectionFontSize] legacy.
///
/// Phase 2a.4: introducido para mantener compatibilidad con campos
/// legacy (`fontSize`) del receptor de proyección.
String _mapFontScaleToLegacySize(double fontScale) {
  if (fontScale < 0.85) return 'small';
  if (fontScale < 1.15) return 'medium';
  if (fontScale < 1.5) return 'large';
  return 'extraLarge';
}

/// Construye el payload del mensaje [SET_CONFIG] con la apariencia actual.
///
/// Phase 2a.4: el receptor espera tanto los campos NUEVOS (textColor,
/// chordColor, bgColor, fontScale, etc.) como los LEGACY (backgroundColor,
/// fontSize, transitionSpeed, background) que ya no se exponen al usuario
/// pero siguen siendo consumidos por la ventana de proyección para
/// mantener retrocompatibilidad con versiones viejas del subproceso.
Map<String, dynamic> _buildSetConfigMessage(HymnAppearanceState appearance) {
  final bgColor = appearance.bgColor;
  return {
    'type': 'SET_CONFIG',
    // ── Nuevos campos de apariencia ──
    'textColor': _colorToHex(appearance.textColor),
    'chordColor': _colorToHex(appearance.chordColor),
    'fontFamily': appearance.fontFamily,
    'isBold': appearance.isBold,
    'fontScale': appearance.fontScale,
    'bgColor': _colorToHex(bgColor),
    'showChords': appearance.showChords,
    'cardOpacity': appearance.cardOpacity,
    // ── Campos legacy (compatibilidad con receptor) ──
    // backgroundColor = bgColor (alias) — el receptor los usa como
    // sinónimos. Mantener ambos evita reset visual en subprocesos viejos.
    'backgroundColor': _colorToHex(bgColor),
    'fontSize': _mapFontScaleToLegacySize(appearance.fontScale),
    'transitionSpeed': 0.5, // default legacy; Phase 2a.4 sin UI dedicada
    // background: 'black' cuando no hay color sólido seleccionado,
    // 'color' en caso contrario (ver BUG_FONDO_RESET.md).
    'background': bgColor == Colors.transparent ? 'black' : 'color',
  };
}

/// Proyecta un capítulo bíblico completo en la ventana receptora.
///
/// Construye la lista de versículos, actualiza el estado local y
/// envía el mensaje LOAD_VERSE al subprocess.
///
/// Retorna `null` en éxito, o un mensaje de error en fallo.
Future<String?> projectBibleChapter(
  WidgetRef ref, {
  required int versionId,
  required int libroId,
  required int capitulo,
}) async {
  try {
    final bibliaRepo = ref.read(bibliaRepositoryProvider);

    // Obtener nombre del libro
    final libro = await bibliaRepo.getLibroById(libroId);
    if (libro == null) return 'Libro no encontrado';

    // Obtener versículos del capítulo
    final cap = await bibliaRepo.getCapitulo(libroId, capitulo);
    if (cap == null) return 'Capítulo no encontrado';

    final versiculos = await bibliaRepo.getVersiculosByCapitulo(cap.id);
    if (versiculos.isEmpty) return 'Sin versículos';

    final textos = versiculos.map((v) => v.texto).toList();

    // Actualizar estado local del emisor
    final notifier = ref.read(liveControlProvider.notifier);
    notifier.loadBibleChapter(
      libroNombre: libro.nombre,
      capitulo: capitulo,
      versiculos: textos,
    );

    // Enviar al receptor
    final windowService = ref.read(windowServiceProvider);
    await windowService.sendMessage({
      'type': 'LOAD_VERSE',
      'libroNombre': libro.nombre,
      'capitulo': capitulo,
      'versiculos': textos,
    });

    // Sincronizar apariencia bíblica con el receptor
    final bibleAppearance = ref.read(bibleAppearanceProvider);
    await windowService.sendMessage({
      'type': 'SET_BIBLE_THEME',
      'theme': bibleAppearance.theme,
    });
    await windowService.sendMessage({
      'type': 'SET_BIBLE_FONT_SIZE',
      'scale': bibleAppearance.fontScale,
    });

    return null; // Éxito
  } catch (e) {
    return e.toString();
  }
}


