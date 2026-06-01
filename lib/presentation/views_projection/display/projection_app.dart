import 'dart:async';
import 'dart:convert';
import 'dart:io' show stdin;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/estrofa_tipo.dart';
import '../../../core/enums/himno_tipo.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../shared_widgets/fullscreen_handler.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../providers/live_control_providers.dart';
import '../providers/projection_providers.dart';
import 'live_projection_screen.dart';

/// Punto de entrada para la segunda ventana de proyección.
///
/// Corre como una instancia Flutter separada lanzada vía [Process.start]
/// con el argumento `--projection`. Muestra [LiveProjectionScreen] cuando
/// hay un himno activo, o un texto de espera.
///
/// ## Comunicación entre ventanas
/// Recibe mensajes JSON desde el proceso padre a través de stdin.
/// Cada mensaje es una línea JSON independiente:
/// - `LOAD_HYMN`: Carga un himno completo con sus estrofas
/// - `NEXT_SLIDE`: Avanza al siguiente slide
/// - `PREV_SLIDE`: Retrocede al slide anterior
/// - `GO_TO_SLIDE`: Va a un slide específico por índice
/// - `NEXT_STANZA`: (deprecated) Usar NEXT_SLIDE
/// - `PREV_STANZA`: (deprecated) Usar PREV_SLIDE
/// - `GO_TO_STANZA`: (deprecated) Usar GO_TO_SLIDE con index + 1
/// - `SET_CONFIG`: Actualiza configuración visual
/// - `BLACKOUT`: Activa/desactiva el modo blackout
///
/// [stdinOverride] permite inyectar un stream de entrada alternativo
/// (p.ej. en tests) en lugar del global [stdin].
class ProjectionApp extends ConsumerStatefulWidget {
  final Stream<String>? stdinOverride;

  const ProjectionApp({super.key, this.stdinOverride});

  @override
  ConsumerState<ProjectionApp> createState() => _ProjectionAppState();
}

class _ProjectionAppState extends ConsumerState<ProjectionApp> {
  StreamSubscription<String>? _stdinSubscription;

  @override
  void initState() {
    super.initState();
    _setupStdinListener();
  }

  /// Configura la escucha de stdin para recibir mensajes JSON
  /// del proceso padre.
  ///
  /// Usa [widget.stdinOverride] si se proveyó (útil en tests);
  /// caso contrario lee del global [stdin] de `dart:io`.
  void _setupStdinListener() {
    try {
      final inputStream = widget.stdinOverride ??
          stdin
              .transform(utf8.decoder)
              .transform(const LineSplitter());
      _stdinSubscription = inputStream.listen(_handleMessage);
    } catch (_) {
      // Sin stdin disponible (web, test, etc.) — modo lectura sola
    }
  }

  /// Procesa un mensaje JSON recibido por stdin.
  void _handleMessage(String line) {
    try {
      final message = jsonDecode(line) as Map<String, dynamic>;
      final notifier = ref.read(liveControlProvider.notifier);
      switch (message['type'] as String?) {
        case 'LOAD_HYMN':
          _handleLoadHymn(notifier, message);
        // ── Nuevos comandos de slides ──
        case 'NEXT_SLIDE':
          notifier.nextSlide();
        case 'PREV_SLIDE':
          notifier.prevSlide();
        case 'GO_TO_SLIDE':
          final slideIndex = message['index'] as int;
          notifier.goToSlide(slideIndex);
        // ── Comandos legacy (backward compat) ──
        case 'NEXT_STANZA':
          notifier.nextSlide();
        case 'PREV_STANZA':
          notifier.prevSlide();
        case 'GO_TO_STANZA':
          final index = message['index'] as int;
          notifier.goToSlide(index + 1); // +1 por TitleSlide
        case 'SET_CONFIG':
          _handleSetConfig(message);
        case 'SET_BACKGROUND':
          final bgId = message['bgFondoId'] as String?;
          if (bgId != null) {
            _handleSetBackground(bgId);
          }
        case 'BLACKOUT':
          final enabled = message['enabled'] as bool;
          if (enabled) {
            notifier.blackout();
          } else {
            notifier.toggleBlackout();
          }
      }
    } catch (_) {
      // Ignorar mensajes mal formados
    }
  }

