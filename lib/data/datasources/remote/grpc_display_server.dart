import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/estrofa_tipo.dart';
import '../../../core/enums/himno_tipo.dart';
import '../../../core/window_manager/window_providers.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/entities/projection_slide.dart';
import '../../../features/biblia/application/providers/biblia_version_provider.dart';
import '../../../features/biblia/application/providers/current_libro_provider.dart';
import '../../../features/biblia/application/providers/current_versiculo_provider.dart';
import '../../../features/biblia/application/providers/favoritos_provider.dart';
import '../../../features/biblia/data/models/versiculo.dart';
import '../../../features/biblia/data/repositories/biblia_repository.dart';
import '../../../presentation/shared_widgets/providers/appearance_provider.dart';
import '../../../presentation/views_projection/providers/live_control_providers.dart';
import '../../../presentation/views_projection/providers/presentation_providers.dart';
import '../../../presentation/views_projection/providers/projection_providers.dart';
import '../../../proto/generated/hymn_control.pbgrpc.dart';

/// Servidor gRPC para control remoto de un display.
///
/// Extiende [HymnControlServiceBase] generado por protobuf.
/// Escucha comandos de controladores remotos y los propaga mediante
/// el callback [onCommand] hacia los providers de Riverpod.
class GrpcDisplayServer extends HymnControlServiceBase {
  static final _log = Logger('GrpcDisplayServer');

  /// Puerto por defecto para el servidor gRPC.
  static const int defaultPort = 50051;

  /// Versión actual del protocolo.
  static const int protocolVersion = 1;

  /// Nombre identificador del display en la red.
  final String displayName;

  /// Identificador único de la sesión actual.
  final String sessionId;

  /// Puerto real en el que escucha el servidor (se asigna dinámicamente).
  int _actualPort = defaultPort;

  /// Callback para propagar comandos a los providers.
  /// Recibe una función de actualización del [LiveControlState].
  void Function(LiveControlState Function(LiveControlState) update)? onCommand;

  /// Callback para cargar un himno completo por ID.
  /// Se invoca cuando se recibe un comando [CommandType.JUMP_TO_HYMN].
  /// Debe cargar el himno y sus estrofas, y llamar a [LiveControlNotifier.loadHymn].
  Future<void> Function(int hymnId)? onJumpToHymn;

  /// Callback cuando un cliente se conecta exitosamente (handshake).
  void Function(String clientName)? onClientConnected;

  /// Callback para cargar un himno por payload completo (SendHymnContent).
  Future<void> Function(Himno hymn, List<Estrofa> stanzas)? onLoadHymnContent;

  Server? _server;
  bool _isRunning = false;

  /// Estado actual de la Biblia en el display (lo que está proyectando).
  /// Por defecto: Génesis 1:1 RV1909 (libro canónico 1, cap 1, v 1).
  _BibleDisplayState _bibleState = _BibleDisplayState.initial();

  /// Cache del `ModuleContext` para incluir en cada `DisplayStatus`.
  /// Se reconstruye cada vez que cambia `_bibleState` (en los handlers
  /// Bible). Mantenerlo en memoria evita abrir la BD en cada stream emit.
  ModuleContext? _bibleModuleContextCache;

  /// ProviderContainer opcional para acceder al estado real de LiveControl.
  final ProviderContainer? _container;

  /// Indica si el servidor está ejecutándose.
  bool get isRunning => _isRunning;

  /// Puerto en el que escucha el servidor (se asigna dinámicamente al iniciar).
  int get port => _actualPort;

  GrpcDisplayServer({
    this.displayName = 'Display Principal',
    int? port,
    String? sessionId,
    ProviderContainer? container,
  })  : _actualPort = port ?? defaultPort,
        sessionId = sessionId ?? const Uuid().v4(),
        _container = container;

  /// Inicia el servidor gRPC escuchando en todas las interfaces.
  ///
  /// Intenta puertos desde [defaultPort] hasta [defaultPort + 9] (50051-50060)
  /// en caso de que el puerto esté ocupado.
  Future<void> start() async {
    if (_isRunning) {
      _log.warning('El servidor ya está en ejecución.');
      return;
    }

    final maxAttempts = 10;
    int lastError = 0;

    for (int i = 0; i < maxAttempts; i++) {
      final tryPort = defaultPort + i;
      try {
        _server = Server.create(
          services: [this],
          keepAliveOptions: ServerKeepAliveOptions(
            minIntervalBetweenPingsWithoutData: Duration(seconds: 10),
            maxBadPings: 3,
          ),
        );
        await _server!.serve(
          address: InternetAddress.anyIPv4,
          port: tryPort,
        );
        _actualPort = tryPort;
        _isRunning = true;
        _log.info(
          'Servidor gRPC iniciado en 0.0.0.0:$tryPort '
          '(displayName: $displayName, sessionId: $sessionId)',
        );
        return;
      } catch (e) {
        lastError = tryPort;
        _log.warning('Puerto $tryPort no disponible ($e), intentando siguiente...');
        _server = null;
      }
    }

    _log.severe(
      'No se pudo iniciar servidor en ningún puerto entre '
      '$defaultPort-${defaultPort + maxAttempts - 1}. '
      'Último error: puerto $lastError',
    );
    throw Exception(
      'No hay puertos disponibles en rango '
      '$defaultPort-${defaultPort + maxAttempts - 1}',
    );
  }

