/// Rol de conexión para el modo Emisor/Receptor.
enum ConnectionRole { emitter, receiver, none }

/// Información de un dispositivo descubierto en la red.
class DeviceInfo {
  final String name;
  final String ip;
  final int port;
  final String? id;

  const DeviceInfo({
    required this.name,
    required this.ip,
    required this.port,
    this.id,
  });

  @override
  String toString() => 'DeviceInfo(name: $name, ip: $ip, port: $port)';
}

/// Estados posibles de la conexión con el display.
sealed class ConnectionState {
  const ConnectionState();
}

/// Estado: desconectado, sin búsqueda activa.
class Disconnected extends ConnectionState {
  const Disconnected();
}

/// Estado: buscando dispositivos en la red.
class Connecting extends ConnectionState {
  const Connecting();
}

/// Estado: conectado a un dispositivo.
class Connected extends ConnectionState {
  final DeviceInfo device;
  final ConnectionRole role;

  const Connected(this.device, {this.role = ConnectionRole.none});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connected && device == other.device && role == other.role;

  @override
  int get hashCode => Object.hash(device, role);
}

/// Estado: error en la conexión.
class ConnectionError extends ConnectionState {
  final String message;

  const ConnectionError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionError && message == other.message;

  @override
  int get hashCode => message.hashCode;
}
