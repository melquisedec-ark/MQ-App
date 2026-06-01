import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show TargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../core/database/database_helper.dart';
import '../core/network/mdns_broadcast_service.dart';
import '../core/network/nsd_discovery_service.dart';
import '../core/network/mdns_discovery.dart';
import '../data/datasources/remote/grpc_display_server.dart';
import '../domain/entities/estrofa.dart';
import '../domain/entities/himno.dart';
import '../presentation/views_personal/providers/hymn_providers.dart';
import '../presentation/views_projection/display/receptor_binding.dart';
import '../presentation/views_projection/providers/live_control_providers.dart';

/// Inicializador de la aplicación.
/// Se encarga de configurar todos los servicios antes de que Flutter renderice.
class AppInitializer {
  static final _log = Logger('AppInitializer');

  static GrpcDisplayServer? _displayServer;
  static MdnsDiscovery? _mdnsDiscovery;
  static MdnsBroadcastService? _mdnsBroadcast;
  static NsdDiscoveryService? _nsdDiscoveryService;

  /// El servidor gRPC en ejecución (solo en modo Display).
  static GrpcDisplayServer? get displayServer => _displayServer;

  /// El servicio de descubrimiento mDNS (solo en modo Controlador).
  static MdnsDiscovery? get mdnsDiscovery => _mdnsDiscovery;