  /// Procesa un mensaje LOAD_HYMN: construye Himno y Estrofas
  /// a partir de los campos planos en el JSON.
  void _handleLoadHymn(
    LiveControlNotifier notifier,
    Map<String, dynamic> message,
  ) {
    final hymn = Himno(
      id: message['himno_id'] as int,
      titulo: message['titulo'] as String,
      numero: message['numero'] as int?,
      tipo: HimnoTipo.values.firstWhere(
        (e) => e.name == (message['tipo'] as String? ?? 'oficial'),
        orElse: () => HimnoTipo.oficial,
      ),
    );

    final estrofasJson = message['estrofas'] as List<dynamic>? ?? [];
    final estrofas = estrofasJson.map((e) {
      final m = e as Map<String, dynamic>;
      return Estrofa(
        id: m['id'] as int,
        versionPaisId: m['version_pais_id'] as int,
        tipo: EstrofaTipo.values.firstWhere(
          (t) => t.name == (m['tipo'] as String? ?? 'estrofa'),
          orElse: () => EstrofaTipo.estrofa,
        ),
        orden: m['orden'] as int,
        contenido: m['contenido'] as String,
      );
    }).toList();

    notifier.loadHymn(hymn, estrofas);
  }

  /// Procesa un mensaje SET_CONFIG: actualiza la configuración visual
  /// de la proyección (color de fondo, tamaño de fuente, velocidad de
  /// transición, fondo seleccionado, y apariencia de texto).
  void _handleSetConfig(Map<String, dynamic> message) {
    final appearanceNotifier = ref.read(hymnAppearanceProvider.notifier);

    // ── Campos de apariencia (Brocha) ──

    if (message.containsKey('textColor')) {
      final hex = message['textColor'] as String;
      try {
        final color = Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
        appearanceNotifier.setTextColor(color);
      } catch (_) {
        // Ignorar color inválido
      }
    }

    if (message.containsKey('chordColor')) {
      final hex = message['chordColor'] as String;
      try {
        final color = Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
        appearanceNotifier.setChordColor(color);
      } catch (_) {
        // Ignorar color inválido
      }
    }

    if (message.containsKey('fontFamily')) {
      appearanceNotifier.setFontFamily(message['fontFamily'] as String);
    }

    if (message.containsKey('isBold')) {
      appearanceNotifier.setIsBold(message['isBold'] as bool);
    }

    if (message.containsKey('fontScale')) {
      appearanceNotifier.setFontScale((message['fontScale'] as num).toDouble());
    }

    if (message.containsKey('projectionFontScale')) {
      appearanceNotifier.setProjectionFontScale(
        (message['projectionFontScale'] as num).toDouble(),
      );
    }

    if (message.containsKey('showChords') && message['showChords'] != null) {
      appearanceNotifier.setShowChords(message['showChords'] as bool);
    }

    if (message.containsKey('cardOpacity') && message['cardOpacity'] != null) {
      appearanceNotifier.setCardOpacity((message['cardOpacity'] as num).toDouble());
    }

    if (message.containsKey('glassBlurSigma') && message['glassBlurSigma'] != null) {
      appearanceNotifier.setGlassBlurSigma((message['glassBlurSigma'] as num).toDouble());
    }
    if (message.containsKey('glassEnabled') && message['glassEnabled'] != null) {
      appearanceNotifier.setGlassEnabled(message['glassEnabled'] as bool);
    }
    if (message.containsKey('glassOverlayColor') && message['glassOverlayColor'] != null) {
      final hex = message['glassOverlayColor'] as String;
      try {
        final color = Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
        appearanceNotifier.setGlassOverlayColor(color);
      } catch (_) {
        // Ignorar color inválido
      }
    }

    // ── Fondo: NO se procesa aquí. El fondo solo se cambia mediante ──
    // mensajes dedicados: SET_BACKGROUND (gRPC) o bgFondoId en SET_CONFIG
    // desde la ventana de proyección. SET_CONFIG del emisor NO transporta
    // fondo para evitar que se borre al cambiar apariencia.
  }

  /// Procesa un mensaje SET_BACKGROUND: carga y aplica el fondo
  /// de pantalla por ID en el subproceso de proyección.
  ///
  /// Busca el [FondoPantalla] en el repositorio local y lo asigna
  /// al [hymnAppearanceProvider] para que se renderice en pantalla.
  void _handleSetBackground(String bgId) {
    final id = int.tryParse(bgId);
    if (id == null) return;
    try {
      final repo = ref.read(fondoRepositoryProvider);
      repo.getAll().then((fondos) {
        final fondo = fondos.where((f) => f.id == id).firstOrNull;
        if (fondo != null) {
          ref.read(hymnAppearanceProvider.notifier).setFondo(fondo);
        }
      }).catchError((_) {
        // Ignorar errores asíncronos de carga del fondo
      });
    } catch (_) {
      // Ignorar errores de carga del fondo
    }
  }

  @override
  void dispose() {
    _stdinSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveControlProvider);

    return FullscreenHandler(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MQ App - Proyección',
        theme: AppTheme.projectionTheme,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: liveState.hymn == null
              ? const Center(
                  child: Text(
                    'Esperando proyección...',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : const LiveProjectionScreen(),
        ),
      ),
    );
  }
}
