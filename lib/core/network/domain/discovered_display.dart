/// Representa un display descubierto en la LAN vía mDNS/nsd.
class DiscoveredDisplay {
  final String name;
  final String host;
  final int port;
  final String sessionId;

  const DiscoveredDisplay({
    required this.name,
    required this.host,
    required this.port,
    this.sessionId = '',
  });

  @override
  String toString() => 'DiscoveredDisplay($name, $host:$port)';
}
