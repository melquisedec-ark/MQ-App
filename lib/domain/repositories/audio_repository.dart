import 'dart:async';

import '../entities/pista_audio.dart';

/// Repositorio de audio.
/// Define el contrato para la reproducción de pistas de audio asociadas a himnos.
abstract class AudioRepository {
  /// Obtiene las pistas de audio de un himno.
  Future<List<PistaAudio>> getByHimno(int himnoId);

  /// Inicia la reproducción de una pista.
  Future<void> play(int pistaId);

  /// Detiene la reproducción actual.
  Future<void> stop();

  /// Pausa la reproducción actual.
  Future<void> pause();

  /// Reanuda la reproducción pausada.
  Future<void> resume();

  /// Navega a una posición específica.
  Future<void> seek(Duration position);

  /// Stream de cambios de posición.
  Stream<Duration> get onPositionChanged;

  /// Stream con la duración total.
  Stream<Duration?> get onDurationChanged;

  /// Indica si hay reproducción en curso.
  bool get isPlaying;
}
