import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Servicio helper para copiar/eliminar archivos de audio.
///
/// Los audios se copian a `{appDocsDir}/audio/{himno_id}/{nombre_archivo}`
/// para mantenerlos aislados por himno y no depender de la ruta original.
class AudioFileService {
  /// Copia [sourcePath] al directorio del himno [himnoId].
  /// Sanitiza el nombre del archivo para evitar problemas con GStreamer
  /// (reemplaza espacios, #, & y otros caracteres especiales por _).
  /// Retorna la ruta absoluta del archivo copiado.
  static Future<String> copyAudioFile(String sourcePath, int himnoId) async {
    final dir = await getApplicationDocumentsDirectory();
    final destDir = Directory('${dir.path}/audio/$himnoId');
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final fileName = sourcePath.split(Platform.pathSeparator).last;
    // Sanitizar nombre: reemplazar caracteres problemáticos para GStreamer
    final sanitized = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final destPath = '${destDir.path}/$sanitized';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Elimina el archivo en [path] si existe (idempotente).
  static Future<void> deleteAudioFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
