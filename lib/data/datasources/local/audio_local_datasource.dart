import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// DataSource local para reproducción de audio.
///
/// Encapsula la implementación con [audioplayers] para reproducir
/// pistas desde assets o desde el sistema de archivos.
class AudioLocalDataSource {
  static final _log = Logger('AudioLocalDataSource');

  final AudioPlayer _player;

  /// Callback que se invoca cuando la reproducción finaliza.
  void Function()? onCompletion;

  AudioLocalDataSource({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    _player.onPlayerComplete.listen((_) {
      _log.fine('Reproducción completada.');
      onCompletion?.call();
    });
  }

  /// Indica si hay una reproducción en curso.
  bool get isPlaying => _player.state == PlayerState.playing;

  /// Stream de cambios de posición durante la reproducción.
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  /// Stream con la duración total del audio actual.
  Stream<Duration?> get onDurationChanged => _player.onDurationChanged;

  /// Pausa la reproducción actual.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Reanuda la reproducción pausada.
  Future<void> resume() async {
    await _player.resume();
  }

  /// Navega a una posición específica del audio.
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Reproduce un archivo desde la carpeta de assets.
  ///
  /// [assetPath] debe ser una ruta relativa a assets/, ej: "audio/001.mp3".
  Future<void> playFromAsset(String assetPath) async {
    try {
      _log.info('Reproduciendo desde asset: $assetPath');
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      _log.severe('Error al reproducir asset $assetPath: $e');
      throw const AudioException(
        'Error al reproducir audio desde asset',
      );
    }
  }

  /// Reproduce un archivo desde el sistema de archivos.
  ///
  /// [filePath] debe ser una ruta absoluta al archivo.
  Future<void> playFromFile(String filePath) async {
    try {
      String resolvedPath = filePath;

      // 1. Verificar si el archivo existe en la ruta original
      if (!File(resolvedPath).existsSync()) {
        // 2. Intentar con nombre sanitizado (reemplazar caracteres especiales)
        final dir = Directory(resolvedPath).parent;
        final fileName = resolvedPath.split('/').last;
        final sanitized = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final altPath = '${dir.path}/$sanitized';
        if (File(altPath).existsSync()) {
          resolvedPath = altPath;
          _log.info('Usando ruta sanitizada: $resolvedPath');
        } else {
          // 3. Intentar resolver contra appDocsDir/audio/ (para Android)
          final appDir = await getApplicationDocumentsDirectory();
          final relativePath = 'audio/${filePath.split('/audio/').last}';
          final appPath = '${appDir.path}/$relativePath';
          if (File(appPath).existsSync()) {
            resolvedPath = appPath;
            _log.info('Usando ruta relativa a appDocs: $resolvedPath');
          } else {
            throw AudioException(
              'Archivo no encontrado. Agregue la pista desde el panel de administración en este dispositivo.\n'
              'Ruta buscada: $filePath',
            );
          }
        }
      }

      _log.info('Reproduciendo desde archivo: $resolvedPath');
      await _player.play(DeviceFileSource(resolvedPath));
    } on AudioException {
      rethrow;
    } catch (e) {
      _log.severe('Error al reproducir archivo $filePath: $e');
      throw AudioException(
        'Error al reproducir el audio. Verifique que el archivo exista.',
      );
    }
  }

  /// Detiene la reproducción actual.
  Future<void> stop() async {
    try {
      await _player.stop();
      _log.fine('Reproducción detenida.');
    } catch (e) {
      _log.severe('Error al detener audio: $e');
      throw const AudioException('Error al detener la reproducción');
    }
  }

  /// Libera los recursos del reproductor.
  Future<void> dispose() async {
    await _player.dispose();
    _log.fine('Recursos de audio liberados.');
  }
}

/// Excepción específica para errores de audio.
class AudioException implements Exception {
  final String message;

  const AudioException(this.message);

  @override
  String toString() => 'AudioException: $message';
}