  /// Detiene el servidor gRPC.
  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    await _server?.shutdown();
    _server = null;
    _log.info('Servidor gRPC detenido.');
  }

  @override
  Future<CommandResponse> sendCommand(
    ServiceCall call,
    CommandRequest request,
  ) async {
    _log.info(
      'Comando recibido: ${request.type} '
      '(stanzaIndex: ${request.hasStanzaIndex() ? request.stanzaIndex : null}, '
      'hymnId: ${request.hasHymnId() ? request.hymnId : null})',
    );

    try {
      switch (request.type) {
        case CommandType.NEXT_STANZA:
          _dispatch(
            (state) => state.copyWith(
              currentSlideIndex: state.hasNextSlide
                  ? state.currentSlideIndex + 1
                  : state.currentSlideIndex,
              isBlackout: false,
            ),
          );
          break;

        case CommandType.PREV_STANZA:
          _dispatch(
            (state) => state.copyWith(
              currentSlideIndex: state.hasPrevSlide
                  ? state.currentSlideIndex - 1
                  : state.currentSlideIndex,
              isBlackout: false,
            ),
          );
          break;

        case CommandType.GO_TO_STANZA:
          if (request.hasStanzaIndex()) {
            _dispatch((state) {
              // stanzaIndex 0 → slide 1 (primer lyrics después del título)
              final slideIdx = request.stanzaIndex + 1;
              final maxIdx = (state.slides.length - 1).clamp(0, 999);
              final idx = slideIdx.clamp(0, maxIdx);
              return state.copyWith(
                currentSlideIndex: idx,
                isBlackout: false,
              );
            });
          }
          break;

        case CommandType.GO_TO_CHORUS:
          _dispatch((state) {
            final chorusIndex = state.slides.indexWhere(
              (s) => s is LyricsSlide && s.estrofa.isChorus,
            );
            if (chorusIndex != -1) {
              return state.copyWith(
                currentSlideIndex: chorusIndex,
                isBlackout: false,
              );
            }
            return state;
          });
          break;

        case CommandType.BLACKOUT:
          _dispatch((state) => state.copyWith(isBlackout: true));
          break;

        case CommandType.CLEAR_BLACKOUT:
          _dispatch(
            (state) => state.copyWith(
              currentSlideIndex: 0,
              isBlackout: false,
            ),
          );
          break;

        case CommandType.JUMP_TO_HYMN:
          if (request.hasHymnId()) {
            _log.info('Cargando himno ${request.hymnId}...');
            onJumpToHymn?.call(request.hymnId);
          }
          break;

        case CommandType.PING:
          // No modifica estado, solo responder
          break;

        case CommandType.SET_BACKGROUND:
          if (_container != null && request.hasBackgroundId()) {
            try {
              final bgId = int.tryParse(request.backgroundId);
              if (bgId == null) {
                _log.warning('ID de fondo inválido: ${request.backgroundId}');
                break;
              }
              final repo = _container.read(fondoRepositoryProvider);
              final fondos = await repo.getAll();
              final fondo = fondos.where((f) => f.id == bgId).firstOrNull;
              if (fondo != null) {
                _container.read(hymnAppearanceProvider.notifier).setFondo(fondo);
                _log.info('Fondo cambiado a: ${fondo.nombre}');
                _syncBackgroundToSubprocess(bgId);
              } else {
                _log.warning('Fondo con ID $bgId no encontrado');
              }
            } catch (e) {
              _log.severe('Error al cambiar fondo: $e');
            }
          }
          break;

        case CommandType.SET_FONT_SIZE:
          if (_container != null && request.hasFontSize()) {
            final scale = request.fontSize / 48.0;
            _container.read(hymnAppearanceProvider.notifier).setFontScale(scale);
            _log.info('Tamaño de fuente cambiado a escala: $scale');
            _syncAppearanceToSubprocess();
          }
          break;

        case CommandType.SET_APPEARANCE:
          if (_container != null) {
            try {
              final notifier = _container.read(hymnAppearanceProvider.notifier);
              if (request.hasTextColor()) notifier.setTextColor(_parseHexColor(request.textColor));
              if (request.hasChordColor()) notifier.setChordColor(_parseHexColor(request.chordColor));
              if (request.hasFontFamily()) notifier.setFontFamily(request.fontFamily);
              if (request.hasIsBold()) notifier.setIsBold(request.isBold);
              if (request.hasShowChords()) notifier.setShowChords(request.showChords);
              if (request.hasCardOpacity()) notifier.setCardOpacity(request.cardOpacity);
              if (request.hasProjectionFontScale()) notifier.setProjectionFontScale(request.projectionFontScale);
              _log.info('Apariencia actualizada desde control remoto');
              _syncAppearanceToSubprocess();
            } catch (e) {
              _log.severe('Error al aplicar apariencia remota: $e');
            }
          }
          break;

        // ─── BIBLE MODULE COMMANDS ─────────────────────────────────
        // Tags 20-28. Manejan navegación, favoritos, cambio de módulo
        // y modo de vista del emisor.

        case CommandType.NEXT_VERSE:
          await _handleNextVerse();
          break;

        case CommandType.PREV_VERSE:
          await _handlePrevVerse();
          break;

        case CommandType.NEXT_CHAPTER:
          await _handleNextChapter();
          break;

        case CommandType.PREV_CHAPTER:
          await _handlePrevChapter();
          break;

        case CommandType.GO_TO_VERSE:
          if (request.hasTargetVerse()) {
            await _handleGoToVerse(
              versionId: request.targetVerse.versionId,
              libroNumero: request.targetVerse.libroNumero,
              capitulo: request.targetVerse.capitulo,
              versiculo: request.targetVerse.versiculo,
            );
          } else {
            _log.warning('GO_TO_VERSE sin targetVerse');
          }
          break;

        case CommandType.TOGGLE_FAVORITE:
          await _handleToggleFavorite();
          break;

        case CommandType.SWITCH_TO_BIBLE:
          await _handleSwitchToBible();
          break;

        case CommandType.SWITCH_TO_HIMNAL:
          // El himnario ya está manejado por LiveControl; este comando
          // solo limpia el cache de Biblia para que el próximo WatchStatus
          // no incluya `module_context` Biblia.
          _bibleModuleContextCache = null;
          _log.info('Cambio a módulo himnario solicitado');
          break;

        case CommandType.SET_EMITTER_VIEW_MODE:
          if (request.hasViewMode()) {
            _handleSetEmitterViewMode(request.viewMode);
          }
          break;

        case CommandType.SET_BIBLE_THEME:
          if (_container != null && request.hasBibleTheme()) {
            _container.read(liveControlProvider.notifier).setBibleTheme(request.bibleTheme);
            _container.read(windowServiceProvider).sendMessage({
              'type': 'SET_BIBLE_THEME',
              'theme': request.bibleTheme,
            });
            _log.info('Bible theme cambiado a: ${request.bibleTheme}');
          }
          break;

        case CommandType.SET_BIBLE_FONT_SCALE:
          if (_container != null && request.hasBibleFontScale()) {
            final scale = request.bibleFontScale.clamp(0.8, 4.0);
            _container.read(liveControlProvider.notifier).setBibleFontScale(scale);
            _container.read(windowServiceProvider).sendMessage({
              'type': 'SET_BIBLE_FONT_SIZE',
              'scale': scale,
            });
            _log.info('Bible font scale cambiado a: $scale');
          }
          break;

        default:
          _log.warning('Tipo de comando no manejado: ${request.type}');
      }

      return CommandResponse(success: true);
    } catch (e) {
      _log.severe('Error procesando comando: $e');
      return CommandResponse(
        success: false,
        errorMessage: 'Error interno: $e',
      );
    }
  }

  @override
  Future<DisplayStatus> getStatus(ServiceCall call, Empty request) async {
    // El estado actual se consulta indirectamente a través del callback.
    // Retornamos un estado por defecto; la sincronización en tiempo real
    // se maneja mediante watchStatus.
    return DisplayStatus(
      currentHymnId: 0,
      currentHymnTitle: '',
      currentStanzaIndex: 0,
      totalStanzas: 0,
      transpositionSemitones: 0,
      isBlackout: false,
      fontSize: 48.0,
      displayName: displayName,
    );
  }

  @override
  Stream<DisplayStatus> watchStatus(ServiceCall call, Empty request) async* {
    // Si no tenemos container, usar el fallback estático
    if (_container == null) {
      yield await getStatus(call, request);
      await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
        if (!_isRunning) break;
        yield await getStatus(call, request);
      }
      return;
    }

    // Emitir estado inicial real desde LiveControl
    yield _buildDisplayStatus();

    // Combinar cambios de estado con timer periódico como fallback
    final controller = StreamController<DisplayStatus>();

    // Escuchar cambios en el provider para emitir en cada cambio
    final sub = _container.listen<LiveControlState>(
      liveControlProvider,
      (previous, next) {
        if (!controller.isClosed) {
          controller.add(_buildDisplayStatus());
        }
      },
    );

    // Timer periódico como fallback adicional
    final timerSub = Stream.periodic(const Duration(seconds: 5)).listen((_) {
      if (!controller.isClosed) {
        controller.add(_buildDisplayStatus());
      }
    });

    try {
      // Pasar eventos del controller al generador
      await for (final status in controller.stream) {
        if (!_isRunning) break;
        yield status;
      }
    } finally {
      sub.close();
      await timerSub.cancel();
      await controller.close();
    }
  }

  /// Construye un [DisplayStatus] a partir del estado real de [LiveControlState].
  DisplayStatus _buildDisplayStatus() {
    final state = _container!.read(liveControlProvider);
    final lyrics =
        state.slides.whereType<LyricsSlide>().map((s) => s.estrofa).toList();

    // Evita crash en clamp(0, -1) cuando no hay himno cargado
    if (lyrics.isEmpty) {
      return DisplayStatus(
        currentHymnId: state.hymn?.id ?? 0,
        currentHymnTitle: state.hymn?.titulo ?? '',
        currentStanzaIndex: 0,
        totalStanzas: 0,
        transpositionSemitones: 0,
        isBlackout: state.isBlackout,
        fontSize: 48.0,
        displayName: displayName,
        moduleContext: _bibleModuleContextCache,
        bibleTheme: state.module == ProjectionModule.bible ? state.bibleTheme : null,
        bibleFontScale: state.module == ProjectionModule.bible ? state.bibleFontScale : null,
      );
    }

    final currentLyricsIndex = (state.currentSlideIndex - 1).clamp(0, lyrics.length - 1);
    return DisplayStatus(
      currentHymnId: state.hymn?.id ?? 0,
      currentHymnTitle: state.hymn?.titulo ?? '',
      currentStanzaIndex: currentLyricsIndex,
      totalStanzas: lyrics.length,
      transpositionSemitones: 0,
      isBlackout: state.isBlackout,
      fontSize: 48.0,
      displayName: displayName,
      moduleContext: _bibleModuleContextCache,
      bibleTheme: state.module == ProjectionModule.bible ? state.bibleTheme : null,
      bibleFontScale: state.module == ProjectionModule.bible ? state.bibleFontScale : null,
    );
  }

  @override
  Future<HandshakeResponse> handshake(
    ServiceCall call,
    HandshakeRequest request,
  ) async {
    _log.info(
      'Handshake recibido de ${request.clientName} '
      'v${request.clientVersion} (protocolo ${request.protocolVersion})',
    );

    onClientConnected?.call(request.clientName);

    return HandshakeResponse(
      accepted: true,
      serverName: 'MQ App Display',
      serverVersion: '2.0.0',
      displayName: displayName,
      protocolVersion: protocolVersion,
      sessionId: sessionId,
    );
  }

  @override
  Future<CommandResponse> sendHymnContent(
    ServiceCall call,
    HymnPayload request,
  ) async {
    _log.info(
      'SendHymnContent recibido: himno #${request.hymnId} '
      '(${request.titulo}) con ${request.estrofas.length} estrofas',
    );

    try {
      final himno = Himno(
        id: request.hymnId,
        titulo: request.titulo,
        numero: request.hasNumero() ? request.numero : null,
        tipo: HimnoTipo.values.firstWhere(
          (t) => t.name == request.tipo,
          orElse: () => HimnoTipo.oficial,
        ),
        versiones: [],
        categorias: [],
      );

      final estrofas = request.estrofas.map((s) => Estrofa(
        id: s.id,
        versionPaisId: s.versionPaisId,
        tipo: _parseStanzaType(s.tipo),
        orden: s.orden,
        contenido: s.contenido,
      ),).toList();

      await onLoadHymnContent?.call(himno, estrofas);
      return CommandResponse(success: true);
    } catch (e) {
      _log.severe('Error en sendHymnContent: $e');
      return CommandResponse(
        success: false,
        errorMessage: 'Error al procesar himno: $e',
      );
    }
  }

  @override
  Future<BackgroundList> getAvailableBackgrounds(
    ServiceCall call,
    Empty request,
  ) async {
    _log.info('GetAvailableBackgrounds solicitado');
    if (_container != null) {
      try {
        final repo = _container.read(fondoRepositoryProvider);
        final fondos = await repo.getAll();
        return BackgroundList(
          backgrounds: fondos.map((f) => BackgroundInfo(
            id: f.id,
            nombre: f.nombre,
            tipo: f.tipo.name,
          ),).toList(),
        );
      } catch (e) {
        _log.warning('Error al leer fondos del PC: $e');
      }
    }
    return BackgroundList(
      backgrounds: [
        BackgroundInfo(id: 0, nombre: 'Negro', tipo: 'color'),
        BackgroundInfo(id: 1, nombre: 'Cielo Azul', tipo: 'image'),
      ],
    );
  }

  /// Despacha una actualización de estado vía el callback [onCommand].
  void _dispatch(LiveControlState Function(LiveControlState) update) {
    onCommand?.call(update);
  }

  /// Parsea el tipo de estrofa desde el string del proto al enum de dominio.
  static EstrofaTipo _parseStanzaType(String tipo) {
    switch (tipo) {
      case 'coro':
        return EstrofaTipo.coro;
      case 'intro':
        return EstrofaTipo.intro;
      case 'amen':
        return EstrofaTipo.final_;
      default:
        return EstrofaTipo.estrofa;
    }
  }

  /// Convierte un string hex (#AARRGGBB o #RRGGBB) a Color.
  static Color _parseHexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) buffer.write('FF');
    buffer.write(hex);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convierte [Color] a string hexadecimal con prefijo `#`.
  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Sincroniza la apariencia actual con la ventana de proyección (subproceso).
  ///
  /// Envía un mensaje SET_CONFIG al [WindowService] para que el subproceso
  /// de proyección reciba los cambios de apariencia que llegaron por gRPC.
  /// bgFondoId se omite intencionalmente (se maneja vía SET_BACKGROUND).
  void _syncAppearanceToSubprocess() {
    if (_container == null) return;
    try {
      final appearance = _container.read(hymnAppearanceProvider);
      final message = <String, dynamic>{
        'type': 'SET_CONFIG',
        'textColor': _colorToHex(appearance.textColor),
        'chordColor': _colorToHex(appearance.chordColor),
        'fontFamily': appearance.fontFamily,
        'isBold': appearance.isBold,
        'fontScale': appearance.fontScale,
        'projectionFontScale': appearance.projectionFontScale,
        'showChords': appearance.showChords,
        'cardOpacity': appearance.cardOpacity,
        'glassBlurSigma': appearance.glassBlurSigma,
        'glassEnabled': appearance.glassEnabled,
        'glassOverlayColor': _colorToHex(appearance.glassOverlayColor),
      };
      _container.read(windowServiceProvider).sendMessage(message);

      // Sincronizar fondo SIEMPRE (SET_CONFIG no transporta fondo).
      // Si selectedFondo es null, envía '0' como señal de "sin fondo".
      _syncBackgroundToSubprocess(appearance.selectedFondo?.id ?? 0);

      _log.fine('Apariencia sincronizada con subproceso');
    } catch (e) {
      _log.warning('Error al sincronizar apariencia con subproceso: $e');
    }
  }

  /// Sincroniza el fondo seleccionado con la ventana de proyección (subproceso).
  ///
  /// Envía un mensaje SET_BACKGROUND al [WindowService] para que el subproceso
  /// cargue el mismo fondo que se seleccionó vía gRPC.
  void _syncBackgroundToSubprocess(int bgId) {
    if (_container == null) return;
    try {
      _container.read(windowServiceProvider).sendMessage({
        'type': 'SET_BACKGROUND',
        'bgFondoId': bgId.toString(),
      });
      _log.fine('Fondo sincronizado con subproceso: $bgId');
    } catch (e) {
      _log.warning('Error al sincronizar fondo con subproceso: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────
  // BIBLE COMMAND HANDLERS (Phase 2a.3)
  // ───────────────────────────────────────────────────────────────
  // Cada handler:
  // 1. Actualiza `_bibleState` (estado del display).
  // 2. Resuelve prev/next versículos (async) y actualiza el cache
  //    `_bibleModuleContextCache` para que el próximo `WatchStatus` lo
  //    incluya en `module_context`.
  // 3. Sincroniza con los providers del Bible reader móvil
  //    (`currentVersionIdProvider`, `currentLibroIdProvider`, etc.)
  //    para que la UI del emisor refleje el estado del display.
  // 4. Persiste favorito si corresponde.
  // Si `_container` es null (modo display puro), solo actualiza el
  // estado interno y el cache.

  Future<void> _handleNextVerse() async {
    if (_container == null) {
      _log.warning('NEXT_VERSE sin container; se ignora');
      return;
    }
    final repo = _container.read(bibliaRepositoryProvider);
    final cap = await repo.getCapitulo(
      await _libroIdForNumero(repo, _bibleState.versionId, _bibleState.libroNumero) ?? -1,
      _bibleState.capitulo,
    );
    if (cap != null) {
      if (_bibleState.versiculoNumero < cap.totalVersiculos) {
        await _updateBibleVerse(_bibleState.versiculoNumero + 1);
        await _updateLiveControlFromBibleState();
        // Enviar NEXT_SLIDE al subproceso de proyección
        try {
          _container.read(windowServiceProvider).sendMessage({'type': 'NEXT_SLIDE'});
        } catch (e) {
          _log.warning('Error enviando NEXT_SLIDE al subproceso: $e');
        }
        return;
      }
    }
    // Último versículo del capítulo → primer versículo del siguiente
    final nextCap = await _getNextCapituloOrLibro();
    if (nextCap != null) {
      _bibleState = _bibleState.copyWith(
        libroNumero: nextCap.$1,
        capitulo: nextCap.$2,
      );
      await _updateBibleVerse(1);
      _updateLiveControlFromBibleState();
      // Cargar nuevo capítulo y enviar LOAD_VERSE
      await _sendCurrentChapterToSubprocess();
    } else {
      // No hay siguiente capítulo, solo avanzar slide
      try {
        _container.read(windowServiceProvider).sendMessage({'type': 'NEXT_SLIDE'});
      } catch (e) {
        _log.warning('Error enviando NEXT_SLIDE al subproceso: $e');
      }
    }
  }

  Future<void> _handlePrevVerse() async {
    if (_container == null) return;
    if (_bibleState.versiculoNumero > 1) {
      await _updateBibleVerse(_bibleState.versiculoNumero - 1);
      _updateLiveControlFromBibleState();
      try {
        _container.read(windowServiceProvider).sendMessage({'type': 'PREV_SLIDE'});
      } catch (e) {
        _log.warning('Error enviando PREV_SLIDE al subproceso: $e');
      }
      return;
    }
    final prevCap = await _getPrevCapituloOrLibro();
    if (prevCap != null) {
      _bibleState = _bibleState.copyWith(
        libroNumero: prevCap.$1,
        capitulo: prevCap.$2,
      );
      final repo = _container.read(bibliaRepositoryProvider);
      final libro = await repo.getLibroByNumero(
        _bibleState.versionId,
        _bibleState.libroNumero,
      );
      if (libro != null) {
        final cap = await repo.getCapitulo(libro.id, _bibleState.capitulo);
        if (cap != null) {
          await _updateBibleVerse(cap.totalVersiculos);
          await _updateLiveControlFromBibleState();
          await _sendCurrentChapterToSubprocess();
        }
      }
    } else {
      try {
        _container.read(windowServiceProvider).sendMessage({'type': 'PREV_SLIDE'});
      } catch (e) {
        _log.warning('Error enviando PREV_SLIDE al subproceso: $e');
      }
    }
  }

  Future<void> _handleNextChapter() async {
    if (_container == null) return;
    final nextCap = await _getNextCapituloOrLibro();
    if (nextCap != null) {
      _bibleState = _bibleState.copyWith(
        libroNumero: nextCap.$1,
        capitulo: nextCap.$2,
      );
      await _updateBibleVerse(1);
      _updateLiveControlFromBibleState();
      await _sendCurrentChapterToSubprocess();
    }
  }

  Future<void> _handlePrevChapter() async {
    if (_container == null) return;
    if (_bibleState.capitulo > 1) {
      _bibleState = _bibleState.copyWith(capitulo: _bibleState.capitulo - 1);
      await _updateBibleVerse(1);
      _updateLiveControlFromBibleState();
      await _sendCurrentChapterToSubprocess();
      return;
    }
    final prevCap = await _getPrevCapituloOrLibro();
    if (prevCap != null) {
      _bibleState = _bibleState.copyWith(
        libroNumero: prevCap.$1,
        capitulo: prevCap.$2,
      );
      await _updateBibleVerse(1);
      _updateLiveControlFromBibleState();
      await _sendCurrentChapterToSubprocess();
    }
  }

  Future<void> _handleGoToVerse({
    required int versionId,
    required int libroNumero,
    required int capitulo,
    required int versiculo,
  }) async {
    if (_container == null) return;
    if (versionId <= 0 || libroNumero <= 0 || capitulo <= 0 || versiculo <= 0) {
      _log.warning('GO_TO_VERSE con valores inválidos: v=$versionId '
          'l=$libroNumero c=$capitulo v=$versiculo');
      return;
    }
    // Detectar si cambió el capítulo o solo el versículo.
    // También verificar que el receptor ya tenga contenido bíblico cargado.
    final yaTieneBiblia = _container!.read(liveControlProvider).module ==
            ProjectionModule.bible &&
        _container!.read(liveControlProvider).slides.isNotEmpty;
    final mismoCapitulo = _bibleState.versionId == versionId &&
        _bibleState.libroNumero == libroNumero &&
        _bibleState.capitulo == capitulo;

    _bibleState = _bibleState.copyWith(
      versionId: versionId,
      libroNumero: libroNumero,
      capitulo: capitulo,
      versiculoNumero: versiculo,
    );
    await _resolveAndCacheBibleContext();
    _syncBibleStateToProviders();

    if (mismoCapitulo && yaTieneBiblia) {
      // Solo cambiar versículo dentro del mismo capítulo ya cargado
      try {
        _container!.read(windowServiceProvider).sendMessage({
          'type': 'GO_TO_SLIDE',
          'index': versiculo - 1,
        });
      } catch (e) {
        _log.warning('Error enviando GO_TO_SLIDE al subproceso: $e');
      }
    } else {
      // Capítulo nuevo o primera carga: cargar completo
      _updateLiveControlFromBibleState();
      try {
        await _sendCurrentChapterToSubprocess();
        _container!.read(windowServiceProvider).sendMessage({
          'type': 'GO_TO_SLIDE',
          'index': versiculo - 1,
        });
      } catch (e) {
        _log.warning('Error enviando GO_TO_VERSE al subproceso: $e');
      }
    }
  }

  /// Actualiza [liveControlProvider] con el capítulo bíblico actual para que
  /// el receptor muestre [LiveProjectionScreen] en vez de [StandbyScreen].
  /// Ahora es async y espera a que la BD termine.
  Future<void> _updateLiveControlFromBibleState() async {
    if (_container == null) return;
    final container = _container;
    try {
      final repo = container!.read(bibliaRepositoryProvider);
      final libro = await repo.getLibroByNumero(
        _bibleState.versionId,
        _bibleState.libroNumero,
      );
      if (libro == null) return;
      final cap = await repo.getCapitulo(libro.id, _bibleState.capitulo);
      if (cap == null) return;
      final versiculos = await repo.getVersiculosByCapitulo(cap.id);
      if (versiculos.isEmpty) return;
      container.read(liveControlProvider.notifier).loadBibleChapter(
        libroNombre: libro.nombre,
        capitulo: _bibleState.capitulo,
        versiculos: versiculos.map((v) => v.texto).toList(),
      );
    } catch (_) {
      // Silencioso
    }
  }

  Future<void> _handleToggleFavorite() async {
    if (_container == null) return;
    final repo = _container.read(favoritosRepositoryProvider);
    final biblia = _container.read(bibliaRepositoryProvider);
    final libro = await biblia.getLibroByNumero(
      _bibleState.versionId,
      _bibleState.libroNumero,
    );
    if (libro == null) {
      _log.warning('TOGGLE_FAVORITE: libro ${_bibleState.libroNumero} no existe');
      return;
    }
    final isFav = await repo.isFavorito(
      _bibleState.versionId,
      libro.id,
      _bibleState.capitulo,
      _bibleState.versiculoNumero,
    );
    if (isFav) {
      await repo.remove(
        _bibleState.versionId,
        libro.id,
        _bibleState.capitulo,
        _bibleState.versiculoNumero,
      );
      _log.fine('Favorito removido vía gRPC');
    } else {
      await repo.add(
        _bibleState.versionId,
        libro.id,
        _bibleState.capitulo,
        _bibleState.versiculoNumero,
      );
      _log.fine('Favorito agregado vía gRPC');
    }
  }

  Future<void> _handleSwitchToBible() async {
    _bibleState = _BibleDisplayState.initial();
    await _resolveAndCacheBibleContext();
    _syncBibleStateToProviders();
    _updateLiveControlFromBibleState();
    // Cargar Génesis 1 y enviar LOAD_VERSE al subproceso
    await _sendCurrentChapterToSubprocess();
    _log.info('Cambio a módulo Biblia solicitado');
  }

  void _handleSetEmitterViewMode(EmitterViewMode mode) {
    _bibleState = _bibleState.copyWith(viewMode: mode);
    // El viewMode es preferencia del emisor (lado cliente), no se
    // transporta en `module_context` del display. Solo lo guardamos
    // internamente; el próximo `WatchStatus` indicará el cambio vía
    // el log, y el cliente lo refleja en su UI local.
    _log.fine('View mode actualizado: $mode');
  }

  /// Carga el capítulo actual desde la BD y envía LOAD_VERSE al subproceso.
  ///
  /// Resuelve el libro por número canónico, obtiene el capítulo y todos
  /// sus versículos, y los envía como mensaje JSON al proceso de proyección.
  Future<void> _sendCurrentChapterToSubprocess() async {
    if (_container == null) return;
    try {
      final repo = _container.read(bibliaRepositoryProvider);
      final libro = await repo.getLibroByNumero(
        _bibleState.versionId,
        _bibleState.libroNumero,
      );
      if (libro == null) {
        _log.warning('Libro ${_bibleState.libroNumero} no encontrado para LOAD_VERSE');
        return;
      }
      final cap = await repo.getCapitulo(libro.id, _bibleState.capitulo);
      if (cap == null) {
        _log.warning('Capítulo ${_bibleState.capitulo} no encontrado para LOAD_VERSE');
        return;
      }
      final versiculos = await repo.getVersiculosByCapitulo(cap.id);
      _container.read(windowServiceProvider).sendMessage({
        'type': 'LOAD_VERSE',
        'libroNombre': libro.nombre,
        'capitulo': _bibleState.capitulo,
        'versiculos': versiculos.map((v) => v.texto).toList(),
      });
      _log.fine('LOAD_VERSE enviado: ${libro.nombre} ${_bibleState.capitulo} '
          '(${versiculos.length} versículos)');
    } catch (e) {
      _log.warning('Error enviando LOAD_VERSE al subproceso: $e');
    }
  }

  /// Resuelve el versículo actual (y prev/next) y actualiza el cache.
  Future<void> _resolveAndCacheBibleContext() async {
    if (_container == null) return;
    final repo = _container.read(bibliaRepositoryProvider);
    final libro = await repo.getLibroByNumero(
      _bibleState.versionId,
      _bibleState.libroNumero,
    );
    if (libro == null) {
      _log.warning('Libro ${_bibleState.libroNumero} no encontrado');
      return;
    }
    final cap = await repo.getCapitulo(libro.id, _bibleState.capitulo);
    if (cap == null) {
      _log.warning('Capítulo ${_bibleState.capitulo} no encontrado');
      return;
    }
    final current = await repo.getVersiculo(cap.id, _bibleState.versiculoNumero);
    if (current == null) {
      _log.warning('Versículo ${_bibleState.versiculoNumero} no encontrado');
      return;
    }
    final version = await repo.getVersionById(_bibleState.versionId);

    // Prev/next del mismo capítulo
    final allVersiculos = await repo.getVersiculosByCapitulo(cap.id);
    final idx = allVersiculos.indexWhere((v) => v.id == current.id);
    Versiculo? prev;
    Versiculo? next;
    if (idx > 0) prev = allVersiculos[idx - 1];
    if (idx >= 0 && idx + 1 < allVersiculos.length) {
      next = allVersiculos[idx + 1];
    } else {
      // Último versículo del capítulo → primero del siguiente
      final nextCap = await _getNextCapituloOrLibro();
      if (nextCap != null) {
        final nextLibro = await repo.getLibroByNumero(
          _bibleState.versionId,
          nextCap.$1,
        );
        if (nextLibro != null) {
          final nc = await repo.getCapitulo(nextLibro.id, nextCap.$2);
          if (nc != null) {
            final nv = await repo.getVersiculosByCapitulo(nc.id);
            if (nv.isNotEmpty) next = nv.first;
          }
        }
      }
    }
    if (_bibleState.versiculoNumero == 1) {
      // Primer versículo → último del capítulo anterior
      final prevCap = await _getPrevCapituloOrLibro();
      if (prevCap != null) {
        final prevLibro = await repo.getLibroByNumero(
          _bibleState.versionId,
          prevCap.$1,
        );
        if (prevLibro != null) {
          final pc = await repo.getCapitulo(prevLibro.id, prevCap.$2);
          if (pc != null) {
            final pv = await repo.getVersiculosByCapitulo(pc.id);
            if (pv.isNotEmpty) prev = pv.last;
          }
        }
      }
    }

    final reference = VerseReference()
      ..versionId = _bibleState.versionId
      ..libroNumero = _bibleState.libroNumero
      ..capitulo = _bibleState.capitulo
      ..versiculo = _bibleState.versiculoNumero;

    final payload = VersePayload()
      ..reference = reference
      ..libroNombre = libro.nombre
      ..libroAbreviatura = libro.abreviatura
      ..texto = current.texto
      ..versionAbreviatura = version?.abreviatura ?? '';

    final ctx = ModuleContext()
      ..module = ModuleType.MODULE_BIBLIA
      ..currentVerse = payload
      ..prevText = prev?.texto ?? ''
      ..currentText = current.texto
      ..nextText = next?.texto ?? '';

    _bibleModuleContextCache = ctx;
    // Actualizar también el state local con los nombres resueltos.
    _bibleState = _bibleState.copyWith(
      libroNombre: libro.nombre,
      libroAbreviatura: libro.abreviatura,
      versionAbreviatura: version?.abreviatura,
    );
  }

  /// Actualiza el número de versículo y re-resuelve el contexto.
  Future<void> _updateBibleVerse(int nuevoNumero) async {
    _bibleState = _bibleState.copyWith(versiculoNumero: nuevoNumero);
    await _resolveAndCacheBibleContext();
    _syncBibleStateToProviders();
  }

  /// Sincroniza el estado bíblico del display con los providers del
  /// Bible reader móvil (si el emisor también tiene su UI abierta).
  void _syncBibleStateToProviders() {
    if (_container == null) return;
    try {
      _container.read(currentVersionIdProvider.notifier).state =
          _bibleState.versionId;
      _container.read(currentCapituloProvider.notifier).state =
          _bibleState.capitulo;
      _container.read(currentVersiculoNumeroProvider.notifier).state =
          _bibleState.versiculoNumero;
      // El libro por id se setea solo si podemos resolverlo. Si no,
      // el emisor usará el número canónico directamente.
      _container.read(bibliaRepositoryProvider).getLibroByNumero(
        _bibleState.versionId,
        _bibleState.libroNumero,
      ).then((libro) {
        if (libro != null) {
          _container.read(currentLibroIdProvider.notifier).state = libro.id;
        }
      });
    } catch (e) {
      _log.warning('Error sincronizando estado Biblia con providers: $e');
    }
  }

  /// Resuelve el `libroId` interno a partir de (versionId, libroNumero).
  /// Helper para `NEXT_VERSE` / `PREV_VERSE` que necesitan el id.
  Future<int?> _libroIdForNumero(
    BibliaRepository repo,
    int versionId,
    int libroNumero,
  ) async {
    final libro = await repo.getLibroByNumero(versionId, libroNumero);
    return libro?.id;
  }

  /// Devuelve el siguiente (libroNumero, capitulo) o null si no hay.
  /// Tuple simple con `Record` de Dart 3.
  Future<(int, int)?> _getNextCapituloOrLibro() async {
    if (_container == null) return null;
    final repo = _container.read(bibliaRepositoryProvider);
    final libro = await repo.getLibroByNumero(
      _bibleState.versionId,
      _bibleState.libroNumero,
    );
    if (libro == null) return null;
    final caps = await repo.getCapitulosByLibro(libro.id);
    final idx = caps.indexWhere((c) => c.numero == _bibleState.capitulo);
    if (idx == -1) return null;
    if (idx + 1 < caps.length) {
      return (_bibleState.libroNumero, caps[idx + 1].numero);
    }
    // Último capítulo → primer capítulo del siguiente libro
    final allLibros = await repo.getLibrosByVersion(_bibleState.versionId);
    final libroIdx = allLibros.indexWhere((l) => l.numero == _bibleState.libroNumero);
    if (libroIdx == -1 || libroIdx + 1 >= allLibros.length) return null;
    final nextLibro = allLibros[libroIdx + 1];
    final nextCaps = await repo.getCapitulosByLibro(nextLibro.id);
    if (nextCaps.isEmpty) return null;
    return (nextLibro.numero, nextCaps.first.numero);
  }

  /// Devuelve el anterior (libroNumero, capitulo) o null si no hay.
  Future<(int, int)?> _getPrevCapituloOrLibro() async {
    if (_container == null) return null;
    final repo = _container.read(bibliaRepositoryProvider);
    final libro = await repo.getLibroByNumero(
      _bibleState.versionId,
      _bibleState.libroNumero,
    );
    if (libro == null) return null;
    final caps = await repo.getCapitulosByLibro(libro.id);
    final idx = caps.indexWhere((c) => c.numero == _bibleState.capitulo);
    if (idx == -1) return null;
    if (idx > 0) {
      return (_bibleState.libroNumero, caps[idx - 1].numero);
    }
    // Primer capítulo → último capítulo del libro anterior
    final allLibros = await repo.getLibrosByVersion(_bibleState.versionId);
    final libroIdx = allLibros.indexWhere((l) => l.numero == _bibleState.libroNumero);
    if (libroIdx <= 0) return null;
    final prevLibro = allLibros[libroIdx - 1];
    final prevCaps = await repo.getCapitulosByLibro(prevLibro.id);
    if (prevCaps.isEmpty) return null;
    return (prevLibro.numero, prevCaps.last.numero);
  }
}

/// Estado interno del display para la Biblia.
///
/// Se mantiene en `GrpcDisplayServer` para que el display sepa qué
/// versículo está proyectando. No se persiste — un reinicio del
/// servidor vuelve a Génesis 1:1.
class _BibleDisplayState {
  /// Versión bíblica. 1 = RV1909, 2 = RV1569.
  final int versionId;

  /// Número canónico del libro (1-66), NO el id interno de la BD.
  final int libroNumero;

  /// Número del capítulo dentro del libro.
  final int capitulo;

  /// Número del versículo dentro del capítulo.
  final int versiculoNumero;

  /// Nombre del libro (cacheado para evitar lookup en cada emit).
  final String libroNombre;

  /// Abreviatura del libro (cacheada para evitar lookup en cada emit).
  final String libroAbreviatura;

  /// Abreviatura de la versión (cacheada).
  final String versionAbreviatura;

  /// Modo de vista actual del emisor.
  final EmitterViewMode viewMode;

  const _BibleDisplayState({
    required this.versionId,
    required this.libroNumero,
    required this.capitulo,
    required this.versiculoNumero,
    this.libroNombre = '',
    this.libroAbreviatura = '',
    this.versionAbreviatura = '',
    this.viewMode = EmitterViewMode.VIEW_MODE_COMPACT,
  });

  /// Estado inicial: Génesis 1:1 (RV1909 = versionId 1) en modo Compact.
  factory _BibleDisplayState.initial() => const _BibleDisplayState(
        versionId: 1,
        libroNumero: 1,
        capitulo: 1,
        versiculoNumero: 1,
        libroNombre: 'Génesis',
        libroAbreviatura: 'Gn',
        versionAbreviatura: 'RVR1909',
        viewMode: EmitterViewMode.VIEW_MODE_COMPACT,
      );

  _BibleDisplayState copyWith({
    int? versionId,
    int? libroNumero,
    int? capitulo,
    int? versiculoNumero,
    String? libroNombre,
    String? libroAbreviatura,
    String? versionAbreviatura,
    EmitterViewMode? viewMode,
  }) {
    return _BibleDisplayState(
      versionId: versionId ?? this.versionId,
      libroNumero: libroNumero ?? this.libroNumero,
      capitulo: capitulo ?? this.capitulo,
      versiculoNumero: versiculoNumero ?? this.versiculoNumero,
      libroNombre: libroNombre ?? this.libroNombre,
      libroAbreviatura: libroAbreviatura ?? this.libroAbreviatura,
      versionAbreviatura: versionAbreviatura ?? this.versionAbreviatura,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}