  /// Inicializa todos los servicios necesarios para la app.
  /// Debe llamarse antes de runApp().
  ///
  /// [skipNetwork] evita iniciar el servidor gRPC y mDNS. Útil para el
  /// subproceso de proyección (`--projection`) que se comunica vía stdin/stdout.
  static Future<void> initialize({
    ProviderContainer? container,
    bool skipNetwork = false,
  }) async {
    _log.info('Inicializando HimnarioID 2.0...');

    // 1. Configurar logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // En producción, enviar a un archivo o servicio externo
      // ignore: avoid_print
      print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    });

    // 2. Inicializar base de datos SQLite
    await _initDatabase();

    // 3. Configurar detección de plataforma
    await _initPlatform();

    // 4. Inicializar servicios de red (mDNS/gRPC) — se salta en subproceso
    if (!skipNetwork) {
      await _initNetworkServices(container);
    }

    // 5. Iniciar descubrimiento nsd (solo plataformas soportadas)
    if (!skipNetwork) {
      await _initNsdDiscovery();
    }

    _log.info('Inicialización completada.');
  }

  static Future<void> _initDatabase() async {
    try {
      final db = await DatabaseHelper.instance.database;
      _log.info('Base de datos inicializada correctamente: ${db.path}');
    } catch (e) {
      _log.severe('Error al inicializar la base de datos: $e');
      rethrow;
    }
  }

  static TargetPlatform? _platform;

  /// Plataforma detectada (web, android, ios, linux, macos, windows).
  static TargetPlatform? get platform => _platform;

  static Future<void> _initPlatform() async {
    // `dart:io` (Platform) está protegido contra web con try/catch.
    // En web las llamadas a Platform lanzan UnsupportedError en tiempo de
    // ejecución, pero el import compila correctamente.
    try {
      if (kIsWeb) {
        _log.info('Plataforma: Web (sin equivalente en TargetPlatform)');
        return;
      }
      if (Platform.isAndroid) {
        _platform = TargetPlatform.android;
      } else if (Platform.isIOS) {
        _platform = TargetPlatform.iOS;
      } else if (Platform.isLinux) {
        _platform = TargetPlatform.linux;
      } else if (Platform.isMacOS) {
        _platform = TargetPlatform.macOS;
      } else if (Platform.isWindows) {
        _platform = TargetPlatform.windows;
      }
      _log.info('Plataforma: $_platform');
    } on UnsupportedError catch (e) {
      _log.info('Platform no disponible en este entorno: $e');
      _platform = null;
    }
  }

  /// Inicializa servicios de red.
  ///
  /// - En plataformas desktop (Linux/macOS/Windows): inicia el servidor gRPC
  ///   para que el display reciba comandos de control remoto.
  /// - En otras plataformas: inicia el descubrimiento mDNS para encontrar
  ///   displays disponibles en la LAN.
  static Future<void> _initNetworkServices([
    ProviderContainer? container,
  ]) async {
    if (_platform == TargetPlatform.linux ||
        _platform == TargetPlatform.macOS ||
        _platform == TargetPlatform.windows) {
      await _initDisplayServer(container);
    } else {
      await _initControllerDiscovery(container);
    }
  }

  /// Inicia el servidor gRPC para modo Display.
  static Future<void> _initDisplayServer([ProviderContainer? container]) async {
    // 1. Iniciar servidor gRPC
    try {
      _displayServer = GrpcDisplayServer(
        displayName: 'Display Principal',
        port: GrpcDisplayServer.defaultPort,
        container: container,
      );

      // Configurar callbacks si tenemos acceso al ProviderContainer
      if (container != null) {
        final effectiveContainer = container;

        _displayServer!.onCommand = (
          LiveControlState Function(
            LiveControlState,
          ) update,
        ) {
          final state = effectiveContainer.read(liveControlProvider);
          final newState = update(state);
          if (newState != state) {
            effectiveContainer
                .read(liveControlProvider.notifier)
                .updateFromServer(newState);
          }
        };

        _displayServer!.onJumpToHymn = (int hymnId) async {
          try {
            final hymnRepo = effectiveContainer.read(hymnRepositoryProvider);
            final hymn = await hymnRepo.getHymnById(hymnId);
            final versionPaisId = hymn.primaryVersionPaisId;
            if (versionPaisId < 0) {
              _log.warning('Himno $hymnId no tiene versiones de país.');
              return;
            }
            final stanzas = await hymnRepo.getStanzas(versionPaisId);
            effectiveContainer
                .read(liveControlProvider.notifier)
                .loadHymn(hymn, stanzas, versionPaisId: versionPaisId);
            _log.info(
              'Himno $hymnId (versión $versionPaisId) cargado en proyección.',
            );
          } catch (e) {
            _log.severe('Error al cargar himno $hymnId: $e');
          }
        };

        _displayServer!.onClientConnected = (String clientName) {
          _log.info('Cliente conectado: $clientName');
          effectiveContainer
              .read(isClientConnectedProvider.notifier)
              .state = true;
        };

        _displayServer!.onLoadHymnContent = (
          Himno himno,
          List<Estrofa> estrofas,
        ) async {
          try {
            effectiveContainer
                .read(liveControlProvider.notifier)
                .loadHymn(himno, estrofas, versionPaisId: himno.primaryVersionPaisId);
            _log.info('Himno "${himno.titulo}" cargado desde controlador remoto.');
          } catch (e) {
            _log.severe('Error al cargar himno desde controlador remoto: $e');
          }
        };
      }

      await _displayServer!.start();
      _log.info('Servidor gRPC iniciado en puerto ${_displayServer!.port}');
    } catch (e) {
      _log.severe('Error al iniciar servidor gRPC: $e');
      // No relanzar — la app puede funcionar sin servidor gRPC
      return;
    }

    // 2. Iniciar broadcast mDNS vía nsd (solo Windows)
    if (_platform == TargetPlatform.windows) {
      try {
        _mdnsBroadcast = MdnsBroadcastService();
        await _mdnsBroadcast!.start(
          name: 'MQ App-${_displayServer!.displayName}',
          port: _displayServer!.port,
          sessionId: _displayServer!.sessionId,
          displayName: _displayServer!.displayName,
        );
        _log.info('Broadcast mDNS iniciado correctamente.');
      } catch (e) {
        _log.severe('Error al iniciar broadcast mDNS: $e');
        _log.warning(
          'El servidor gRPC está funcionando, pero el broadcast mDNS '
          'falló. Usa conexión manual con la IP de esta máquina.',
        );
      }
    } else if (_platform == TargetPlatform.linux) {
      _log.info(
        'mDNS broadcast no disponible en Linux. '
        'Usa conexión manual con la IP de esta máquina.',
      );
    }
  }

  /// Inicia el descubrimiento mDNS para modo Controlador.
  static Future<void> _initControllerDiscovery([
    ProviderContainer? container,
  ]) async {
    try {
      _mdnsDiscovery = MdnsDiscovery();

      // Escuchar dispositivos descubiertos
      _mdnsDiscovery!.onDeviceDiscovered.listen((device) {
        _log.info('Display descubierto: ${device.name} en ${device.ip}');
      });

      // Iniciar descubrimiento (no bloqueante)
      _mdnsDiscovery!.startDiscovery();
      _log.info('Descubrimiento mDNS iniciado.');
    } catch (e) {
      _log.severe('Error al iniciar mDNS: $e');
    }
  }

  /// Inicia el descubrimiento mDNS vía nsd (solo en móvil).
  static Future<void> _initNsdDiscovery() async {
    // Solo iniciar en móvil; en desktop el broadcast ya publica el servicio
    if (_platform == TargetPlatform.android || _platform == TargetPlatform.iOS) {
      try {
        _nsdDiscoveryService = NsdDiscoveryService();
        await _nsdDiscoveryService!.start();
        _log.info('Descubrimiento nsd iniciado.');
      } catch (e) {
        _log.severe('Error al iniciar NsdDiscoveryService: $e');
      }
    } else {
      _log.info('nsd discovery omitido en plataforma no soportada.');
    }
  }

  /// Detiene todos los servicios de red.
  static Future<void> dispose() async {
    await _displayServer?.stop();
    await _mdnsBroadcast?.stop();
    _mdnsBroadcast = null;
    await _nsdDiscoveryService?.stop();
    _nsdDiscoveryService = null;
    await _mdnsDiscovery?.stopDiscovery();
    _mdnsDiscovery?.dispose();
    _log.info('Servicios de red detenidos.');
  }

}
