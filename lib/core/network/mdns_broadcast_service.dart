import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:nsd/nsd.dart';

/// Servicio de broadcast mDNS vía `nsd`.
///
/// Publica un servicio `_himnario._tcp` en la red local para que
/// otros dispositivos puedan descubrirlo.
///
/// NOTA: `nsd` NO soporta Linux. En Linux el broadcast se omite
/// y se muestra un log informativo.
class MdnsBroadcastService {
  final _log = Logger('MdnsBroadcastService');
  Registration? _registration;

  /// Inicia la publicación del servicio.
  ///
  /// [name] es el nombre visible del dispositivo.
  /// [port] es el puerto donde corre el servidor gRPC.
  /// [sessionId] es el ID único de sesión.
  /// [displayName] es el nombre del display configurado.
  Future<void> start({
    required String name,
    required int port,
    required String sessionId,
    required String displayName,
  }) async {
    if (_registration != null) {
      _log.warning('El servicio mDNS ya está registrado.');
      return;
    }

    try {
      final service = Service(
        name: name,
        type: '_himnario._tcp',
        port: port,
        txt: {
          'sessionId': Uint8List.fromList(utf8.encode(sessionId)),
          'displayName': Uint8List.fromList(utf8.encode(displayName)),
        },
      );

      _registration = await register(service);

      _log.info(
        'mDNS iniciado exitosamente: ${_registration!.service.name} '
        '(_himnario._tcp) en puerto $port',
      );
    } catch (e) {
      _log.severe('Error crítico iniciando mDNS con nsd: $e');
      rethrow;
    }
  }

  /// Detiene la publicación del servicio.
  Future<void> stop() async {
    if (_registration != null) {
      try {
        await unregister(_registration!);
        _registration = null;
        _log.info('mDNS detenido y desregistrado correctamente.');
      } catch (e) {
        _log.severe('Error al detener el servicio mDNS: $e');
      }
    }
  }
}
