import '../../../core/errors/failures.dart';
import '../../repositories/control_repository.dart';

/// Comandos disponibles para enviar al display.
enum ControlCommand {
  nextStanza,
  prevStanza,
  goToStanza,
  blackout,
  clearBlackout,
  showHimno,
  playAudio,
  stopAudio,
  setConfig,
}

/// Parámetros de configuración del display.
class ConfigParams {
  final String? fondo;
  final double? tamano;

  const ConfigParams({this.fondo, this.tamano});
}

/// Caso de uso para enviar comandos al display remoto.
class SendCommandUseCase {
  final ControlRepository _repository;

  SendCommandUseCase(this._repository);

  /// Ejecuta un comando en el display remoto.
  Future<bool> execute(
    ControlCommand command, {
    int? stanzaIndex,
    int? himnoId,
    ConfigParams? config,
  }) async {
    try {
      switch (command) {
        case ControlCommand.nextStanza:
          return await _repository.sendNextStanza();
        case ControlCommand.prevStanza:
          return await _repository.sendPrevStanza();
        case ControlCommand.goToStanza:
          if (stanzaIndex == null) {
            throw const InvalidArgumentFailure(
              'Se requiere stanzaIndex para goToStanza',
            );
          }
          return await _repository.sendGoToStanza(stanzaIndex);
        case ControlCommand.blackout:
          return await _repository.sendBlackout(true);
        case ControlCommand.clearBlackout:
          return await _repository.sendBlackout(false);
        case ControlCommand.showHimno:
          if (himnoId == null) {
            throw const InvalidArgumentFailure(
              'Se requiere himnoId para showHimno',
            );
          }
          return await _repository.sendShowHimno(himnoId);
        case ControlCommand.playAudio:
          return await _repository.sendPlayAudio();
        case ControlCommand.stopAudio:
          return await _repository.sendStopAudio();
        case ControlCommand.setConfig:
          return await _repository.sendSetConfig(
            fondo: config?.fondo,
            tamano: config?.tamano,
          );
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Error al ejecutar comando: $e');
    }
  }
}
