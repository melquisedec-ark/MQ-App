import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio para gestionar permisos de red necesarios para mDNS/nsd.
///
/// `nsd` usa NsdManager en Android, que requiere `INTERNET` y
/// `CHANGE_WIFI_MULTICAST_STATE` (declarados en AndroidManifest.xml).
/// En Android 13+, `NEARBY_WIFI_DEVICES` puede ser necesario como
/// permiso normal (auto-concedido si se declara en el manifiesto).
class PermissionService {
  static final _log = Logger('PermissionService');

  /// Solicita el permiso [Permission.nearbyWifiDevices] en Android 13+.
  ///
  /// Retorna `true` si el permiso está concedido o no es necesario.
  /// En plataformas que no son Android, retorna `true` inmediatamente.
  static Future<bool> requestNearbyWifiPermission() async {
    if (kIsWeb) return true;
    try {
      if (!Platform.isAndroid) return true;
    } catch (_) {
      return true; // Platform no disponible
    }

    final status = await Permission.nearbyWifiDevices.status;
    if (status.isGranted) return true;

    _log.info('Solicitando permiso NEARBY_WIFI_DEVICES...');
    final result = await Permission.nearbyWifiDevices.request();

    if (result.isGranted) {
      _log.info('Permiso NEARBY_WIFI_DEVICES concedido.');
      return true;
    }

    _log.warning(
      'Permiso NEARBY_WIFI_DEVICES denegado (${result.name}). '
      'El descubrimiento mDNS podría no funcionar en Android 13+.',
    );
    return false;
  }
}
