import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connection_state.dart';
import '../../../../core/network/domain/discovered_display.dart';
import '../../../../core/network/permission_service.dart';
import '../../../../data/datasources/remote/grpc_display_server.dart';
import '../../../../domain/repositories/control_repository.dart' as domain;
import '../../display/receptor_binding.dart';
import '../../providers/connection_providers.dart';
import '../../providers/discovery_providers.dart';

/// BottomSheet modal para descubrir displays en la red vía mDNS,
/// conectar y controlar remotamente el display seleccionado.
///
/// ## Flujo
/// 1. Selección de rol (Emisor / Receptor)
/// 2. Escaneo automático con autorefresco cada 10s
/// 3. Conexión a un display
/// 4. Panel de control remoto (fondo, fuente, transposición)
///
/// Todos los widgets usan [colorScheme] / [textTheme] de Material 3.
class DiscoverDisplaySheet extends ConsumerStatefulWidget {
  const DiscoverDisplaySheet({super.key});

  @override
  ConsumerState<DiscoverDisplaySheet> createState() =>
      _DiscoverDisplaySheetState();
}

class _DiscoverDisplaySheetState extends ConsumerState<DiscoverDisplaySheet> {
  // ── D1.1: Timer de autorefresco ────────────────────────────────
  Timer? _refreshTimer;

  /// IP del dispositivo al que se está conectando actualmente.
  String? _connectingIp;

  /// Controlador para el campo de IP de conexión manual.
  final _manualIpController = TextEditingController();

  /// Controlador para el campo de puerto de conexión manual.
  final _manualPortController =
      TextEditingController(text: '${GrpcDisplayServer.defaultPort}');

  /// Si el permiso [Permission.nearbyWifiDevices] ya fue verificado.
  bool _permissionChecked = false;

  /// Si el permiso [Permission.nearbyWifiDevices] fue concedido.
  bool _nearbyPermissionGranted = false;

  /// Clave para el [AnimatedList] de dispositivos.
  final GlobalKey<AnimatedListState> _listKey =
      GlobalKey<AnimatedListState>();

  /// Lista actual de dispositivos mostrados (para diff con AnimatedList).
  List<DeviceInfo> _previousDevices = const [];

