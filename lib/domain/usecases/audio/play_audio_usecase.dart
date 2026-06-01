import '../../../core/errors/failures.dart';
import '../../entities/pista_audio.dart';
import '../../repositories/audio_repository.dart';

/// Caso de uso para reproducción de audio asociado a himnos.
class PlayAudioUseCase {
  final AudioRepository _repository;

  PlayAudioUseCase(this._repository);

  /// Obtiene las pistas de audio de un himno.
  Future<List<PistaAudio>> getTracks(int himnoId) async {
    if (himnoId <= 0) {
      throw const InvalidArgumentFailure('ID de himno inválido');
    }
    return await _repository.getByHimno(himnoId);
  }

  /// Inicia la reproducción de una pista.
  Future<void> play(int pistaId) async {
    if (pistaId <= 0) {
      throw const InvalidArgumentFailure('ID de pista inválido');
    }
    await _repository.play(pistaId);
  }

  /// Detiene la reproducción actual.
  Future<void> stop() async {
    await _repository.stop();
  }
}
