import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/network/nsd_discovery_service.dart';
import '../../../core/network/connection_state.dart';
import '../../../core/network/domain/discovered_display.dart';
import '../../../data/datasources/remote/grpc_control_datasource.dart';
import '../../../data/repositories/control_repository_impl.dart';
import '../../../domain/repositories/control_repository.dart' as domain;

final _log = Logger('ConnectionProviders');

/// Provider del datasource de control remoto.
final controlDataSourceProvider = Provider<GrpcControlDataSource>((ref) {
  return GrpcControlDataSource();
});

/// Provider del repositorio de control remoto.
final controlRepositoryProvider = Provider<domain.ControlRepository>((ref) {
  final dataSource = ref.read(controlDataSourceProvider);
  return ControlRepositoryImpl(dataSource: dataSource);
});

/// Provider que obtiene la lista de fondos disponibles en el display remoto.
final remoteBackgroundsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final connectionState = ref.watch(connectionStateProvider);
  if (connectionState is! Connected) return [];
  final dataSource = ref.watch(controlDataSourceProvider);
  return dataSource.getAvailableBackgrounds();
});

/// Provider del estado de conexión usando [ConnectionNotifier].
final connectionStateProvider =
    StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  return ConnectionNotifier(ref.read(controlDataSourceProvider), ref);
});

/// Provider con la información del dispositivo conectado.
final connectedDeviceProvider = Provider<DeviceInfo?>((ref) {
  final state = ref.watch(connectionStateProvider);
  if (state is Connected) {
    return state.device;
  }
  return null;
});

/// Provider del rol de conexión (Emisor/Receptor).
final connectionRoleProvider =
    StateProvider<ConnectionRole>((ref) => ConnectionRole.none);

/// Provider de solo lectura para verificar si hay conexión activa.
final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectionStateProvider) is Connected;
});

/// Notifier que maneja la conexión con un display remoto.
///
/// Expone [connectToDevice] y [disconnect] para ser usados desde la UI.
/// Incluye heartbeat periódico y reconexión automática con backoff exponencial.
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  static final _log = Logger('ConnectionNotifier');

  // ── Constantes ────────────────────────────────────────────────
  static final _heartbeatInterval = Duration(seconds: 15);
  static const _maxFailedPings = 3;
  static const _maxReconnectAttempts = 5;
  static const _backoffDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
  ];

  // ── Dependencias ──────────────────────────────────────────────
  final GrpcControlDataSource _dataSource;
  final Ref _ref;

  // ── Estado interno ────────────────────────────────────────────
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DeviceInfo? _lastConnectedDevice;
  int _reconnectAttempts = 0;
  int _failedPings = 0;
  StreamSubscription<domain.DisplayStatus>? _statusSubscription;

  ConnectionNotifier(this._dataSource, this._ref) : super(const Disconnected());

  /// Intenta conectar con un dispositivo remoto.
  /// Retorna `true` si la conexión fue exitosa.
  Future<bool> connectToDevice(DeviceInfo device) async {
    state = const Connecting();
    _log.info('Conectando a ${device.ip}:${device.port}...');

    try {
      await _dataSource.connect(device.ip, device.port);
      _lastConnectedDevice = device;
      _resetCounters();
      state = Connected(device);
      _startHeartbeat();
      _log.info('Conexión exitosa a ${device.name}');
      return true;
    } on NetworkException catch (e) {
      state = ConnectionError(e.message);
      _log.severe('Error de conexión: ${e.message}');
      return false;
    } catch (e) {
      state = ConnectionError('Error inesperado: $e');
      _log.severe('Error inesperado al conectar: $e');
      return false;
    }
  }

  /// Desconecta del dispositivo actual y resetea el rol a [ConnectionRole.none].
  Future<void> disconnect() async {
    _cancelHeartbeat();
    _cancelReconnect();
    _cancelStatusSubscription();
    await _dataSource.disconnect();
    _resetCounters();
    _lastConnectedDevice = null;
    state = const Disconnected();
    _ref.read(connectionRoleProvider.notifier).state = ConnectionRole.none;
    _log.info('Desconectado. Rol reseteado a none.');
  }

  // ── Heartbeat ─────────────────────────────────────────────────

  /// Inicia el timer periódico que envía pings para mantener la conexión viva.
  void _startHeartbeat() {
    _cancelHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _sendPing());
    _log.fine('Heartbeat iniciado (intervalo: $_heartbeatInterval)');
  }

  /// Cancela el timer de heartbeat.
  void _cancelHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Envía un ping al servidor y contabiliza los fallos.
  Future<void> _sendPing() async {
    try {
      await _dataSource.sendPing();
      _failedPings = 0;
    } catch (e) {
      _failedPings++;
      _log.warning(
        'Ping fallido ($_failedPings/$_maxFailedPings): $e',
      );
      if (_failedPings >= _maxFailedPings) {
        _onConnectionLost();
      }
    }
  }

  // ── Reconexión ────────────────────────────────────────────────

  /// Se invoca cuando se pierde la conexión.
  void _onConnectionLost() {
    _log.warning('Conexión perdida. Iniciando reconexión...');
    _cancelHeartbeat();
    _cancelStatusSubscription();
    state = const Disconnected();
    _scheduleReconnect();
  }

  /// Programa un reintento de conexión con backoff exponencial.
  void _scheduleReconnect() {
    _cancelReconnect();

    if (_reconnectAttempts >= _maxReconnectAttempts || _lastConnectedDevice == null) {
      _log.severe(
        'Reconexión fallida tras $_reconnectAttempts intentos.',
      );
      state = ConnectionError(
        'No se pudo reconectar tras $_reconnectAttempts intentos',
      );
      return;
    }

    final delay = _backoffDelays[_reconnectAttempts];
    _log.info(
      'Reintento $_reconnectAttempts en ${delay.inSeconds}s...',
    );

    _reconnectTimer = Timer(delay, () => _tryReconnect());
  }

  /// Intenta reconectar con el último dispositivo conocido.
  Future<void> _tryReconnect() async {
    final device = _lastConnectedDevice;
    if (device == null) return;

    state = const Connecting();
    try {
      await _dataSource.connect(device.ip, device.port);
      _resetCounters();
      state = Connected(device);
      _startHeartbeat();
      _log.info('Reconexión exitosa a ${device.name}');
    } catch (e) {
      _reconnectAttempts++;
      _log.warning(
        'Intento $_reconnectAttempts fallido: $e',
      );
      _scheduleReconnect();
    }
  }

  /// Cancela el timer de reconexión.
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ── Utilidades ────────────────────────────────────────────────

  /// Resetea los contadores de pings fallidos e intentos de reconexión.
  void _resetCounters() {
    _failedPings = 0;
    _reconnectAttempts = 0;
  }

  /// Cancela la suscripción al stream de estado si existe.
  void _cancelStatusSubscription() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
  }

  @override
  void dispose() {
    _cancelHeartbeat();
    _cancelReconnect();
    _cancelStatusSubscription();
    super.dispose();
  }
}

