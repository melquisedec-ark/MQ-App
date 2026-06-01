/// Información del estado actual del display remoto.
class DisplayStatus {
  final int currentHymnId;
  final String currentHymnTitle;
  final int currentStanzaIndex;
  final int totalStanzas;
  final int transpositionSemitones;
  final bool isBlackout;
  final String? currentBackgroundId;
  final double fontSize;
  final String displayName;

  const DisplayStatus({
    required this.currentHymnId,
    required this.currentHymnTitle,
    required this.currentStanzaIndex,
    required this.totalStanzas,
    this.transpositionSemitones = 0,
    this.isBlackout = false,
    this.currentBackgroundId,
    this.fontSize = 48.0,
    this.displayName = '',
  });
}

/// Repositorio de control remoto.
/// Define el contrato para la comunicación con el display vía gRPC.
abstract class ControlRepository {
  /// Establece conexión con un display remoto.
  Future<bool> connect(String host, int port);

  /// Envía un comando para mostrar un himno específico.
  Future<bool> sendShowHimno(int himnoId);

  /// Envía comando para avanzar a la siguiente estrofa.
  Future<bool> sendNextStanza();

  /// Envía comando para retroceder a la estrofa anterior.
  Future<bool> sendPrevStanza();

  /// Envía comando para ir a una estrofa específica.
  Future<bool> sendGoToStanza(int index);

  /// Envía comando para activar/desactivar blackout.
  Future<bool> sendBlackout(bool active);

  /// Envía comando para reproducir audio.
  Future<bool> sendPlayAudio();

  /// Envía comando para detener audio.
  Future<bool> sendStopAudio();

  /// Envía comando para cambiar configuración del display.
  Future<bool> sendSetConfig({String? fondo, double? tamano});

  /// Obtiene el estado actual del display.
  Future<DisplayStatus> getStatus();

  /// Stream de estado del display en tiempo real.
  Stream<DisplayStatus> watchStatus();
}
