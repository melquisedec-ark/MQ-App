import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:nsd/nsd.dart';

import 'domain/bonsoir_discovered_service.dart';

/// Servicio de descubrimiento mDNS vía `nsd`.
///
/// Escanea servicios `_himnario._tcp` en la red local y emite
/// [BonsoirDiscoveredService] cada vez que un servicio es descubierto
/// o eliminado.
///
/// NOTA: `nsd` NO soporta Linux. En Linux el discovery no está disponible.
class NsdDiscoveryService {
  final _log = Logger('NsdDiscoveryService');
  Discovery? _discovery;
  final _serviceController = StreamController<BonsoirDiscoveredService>.broadcast();

  /// Stream de servicios descubiertos/eliminados.
  Stream<BonsoirDiscoveredService> get onServiceChanged => _serviceController.stream;

  /// Inicia el escaneo de servicios mDNS.
  Future<void> start() async {
    if (_discovery != null) return;
    try {
      _discovery = await startDiscovery(
        '_himnario._tcp',
        ipLookupType: IpLookupType.any,
      );

      _discovery!.addServiceListener((service, status) {
        switch (status) {
          case ServiceStatus.found:
            _log.info('Servicio encontrado: ${service.name}');
            final ip = service.addresses?.isNotEmpty == true
                ? service.addresses!.first.address
                : service.host ?? '0.0.0.0';
            _serviceController.add(
              BonsoirDiscoveredService(
                name: service.name ?? 'Unknown',
                ip: ip,
                port: service.port ?? 0,
                attributes: _decodeTxtMap(service.txt),
                isNew: true,
                isRemoved: false,
              ),
            );
            break;
          case ServiceStatus.lost:
            _log.info('Servicio perdido: ${service.name}');
            final ip = service.addresses?.isNotEmpty == true
                ? service.addresses!.first.address
                : service.host ?? '0.0.0.0';
            _serviceController.add(
              BonsoirDiscoveredService(
                name: service.name ?? 'Unknown',
                ip: ip,
                port: service.port ?? 0,
                attributes: _decodeTxtMap(service.txt),
                isNew: false,
                isRemoved: true,
              ),
            );
            break;
        }
      });

      _log.info('NsdDiscovery iniciado para _himnario._tcp');
    } catch (e) {
      _log.severe('Error iniciando NsdDiscovery: $e');
      rethrow;
    }
  }

  /// Decodifica el mapa TXT de bytes a String.
  Map<String, String> _decodeTxtMap(Map<String, Uint8List?>? txt) {
    if (txt == null) return {};
    return txt.map((key, value) =>
        MapEntry(key, value != null ? utf8.decode(value) : ''),);
  }

  /// Detiene el escaneo de servicios.
  Future<void> stop() async {
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
      _log.info('NsdDiscovery detenido');
    }
  }

  /// Libera recursos.
  void dispose() {
    _serviceController.close();
  }
}