/// Provider que emite el estado del display en tiempo real mientras
/// haya una conexión activa. Retorna `null` cuando no hay conexión.
final liveDisplayStatusProvider = StreamProvider<domain.DisplayStatus?>((ref) {
  final connectionState = ref.watch(connectionStateProvider);
  final dataSource = ref.watch(controlDataSourceProvider);
  if (connectionState is! Connected) return Stream.value(null);
  return dataSource.watchStatus().map((status) => status);
});

/// Provider de la instancia única de [NsdDiscoveryService].
final nsdDiscoveryServiceProvider = Provider<NsdDiscoveryService>((ref) {
  final service = NsdDiscoveryService();
  ref.onDispose(() {
    service.stop();
    service.dispose();
  });
  return service;
});

/// Provider que escanea la LAN en busca de displays vía nsd.
///
/// Escucha [NsdDiscoveryService.onServiceChanged] durante 5 segundos y
/// retorna la lista de displays descubiertos.
final displayScannerProvider =
    FutureProvider.autoDispose<List<DiscoveredDisplay>>((ref) async {
  final nsdService = ref.watch(nsdDiscoveryServiceProvider);
  await nsdService.start();
  _log.info('Escaneando displays nsd...');

  final results = <DiscoveredDisplay>[];
  final sub = nsdService.onServiceChanged.listen((event) {
    _log.info(
      'Evento nsd: ${event.name} en ${event.ip}:${event.port} '
      '(isNew=${event.isNew}, isRemoved=${event.isRemoved})',
    );
    if (event.isRemoved) {
      results.removeWhere((d) => d.name == event.name);
    } else {
      results.add(
        DiscoveredDisplay(
          name: event.name,
          host: event.ip,
          port: event.port,
          sessionId: event.attributes['sessionId'] ?? '',
        ),
      );
    }
  });

  // Esperar 5 segundos para recopilar servicios (más tiempo para resolver)
  await Future.delayed(const Duration(seconds: 5));
  await sub.cancel();

  _log.info('Escaneo completado: ${results.length} displays encontrados');
  return results.toList();
});
