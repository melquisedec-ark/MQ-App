/// Representa un servicio mDNS descubierto vía nsd.
class BonsoirDiscoveredService {
  final String name;
  final String ip;
  final int port;
  final Map<String, String> attributes;
  final bool isNew;
  final bool isRemoved;

  const BonsoirDiscoveredService({
    required this.name,
    required this.ip,
    required this.port,
    this.attributes = const {},
    this.isNew = true,
    this.isRemoved = false,
  });

  @override
  String toString() => 'BonsoirDiscoveredService($name, $ip:$port)';
}
