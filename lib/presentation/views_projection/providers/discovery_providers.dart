import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connection_state.dart';
import '../../../core/network/mdns_discovery.dart';

/// Provider de la instancia única de [MdnsDiscovery].
///
/// Se descarta automáticamente al finalizar el lifecycle del provider.
final mdnsDiscoveryProvider = Provider<MdnsDiscovery>((ref) {
  final discovery = MdnsDiscovery();
  ref.onDispose(discovery.dispose);
  return discovery;
});

/// Estado inmutable del proceso de descubrimiento mDNS.
class DiscoveryState {
  /// Indica si hay un escaneo activo en este momento.
  final bool isScanning;

  /// Lista de dispositivos descubiertos hasta el momento.
  final List<DeviceInfo> devices;

  /// Mensaje de error del último escaneo, o `null` si no hubo error.
  final String? error;

  const DiscoveryState({
    this.isScanning = false,
    this.devices = const [],
    this.error,
  });

  DiscoveryState copyWith({
    bool? isScanning,
    List<DeviceInfo>? devices,
    String? error,
    bool clearError = false,
  }) {
    return DiscoveryState(
      isScanning: isScanning ?? this.isScanning,
      devices: devices ?? this.devices,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// [StateNotifier] que envuelve [MdnsDiscovery] y expone el estado del
/// escaneo de dispositivos en la LAN.
///
/// Escucha el stream [MdnsDiscovery.onDeviceDiscovered] y acumula
/// dispositivos evitando duplicados por IP:puerto.
class DiscoveredDevicesNotifier extends StateNotifier<DiscoveryState> {
  final MdnsDiscovery _discovery;
  StreamSubscription<DeviceInfo>? _subscription;

  DiscoveredDevicesNotifier(this._discovery) : super(const DiscoveryState());

  /// Inicia el escaneo mDNS.
  ///
  /// Reinicia la lista de dispositivos al comenzar un nuevo escaneo.
  /// El escaneo se auto-detiene tras [MdnsDiscovery._searchDuration].
  Future<void> startScanning() async {
    await _subscription?.cancel();
    _subscription = null;

    state = const DiscoveryState(isScanning: true);

    _subscription = _discovery.onDeviceDiscovered.listen((device) {
      final exists = state.devices.any(
        (d) => d.ip == device.ip && d.port == device.port,
      );
      if (!exists) {
        state = state.copyWith(
          devices: [...state.devices, device],
        );
      }
    });

    try {
      await _discovery.startDiscovery();
      state = state.copyWith(isScanning: false);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: e.toString(),
      );
    }
  }

  /// Detiene el escaneo activo de forma anticipada.
  Future<void> stopScanning() async {
    await _subscription?.cancel();
    _subscription = null;
    await _discovery.stopDiscovery();
    state = state.copyWith(isScanning: false);
  }

  /// Limpia el mensaje de error del estado.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider del estado de descubrimiento de dispositivos.
///
/// Expone un [DiscoveryState] que la UI puede escuchar para mostrar
/// la lista de displays encontrados y el progreso del escaneo.
final discoveredDevicesProvider =
    StateNotifierProvider<DiscoveredDevicesNotifier, DiscoveryState>((ref) {
  final discovery = ref.watch(mdnsDiscoveryProvider);
  return DiscoveredDevicesNotifier(discovery);
});
