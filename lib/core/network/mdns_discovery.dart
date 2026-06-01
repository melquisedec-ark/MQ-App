import 'dart:async';

import 'package:logging/logging.dart';

import 'nsd_discovery_service.dart';
import 'connection_state.dart';
import 'domain/bonsoir_discovered_service.dart';

/// Servicio de descubrimiento mDNS basado en [NsdDiscoveryService].
///
/// Mantiene la misma API pública que el `MdnsDiscovery` anterior, pero
/// ahora delega internamente en `nsd` para encontrar displays en la LAN.
class MdnsDiscovery {
  static final _log = Logger('MdnsDiscovery');

  final NsdDiscoveryService _nsdDiscoveryService = NsdDiscoveryService();
  StreamSubscription<BonsoirDiscoveredService>? _subscription;
  final StreamController<DeviceInfo> _deviceController =
      StreamController<DeviceInfo>.broadcast();

  bool _isRunning = false;

  /// Stream de dispositivos descubiertos en la red.
  Stream<DeviceInfo> get onDeviceDiscovered => _deviceController.stream;

  /// Indica si el descubrimiento está activo.
  bool get isRunning => _isRunning;

  /// Inicia el escaneo de dispositivos mDNS en la LAN.
  Future<void> startDiscovery() async {
    if (_isRunning) {
      _log.warning('El descubrimiento ya está en ejecución.');
      return;
    }

    _isRunning = true;

    try {
      _log.info('Iniciando descubrimiento mDNS (nsd)...');
      await _nsdDiscoveryService.start();

      _subscription = _nsdDiscoveryService.onServiceChanged.listen((event) {
        if (event.isRemoved) return;
        final device = DeviceInfo(
          name: event.name,
          ip: event.ip,
          port: event.port,
        );
        _log.info('Dispositivo descubierto: $device');
        _deviceController.add(device);
      });
    } catch (e) {
      _log.severe('Error en descubrimiento mDNS: $e');
      _isRunning = false;
      rethrow;
    }
  }

  /// Realiza un escaneo único y retorna la lista de dispositivos encontrados.
  Future<List<DeviceInfo>> discoverDevices() async {
    final devices = <DeviceInfo>[];
    final subscription = onDeviceDiscovered.listen((device) {
      devices.add(device);
    });

    await startDiscovery();

    // Dar tiempo para recoger resultados
    await Future.delayed(const Duration(seconds: 5));

    await subscription.cancel();
    await stopDiscovery();
    return devices;
  }

  /// Detiene el descubrimiento y libera recursos.
  Future<void> stopDiscovery() async {
    _isRunning = false;
    await _subscription?.cancel();
    _subscription = null;
    await _nsdDiscoveryService.stop();
    _log.info('Descubrimiento mDNS detenido.');
  }

  /// Libera todos los recursos.
  void dispose() {
    _deviceController.close();
    _nsdDiscoveryService.dispose();
  }
}
