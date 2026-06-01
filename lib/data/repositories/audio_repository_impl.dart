import 'package:logging/logging.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/pista_audio.dart';
import '../../domain/repositories/audio_repository.dart';
import '../datasources/local/audio_local_datasource.dart';
import '../datasources/local/catalog_local_datasource.dart';

/// Implementación del repositorio de audio.
///
/// Usa [AudioLocalDataSource] para la reproducción y
/// [CatalogLocalDataSource] para consultar pistas desde la BD.
class AudioRepositoryImpl implements AudioRepository {
  static final _log = Logger('AudioRepositoryImpl');

  final AudioLocalDataSource _audioDataSource;
  final CatalogLocalDataSource _catalogDataSource;

  /// Cache de pistas de audio por ID de pista.
  final Map<int, PistaAudio> _pistaCache = {};

  AudioRepositoryImpl({
    AudioLocalDataSource? audioDataSource,
    CatalogLocalDataSource? catalogDataSource,
  })  : _audioDataSource = audioDataSource ?? AudioLocalDataSource(),
        _catalogDataSource = catalogDataSource ?? CatalogLocalDataSource();

  @override
  Future<List<PistaAudio>> getByHimno(int himnoId) async {
    try {
      final models = await _catalogDataSource.getPistasByHimno(himnoId);
      final pistas = models.map((m) => m.toEntity()).toList();

      // Poblar caché por ID de pista
      for (final pista in pistas) {
        _pistaCache[pista.id] = pista;
      }

      _log.fine('${pistas.length} pista(s) encontrada(s) para himno $himnoId');
      return pistas;
    } catch (e) {
      _log.severe('Error al obtener pistas del himno $himnoId: $e');
      throw AudioFailure('Error al obtener pistas de audio: $e');
    }
  }

  @override
  Future<void> play(int pistaId) async {
    try {
      final pista = _pistaCache[pistaId];
      if (pista == null) {
        throw AudioFailure('Pista de audio no encontrada (id: $pistaId)');
      }

      // Si la ruta es absoluta (empieza con /), usar playFromFile
      // Si no, usar playFromAsset (para assets del bundle)
      if (pista.rutaArchivo.startsWith('/')) {
        await _audioDataSource.playFromFile(pista.rutaArchivo);
      } else {
        await _audioDataSource.playFromAsset(pista.rutaArchivo);
      }
      _log.info('Reproduciendo pista $pistaId: ${pista.rutaArchivo}');
    } on AudioFailure {
      rethrow;
    } catch (e) {
      _log.severe('Error al reproducir pista $pistaId: $e');
      throw AudioFailure('Error al reproducir audio: $e');
    }
  }

  @override
  bool get isPlaying => _audioDataSource.isPlaying;

  @override
  Stream<Duration> get onPositionChanged => _audioDataSource.onPositionChanged;

  @override
  Stream<Duration?> get onDurationChanged => _audioDataSource.onDurationChanged;

  @override
  Future<void> stop() async {
    try {
      await _audioDataSource.stop();
      _log.info('Reproducción detenida.');
    } catch (e) {
      _log.severe('Error al detener audio: $e');
      throw AudioFailure('Error al detener la reproducción: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _audioDataSource.pause();
    } catch (e) {
      _log.severe('Error al pausar: $e');
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _audioDataSource.resume();
    } catch (e) {
      _log.severe('Error al reanudar: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _audioDataSource.seek(position);
    } catch (e) {
      _log.severe('Error al seek: $e');
    }
  }
}
