import '../entities/pista_audio.dart';

/// Interfaz de repositorio para operaciones CRUD sobre pistas de audio.
abstract class PistaAudioRepository {
  /// Obtiene todas las pistas de audio de un himno.
  Future<List<PistaAudio>> getByHimno(int himnoId);

  /// Crea una pista de audio.
  /// Retorna el ID autogenerado.
  Future<int> create({
    required int himnoId,
    required String rutaArchivo,
    String? descripcion,
    double? duracionSegundos,
    String? formato,
    String origen,
  });

  /// Elimina la pista de audio con [id].
  Future<void> delete(int id);
}
