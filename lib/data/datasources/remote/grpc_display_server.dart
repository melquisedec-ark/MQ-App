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
import '../../../presentation/shared_widgets/providers/appearance_provider.dart';
import '../../../presentation/views_projection/providers/live_control_providers.dart';
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
}