  /// Marca temporal del último escaneo completo para controlar el
  /// mensaje de "no encontrados" tras 10s sin resultados.
  DateTime? _lastScanCompleted;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
    _checkPermission();
  }

  /// Verifica y solicita el permiso [Permission.nearbyWifiDevices].
  ///
  /// Este permiso es necesario en Android 13+ para que nsd pueda
  /// descubrir dispositivos en la red local mediante mDNS/NSD.
  Future<void> _checkPermission() async {
    final granted = await PermissionService.requestNearbyWifiPermission();
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _nearbyPermissionGranted = granted;
    });
  }

  /// Inicia el timer que invalida [displayScannerProvider] cada 10s.
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      ref.invalidate(displayScannerProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _manualIpController.dispose();
    _manualPortController.dispose();
    super.dispose();
  }

  // ── Acciones ─────────────────────────────────────────────────

  Future<void> _connectToDevice(DeviceInfo device) async {
    setState(() {
      _connectingIp = device.ip;
    });
    final success = await ref
        .read(connectionStateProvider.notifier)
        .connectToDevice(device);
    if (!mounted) return;
    if (success) {
      setState(() => _connectingIp = null);
      // Auto-asignar rol emitter si no hay rol definido
      final currentRole = ref.read(connectionRoleProvider);
      if (currentRole == ConnectionRole.none) {
        ref.read(connectionRoleProvider.notifier).state = ConnectionRole.emitter;
      }
    }
  }

  Future<void> _disconnect() async {
    await ref.read(connectionStateProvider.notifier).disconnect();
    if (!mounted) return;
    setState(() => _connectingIp = null);
  }

  /// Intenta conectar a una IP ingresada manualmente.
  Future<void> _connectManual() async {
    final ip = _manualIpController.text.trim();
    final portStr = _manualPortController.text.trim();
    if (ip.isEmpty) return;

    final port = int.tryParse(portStr) ?? GrpcDisplayServer.defaultPort;

    final device = DeviceInfo(
      name: 'Manual: $ip',
      ip: ip,
      port: port,
      id: '',
    );

    final notifier = ref.read(connectionStateProvider.notifier);
    await notifier.connectToDevice(device);
  }

  void _selectEmitter() {
    ref.read(connectionRoleProvider.notifier).state = ConnectionRole.emitter;
  }

  void _selectReceiver() {
    final server = ref.read(grpcDisplayServerProvider);
    if (server == null || !server.isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Modo Receptor no disponible en esta plataforma. '
            'Usa un PC con Linux, macOS o Windows.',
          ),
        ),
      );
      return;
    }
    ref.read(connectionRoleProvider.notifier).state = ConnectionRole.receiver;
    if (context.mounted) Navigator.pop(context);
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final connectionState = ref.watch(connectionStateProvider);
    final isConnected = connectionState is Connected;
    final role = ref.watch(connectionRoleProvider);
    final showScanView = role == ConnectionRole.emitter || isConnected;

    return DraggableScrollableSheet(
      initialChildSize: showScanView ? 0.65 : 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(colorScheme),
              _buildHeader(colorScheme, textTheme, isConnected),
              const Divider(height: 1),
              // ── Banner de permiso (Android 13+) ──
              _buildPermissionBanner(colorScheme, textTheme),
              // ── D1.2: Indicador de carga ──
              _buildScannerLoadingIndicator(colorScheme),
              // Contenido principal
              Expanded(
                child: showScanView
                    ? _buildScanContent(
                        colorScheme,
                        textTheme,
                        connectionState,
                        scrollController,
                      )
                    : _buildRoleSelection(colorScheme, textTheme),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Handle ───────────────────────────────────────────────────

  Widget _buildHandle(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isConnected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isConnected ? 'Panel de Control' : 'Conectar Display',
              style: textTheme.titleLarge,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── D1.2: Indicador visual de carga/refresh ──────────────────

  Widget _buildScannerLoadingIndicator(ColorScheme colorScheme) {
    final scannerAsync = ref.watch(displayScannerProvider);
    return scannerAsync.isLoading
        ? LinearProgressIndicator(
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          )
        : const SizedBox.shrink();
  }

  // ── Banner de permiso NEARBY_WIFI_DEVICES ─────────────────────

  /// Muestra un banner si el permiso [Permission.nearbyWifiDevices]
  /// aún no ha sido concedido (Android 13+). Este permiso es necesario
  /// para que nsd pueda descubrir dispositivos en la LAN.
  Widget _buildPermissionBanner(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (_permissionChecked && _nearbyPermissionGranted) {
      return const SizedBox.shrink();
    }
    if (!_permissionChecked) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text('Verificando permisos de red...'),
            ),
          ],
        ),
      );
    }
    // Permiso denegado
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Permiso "Dispositivos WiFi cercanos" denegado. '
              'Actívalo en Ajustes > Himnario ID > Permisos para '
              'descubrir displays automáticamente.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contenido de escaneo ─────────────────────────────────────

  Widget _buildScanContent(
    ColorScheme colorScheme,
    TextTheme textTheme,
    ConnectionState connectionState,
    ScrollController scrollController,
  ) {
    final discoveryState = ref.watch(discoveredDevicesProvider);
    final scannerAsync = ref.watch(displayScannerProvider);
    final isConnected = connectionState is Connected;
    final connectedDevice = isConnected ? connectionState.device : null;

    // Si hay conexión activa, mostrar panel de control remoto (D2).
    if (isConnected) {
      return _buildRemoteControlPanel(colorScheme, textTheme, connectionState);
    }

    // Sincronizar dispositivos del scanner nsd con el estado local.
    final nsdDevices = scannerAsync.valueOrNull ?? <DiscoveredDisplay>[];
    final allDevices = <DeviceInfo>{
      ...discoveryState.devices,
      ...nsdDevices.map(
        (d) => DeviceInfo(name: d.name, ip: d.host, port: d.port, id: d.sessionId),
      ),
    }.toList()
      // Ordenar: primero los conectados, luego por nombre.
      ..sort((a, b) {
        final aConnected =
            connectedDevice != null && a.ip == connectedDevice.ip;
        final bConnected =
            connectedDevice != null && b.ip == connectedDevice.ip;
        if (aConnected && !bConnected) return -1;
        if (!aConnected && bConnected) return 1;
        return a.name.compareTo(b.name);
      });

    // Registrar cuándo termina un escaneo para el estado vacío.
    if (!discoveryState.isScanning &&
        !scannerAsync.isLoading &&
        _lastScanCompleted == null) {
      _lastScanCompleted = DateTime.now();
    }

    final showEmptyState = allDevices.isEmpty &&
        !discoveryState.isScanning &&
        !scannerAsync.isLoading &&
        _lastScanCompleted != null &&
        DateTime.now().difference(_lastScanCompleted!) >= const Duration(seconds: 10);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        _buildScanSection(colorScheme, textTheme, discoveryState),

        // Lista de dispositivos con AnimatedList
        if (allDevices.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Dispositivos encontrados',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnimatedDeviceList(
            colorScheme, textTheme, allDevices, connectedDevice, connectionState,
          ),
        ],

        // ── D1.5: Estado vacío tras 10s sin resultados ──
        if (showEmptyState)
          _buildEmptyState(colorScheme, textTheme),

        // Banner de error
        if (discoveryState.error != null)
          _buildErrorBanner(colorScheme, textTheme, discoveryState.error!),

        // ── Sección de conexión manual por IP ──
        const SizedBox(height: 24),
        _buildManualConnection(colorScheme, textTheme),
      ],
    );
  }

  // ── D1.4: AnimatedList ───────────────────────────────────────

  Widget _buildAnimatedDeviceList(
    ColorScheme colorScheme,
    TextTheme textTheme,
    List<DeviceInfo> devices,
    DeviceInfo? connectedDevice,
    ConnectionState connectionState,
  ) {
    // Diff con la lista anterior para animar inserciones/remociones.
    final oldSet = _previousDevices.map((d) => '${d.ip}:${d.port}').toSet();
    final newSet = devices.map((d) => '${d.ip}:${d.port}').toSet();

    final removed = oldSet.difference(newSet);
    final added = newSet.difference(oldSet);

    for (final key in removed) {
      final idx = _previousDevices.indexWhere(
        (d) => '${d.ip}:${d.port}' == key,
      );
      if (idx >= 0) {
        _listKey.currentState?.removeItem(
          idx,
          (context, animation) => _buildDeviceTileAnimated(
            colorScheme, textTheme, _previousDevices[idx],
            connectedDevice, connectionState, animation,
          ),
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    for (final key in added) {
      final idx = devices.indexWhere((d) => '${d.ip}:${d.port}' == key);
      if (idx >= 0) {
        _listKey.currentState?.insertItem(
          idx,
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    _previousDevices = List.of(devices);

    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: devices.length,
      itemBuilder: (context, index, animation) {
        if (index >= devices.length) return const SizedBox.shrink();
        return _buildDeviceTileAnimated(
          colorScheme, textTheme, devices[index],
          connectedDevice, connectionState, animation,
        );
      },
    );
  }

  /// Tile animado para cada dispositivo en [AnimatedList].
  Widget _buildDeviceTileAnimated(
    ColorScheme colorScheme,
    TextTheme textTheme,
    DeviceInfo device,
    DeviceInfo? connectedDevice,
    ConnectionState connectionState,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _buildDeviceTile(
          colorScheme, textTheme, device, connectedDevice, connectionState,
        ),
      ),
    );
  }

  // ── Sección de escaneo ───────────────────────────────────────

  Widget _buildScanSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    DiscoveryState state,
  ) {
    if (state.isScanning) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Buscando displays...',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          ref.read(discoveredDevicesProvider.notifier).startScanning();
        },
        icon: const Icon(Icons.search_rounded),
        label: const Text('Buscar displays'),
      ),
    );
  }

  // ── Device Tile ──────────────────────────────────────────────

  Widget _buildDeviceTile(
    ColorScheme colorScheme,
    TextTheme textTheme,
    DeviceInfo device,
    DeviceInfo? connectedDevice,
    ConnectionState connectionState,
  ) {
    final isThisConnected = connectedDevice != null &&
        connectedDevice.ip == device.ip &&
        connectedDevice.port == device.port;

    final isThisConnecting =
        _connectingIp == device.ip && connectionState is Connecting;

    final isThisError =
        _connectingIp == device.ip && connectionState is ConnectionError;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isThisConnected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isThisConnected
            ? Border.all(color: colorScheme.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isThisConnected ? null : () => _connectToDevice(device),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono del dispositivo
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isThisConnected
                        ? colorScheme.primary
                        : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isThisConnected
                        ? Icons.cast_connected_rounded
                        : Icons.tv_rounded,
                    color: isThisConnected
                        ? colorScheme.onPrimary
                        : colorScheme.onSecondaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Nombre, IP y puerto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              device.name,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ── D1.3: Badge "Conectado" ──
                          if (isThisConnected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 12,
                                    color: colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Conectado',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${device.ip}:${device.port}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Botón de acción contextual
                _buildDeviceAction(
                  colorScheme,
                  isThisConnected,
                  isThisConnecting,
                  isThisError,
                  device,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceAction(
    ColorScheme colorScheme,
    bool isThisConnected,
    bool isThisConnecting,
    bool isThisError,
    DeviceInfo device,
  ) {
    if (isThisConnected) {
      return TextButton(
        onPressed: () => _disconnect(),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text('Desconectar'),
      );
    }

    if (isThisConnecting) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
    }

    if (isThisError) {
      return TextButton(
        onPressed: () => _connectToDevice(device),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.error,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text('Reintentar'),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: () => _connectToDevice(device),
      icon: const Icon(Icons.link_rounded, size: 18),
      label: const Text('Conectar'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  // ── D1.5: Estado vacío ───────────────────────────────────────

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron displays en la red',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aseg\u00farate de que la PC est\u00e9 encendida\ny en la misma red WiFi.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Tambi\u00e9n puedes usar "Conexi\u00f3n manual"\nm\u00e1s abajo con la IP de la PC.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              _lastScanCompleted = null;
              ref.invalidate(displayScannerProvider);
              ref.read(discoveredDevicesProvider.notifier).startScanning();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // ── Conexión manual por IP ────────────────────────────────────

  Widget _buildManualConnection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Conexión manual',
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _manualIpController,
                decoration: const InputDecoration(
                  labelText: 'Dirección IP',
                  hintText: '192.168.1.100',
                  prefixIcon: Icon(Icons.computer),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _connectManual(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _manualPortController,
                decoration: const InputDecoration(
                  labelText: 'Puerto',
                  hintText: '50051',
                  prefixIcon: Icon(Icons.settings_ethernet),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _connectManual(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _connectManual,
            icon: const Icon(Icons.link),
            label: const Text('Conectar manualmente'),
          ),
        ),
      ],
    );
  }

  // ── Rol selection ────────────────────────────────────────────

  Widget _buildRoleSelection(ColorScheme colorScheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleCard(
            icon: Icons.cast_rounded,
            title: 'Soy Emisor',
            description: 'Controlar la proyecci\u00f3n\ndesde mi dispositivo',
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            textTheme: textTheme,
            onTap: _selectEmitter,
          ),
          const SizedBox(height: 16),
          _roleCard(
            icon: Icons.tv_rounded,
            title: 'Soy Receptor',
            description: 'Mostrar en esta pantalla\nlo que el emisor env\u00eda',
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            textTheme: textTheme,
            onTap: _selectReceiver,
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String description,
    required Color backgroundColor,
    required Color foregroundColor,
    required TextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: foregroundColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: foregroundColor, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: foregroundColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: foregroundColor.withValues(alpha: 0.6),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error banner ─────────────────────────────────────────────

  Widget _buildErrorBanner(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String errorMessage,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error de escaneo',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(discoveredDevicesProvider.notifier).clearError();
                    ref
                        .read(discoveredDevicesProvider.notifier)
                        .startScanning();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onErrorContainer,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Reintentar escaneo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // D2: PANEL DE CONTROL REMOTO
  // ═══════════════════════════════════════════════════════════════

  /// Panel de control remoto que se muestra cuando hay una conexión
  /// activa con un display. Organizado en secciones dentro de [Card]s.
  ///
  /// Usa [liveDisplayStatusProvider] para el estado en vivo y
  /// [controlDataSourceProvider]/[controlRepositoryProvider] para enviar
  /// comandos.
  Widget _buildRemoteControlPanel(
    ColorScheme colorScheme,
    TextTheme textTheme,
    ConnectionState connectionState,
  ) {
    final device = (connectionState as Connected).device;
    final liveStatus = ref.watch(liveDisplayStatusProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header del dispositivo conectado
        _buildConnectedHeader(colorScheme, textTheme, device, liveStatus),
        const SizedBox(height: 16),

        // ── D2.2: Selector de fondo ──
        _buildBackgroundSection(colorScheme, textTheme, liveStatus),
        const SizedBox(height: 12),

        // ── D2.3: Botón desconectar ──
        _buildDisconnectButton(colorScheme, textTheme),
      ],
    );
  }

  /// Cabecera del dispositivo conectado (nombre, ip, estado).
  Widget _buildConnectedHeader(
    ColorScheme colorScheme,
    TextTheme textTheme,
    DeviceInfo device,
    AsyncValue<domain.DisplayStatus?> liveStatus,
  ) {
    final status = liveStatus.valueOrNull;
    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.cast_connected_rounded,
                color: colorScheme.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device.ip}:${device.port}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (status != null && status.displayName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      status.displayName,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (liveStatus.isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ── D2.2: Selector de fondo (remoto) ──────────────────────────

  /// Sección de fondo remoto: muestra los fondos disponibles en el PC
  /// conectado como [FilterChip]s. Al seleccionar uno, envía
  /// [GrpcControlDataSource.sendSetBackground] al display remoto.
  Widget _buildBackgroundSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AsyncValue<domain.DisplayStatus?> liveStatus,
  ) {
    final remoteFondosAsync = ref.watch(remoteBackgroundsProvider);
    final currentBgId = liveStatus.valueOrNull?.currentBackgroundId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fondo (PC remoto)',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            remoteFondosAsync.when(
              loading: () => const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => Text(
                'Error al cargar fondos remotos',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              data: (fondos) {
                if (fondos.isEmpty) {
                  return Text(
                    'No hay fondos disponibles en el PC',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: fondos.map((bg) {
                    final bgId = bg['id'] as int;
                    final nombre = bg['nombre'] as String;
                    final isSelected = currentBgId == bgId.toString();
                    return FilterChip(
                      label: Text(
                        nombre,
                        style: textTheme.labelSmall,
                      ),
                      selected: isSelected,
                      onSelected: (_) =>
                          _selectRemoteBackground(bgId, currentBgId),
                      showCheckmark: true,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Envía el comando [SET_BACKGROUND] al display remoto.
  Future<void> _selectRemoteBackground(
    int bgId,
    String? currentBgId,
  ) async {
    if (currentBgId == bgId.toString()) return;
    try {
      await ref
          .read(controlDataSourceProvider)
          .sendSetBackground(bgId.toString());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar fondo remoto: $e')),
      );
    }
  }





  // ── D2.3: Botón desconectar ──────────────────────────────────

  Widget _buildDisconnectButton(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _disconnect();
          Navigator.pop(context);
        },
        icon: const Icon(Icons.link_off_rounded),
        label: const Text('Desconectar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
