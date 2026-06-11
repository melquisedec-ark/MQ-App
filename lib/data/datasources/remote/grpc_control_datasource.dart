import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:logging/logging.dart';

import '../../../core/errors/exceptions.dart';
import '../../../domain/repositories/control_repository.dart' as domain;
import '../../../proto/generated/hymn_control.pbgrpc.dart';

/// DataSource remoto para control del display vía gRPC.
///
/// Encapsula toda la comunicación con el servicio HymnControl del display.
/// Usa los stubs generados a partir del archivo .proto.
class GrpcControlDataSource {
  static final _log = Logger('GrpcControlDataSource');

  HymnControlClient? _client;
  ClientChannel? _channel;
  String? _connectedHost;
  int? _connectedPort;

  /// Dirección IP del host actualmente conectado, o null si no hay conexión.
  String? get connectedHost => _connectedHost;

  /// Puerto del host actualmente conectado, o null si no hay conexión.
  int? get connectedPort => _connectedPort;

  /// Indica si hay una conexión activa.
  bool get isConnected => _client != null;

  /// Establece conexión gRPC con un display remoto.
  Future<void> connect(String host, int port) async {
    try {
      // Cerrar conexión previa si existe
      await disconnect();

      _channel = ClientChannel(
        host,
        port: port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
          keepAlive: ClientKeepAliveOptions(
            pingInterval: Duration(seconds: 30),
            timeout: Duration(seconds: 10),
            permitWithoutCalls: true,
          ),
          connectTimeout: Duration(seconds: 10),
        ),
      );

      final client = HymnControlClient(_channel!);

      // Realizar handshake para verificar conexión
      final response = await client
          .handshake(
            HandshakeRequest(
              clientName: 'MQ App Controller',
              clientVersion: '2.0.0',
              protocolVersion: 1,
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (!response.accepted) {
        await disconnect();
        throw const NetworkException(
          'Handshake rechazado por el display',
          statusCode: -1,
        );
      }

      _client = client;
      _connectedHost = host;
      _connectedPort = port;

      _log.info(
        'Conectado a display: ${response.displayName} '
        '(${response.serverName} v${response.serverVersion})',
      );
    } on NetworkException {
      rethrow;
    } on GrpcError catch (e) {
      _log.severe('Error gRPC al conectar: $e');
      await disconnect();
      throw NetworkException(
        'Error de conexión gRPC: ${e.message}',
        statusCode: e.code,
      );
    } on TimeoutException {
      _log.severe('Timeout al conectar con $host:$port');
      await disconnect();
      throw const NetworkException(
        'Timeout de conexión: el display no respondió',
        statusCode: -1,
      );
    } catch (e) {
      _log.severe('Error inesperado al conectar: $e');
      await disconnect();
      throw NetworkException('Error al conectar: $e');
    }
  }

  /// Cierra la conexión actual.
  Future<void> disconnect() async {
    _client = null;
    await _channel?.shutdown();
    _channel = null;
    _connectedHost = null;
    _connectedPort = null;
    _log.info('Desconectado del display.');
  }

  /// Envía un comando genérico al display.
  Future<CommandResponse> _sendCommand(CommandRequest request) async {
    _ensureConnected();

    try {
      final response = await _client!.sendCommand(request);
      if (!response.success) {
        _log.warning('Comando rechazado: ${response.errorMessage}');
      }
      return response;
    } on GrpcError catch (e) {
      _log.severe('Error gRPC al enviar comando: $e');
      throw NetworkException(
        'Error al enviar comando: ${e.message}',
        statusCode: e.code,
      );
    }
  }

  /// Envía comando para mostrar un himno específico.
  Future<bool> sendShowHimno(int himnoId) async {
    final response = await _sendCommand(
      CommandRequest(
        type: CommandType.JUMP_TO_HYMN,
        hymnId: himnoId,
      ),
    );
    return response.success;
  }

  /// Envía comando para avanzar a la siguiente estrofa.
  Future<bool> sendNextStanza() async {
    final response = await _sendCommand(
      CommandRequest(type: CommandType.NEXT_STANZA),
    );
    return response.success;
  }

  /// Envía comando para retroceder a la estrofa anterior.
  Future<bool> sendPrevStanza() async {
    final response = await _sendCommand(
      CommandRequest(type: CommandType.PREV_STANZA),
    );
    return response.success;
  }

  /// Envía comando para ir a una estrofa específica.
  Future<bool> sendGoToStanza(int index) async {
    final response = await _sendCommand(
      CommandRequest(
        type: CommandType.GO_TO_STANZA,
        stanzaIndex: index,
      ),
    );
    return response.success;
  }

  /// Envía comando para activar/desactivar blackout.
  Future<bool> sendBlackout(bool active) async {
    final response = await _sendCommand(
      CommandRequest(
        type: active ? CommandType.BLACKOUT : CommandType.CLEAR_BLACKOUT,
      ),
    );
    return response.success;
  }

  /// Envía comando para cambiar transposición.
  Future<bool> sendTransposition(int semitones) async {
    final response = await _sendCommand(
      CommandRequest(
        type: CommandType.SET_TRANSPOSITION,
        semitones: semitones,
      ),
    );
    return response.success;
  }

  /// Envía comando para cambiar fondo.
  Future<bool> sendSetBackground(String backgroundId) async {
    final response = await _sendCommand(
      CommandRequest(
        type: CommandType.SET_BACKGROUND,
        backgroundId: backgroundId,
      ),
    );
    return response.success;
  }

  /// Envía comando para cambiar tamaño de fuente.
  Future<bool> sendSetFontSize(double fontSize) async {
    final response = await _sendCommand(
      CommandRequest(
        type: CommandType.SET_FONT_SIZE,
        fontSize: fontSize,
      ),
    );
    return response.success;
  }

  /// Envía configuración de apariencia (texto, acordes, fuente) al display remoto.
  Future<bool> sendSetAppearance({
    String? textColor,
    String? chordColor,
    String? fontFamily,
    bool? isBold,
    bool? showChords,
    double? cardOpacity,
    double? projectionFontScale,
  }) async {
    _ensureConnected();
    try {
      final request = CommandRequest(type: CommandType.SET_APPEARANCE);
      if (textColor != null) request.textColor = textColor;
      if (chordColor != null) request.chordColor = chordColor;
      if (fontFamily != null) request.fontFamily = fontFamily;
      if (isBold != null) request.isBold = isBold;
      if (showChords != null) request.showChords = showChords;
      if (cardOpacity != null) request.cardOpacity = cardOpacity;
      if (projectionFontScale != null) request.projectionFontScale = projectionFontScale;
      final response = await _client!.sendCommand(request);
      return response.success;
    } on GrpcError catch (e) {
      _log.severe('Error gRPC en sendSetAppearance: $e');
      throw NetworkException('Error al enviar apariencia: ${e.message}', statusCode: e.code);
    }
  }

  /// Envía el contenido completo de un himno al display remoto.
  Future<bool> sendHymnContent({
    required int hymnId,
    required String titulo,
    int? numero,
    required String tipo,
    required int versionPaisId,
    required List<Map<String, dynamic>> estrofas,
  }) async {
    _ensureConnected();

    try {
      final payload = HymnPayload(
        hymnId: hymnId,
        titulo: titulo,
        tipo: tipo,
        versionPaisId: versionPaisId,
      );
      if (numero != null) payload.numero = numero;
      payload.estrofas.addAll(
        estrofas.map((e) => StanzaPayload(
          id: e['id'] as int,
          versionPaisId: e['version_pais_id'] as int,
          tipo: e['tipo'] as String,
          orden: e['orden'] as int,
          contenido: e['contenido'] as String,
        ),),
      );

      final response = await _client!.sendHymnContent(payload);
      return response.success;
    } on GrpcError catch (e) {
      _log.severe('Error gRPC en sendHymnContent: $e');
      throw NetworkException(
        'Error al enviar himno: ${e.message}',
        statusCode: e.code,
      );
    }
  }

  /// Obtiene la lista de fondos disponibles en el display remoto.
  Future<List<Map<String, dynamic>>> getAvailableBackgrounds() async {
    _ensureConnected();

    try {
      final response = await _client!.getAvailableBackgrounds(Empty());
      return response.backgrounds.map((bg) => {
        'id': bg.id,
        'nombre': bg.nombre,
        'tipo': bg.tipo,
      },).toList();
    } on GrpcError catch (e) {
      _log.severe('Error gRPC en getAvailableBackgrounds: $e');
      throw NetworkException(
        'Error al obtener fondos: ${e.message}',
        statusCode: e.code,
      );
    }
  }

  /// Obtiene el estado actual del display.
  Future<domain.DisplayStatus> getStatus() async {
    _ensureConnected();

    try {
      final status = await _client!.getStatus(Empty());
      return domain.DisplayStatus(
        currentHymnId: status.currentHymnId,
        currentHymnTitle: status.currentHymnTitle,
        currentStanzaIndex: status.currentStanzaIndex,
        totalStanzas: status.totalStanzas,
        transpositionSemitones: status.transpositionSemitones,
        isBlackout: status.isBlackout,
        currentBackgroundId: status.currentBackgroundId,
        fontSize: status.fontSize,
        displayName: status.displayName,
      );
    } on GrpcError catch (e) {
      _log.severe('Error gRPC al obtener estado: $e');
      throw NetworkException(
        'Error al obtener estado: ${e.message}',
        statusCode: e.code,
      );
    }
  }

  /// Stream de estado del display en tiempo real.
  ///
  /// Detecta cierres silenciosos del stream emitiendo un error para que
  /// quien lo escuche pueda reconectar.
  Stream<domain.DisplayStatus> watchStatus() {
    _ensureConnected();

    try {
      final stream = _client!.watchStatus(Empty());

      return stream
          .map(
            (status) => domain.DisplayStatus(
              currentHymnId: status.currentHymnId,
              currentHymnTitle: status.currentHymnTitle,
              currentStanzaIndex: status.currentStanzaIndex,
              totalStanzas: status.totalStanzas,
              transpositionSemitones: status.transpositionSemitones,
              isBlackout: status.isBlackout,
              currentBackgroundId: status.currentBackgroundId,
              fontSize: status.fontSize,
              displayName: status.displayName,
            ),
          )
          .transform(
            StreamTransformer.fromHandlers(
              handleData: (data, sink) => sink.add(data),
              handleError: (error, stack, sink) {
                _log.warning('Error en stream de estado: $error');
                sink.addError(
                  NetworkException(
                    'Stream de estado interrumpido: $error',
                  ),
                  stack,
                );
              },
              handleDone: (sink) {
                _log.warning('Stream de estado cerrado por el servidor');
                sink.addError(
                  const NetworkException(
                    'Stream de estado cerrado por el servidor',
                  ),
                );
              },
            ),
          );
    } on GrpcError catch (e) {
      _log.severe('Error gRPC en watchStatus: $e');
      throw NetworkException(
        'Error al iniciar stream de estado: ${e.message}',
        statusCode: e.code,
      );
    }
  }

  /// Envía un comando PING al servidor para mantener la conexión viva.
  Future<void> sendPing() async {
    await _sendCommand(CommandRequest(type: CommandType.PING));
  }

  // ───────────────────────────────────────────────────────────────
  // BIBLE MODULE COMMANDS (Phase 2a.3)
  // ───────────────────────────────────────────────────────────────
  // Wrappers tipados sobre `_sendCommand` para los 9 comandos nuevos.
  // Siguen el mismo patrón que `sendNextStanza` / `sendShowHimno`.

  /// Avanza al versículo siguiente en el display.
  Future<bool> sendNextVerse() async {
    final r = await _sendCommand(CommandRequest(type: CommandType.NEXT_VERSE));
    return r.success;
  }

  /// Retrocede al versículo anterior en el display.
  Future<bool> sendPrevVerse() async {
    final r = await _sendCommand(CommandRequest(type: CommandType.PREV_VERSE));
    return r.success;
  }

  /// Avanza al siguiente capítulo en el display.
  Future<bool> sendNextChapter() async {
    final r = await _sendCommand(CommandRequest(type: CommandType.NEXT_CHAPTER));
    return r.success;
  }

  /// Retrocede al capítulo anterior en el display.
  Future<bool> sendPrevChapter() async {
    final r = await _sendCommand(CommandRequest(type: CommandType.PREV_CHAPTER));
    return r.success;
  }

  /// Salta a un versículo específico identificado por referencia canónica.
  ///
  /// [versionId] 1 = RV1909, 2 = RV1569.
  /// [libroNumero] sigue orden canónico (1..66): 1=Génesis, 43=Juan, etc.
  Future<bool> sendGoToVerse({
    required int versionId,
    required int libroNumero,
    required int capitulo,
    required int versiculo,
  }) async {
    final ref = VerseReference()
      ..versionId = versionId
      ..libroNumero = libroNumero
      ..capitulo = capitulo
      ..versiculo = versiculo;
    final req = CommandRequest(type: CommandType.GO_TO_VERSE)
      ..targetVerse = ref;
    final r = await _sendCommand(req);
    return r.success;
  }

  /// Alterna el estado de favorito del versículo actual en el display.
  Future<bool> sendToggleFavorite() async {
    final r = await _sendCommand(CommandRequest(type: CommandType.TOGGLE_FAVORITE));
    return r.success;
  }

  /// Solicita al display que cambie al módulo Biblia.
  Future<bool> sendSwitchToBible() async {
    final req = CommandRequest(type: CommandType.SWITCH_TO_BIBLE)
      ..targetModule = ModuleType.MODULE_BIBLIA;
    final r = await _sendCommand(req);
    return r.success;
  }

  /// Solicita al display que vuelva al módulo Himnario.
  Future<bool> sendSwitchToHymnal() async {
    final req = CommandRequest(type: CommandType.SWITCH_TO_HIMNAL)
      ..targetModule = ModuleType.MODULE_HIMNARIO;
    final r = await _sendCommand(req);
    return r.success;
  }

  /// Cambia el modo de vista del emisor (COMPACT/PREVIEW) en el display.
  ///
  /// NOTA: el `viewMode` es una preferencia del cliente, pero igual se
  /// notifica al display para que registre el cambio y pueda sincronizar
  /// con múltiples clientes en el futuro.
  Future<bool> sendSetEmitterViewMode(EmitterViewMode mode) async {
    final req = CommandRequest(type: CommandType.SET_EMITTER_VIEW_MODE)
      ..viewMode = mode;
    final r = await _sendCommand(req);
    return r.success;
  }

  /// Verifica que el cliente esté conectado.
  void _ensureConnected() {
    if (_client == null) {
      throw const NetworkException('No hay conexión activa con el display');
    }
  }
}
