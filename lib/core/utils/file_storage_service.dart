import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio helper para copiar archivos de fondos al almacenamiento local de la app.
///
/// Los fondos (imágenes) se copian a `{appDocsDir}/himnario_id/fondos/`
/// con un nombre único para evitar colisiones.
///
/// Así la app es dueña del archivo y no depende de rutas externas (galería, URI temporal).
/// Al eliminar un fondo, solo se borra la copia interna, nunca el original del usuario.
class FileStorageService {
  static final _log = Logger('FileStorageService');

  static const _subdirectory = 'himnario_id/fondos';

  /// Retorna la ruta del directorio de fondos, creándolo si no existe.
  static Future<String> get fondosDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_subdirectory');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Copia el archivo en [sourcePath] al directorio local de fondos.
  ///
  /// [sourcePath] puede ser una ruta absoluta del sistema o una content:// URI
  /// (Android scoped storage). En content:// se usa [readStream] provisto por file_picker.
  ///
  /// [fileName] es el nombre original del archivo, necesario para content:// URIs
  /// donde el path no es descriptivo. Si se omite, se extrae de [sourcePath].
  ///
  /// Retorna la ruta absoluta del archivo copiado, o [sourcePath] si el archivo
  /// ya está dentro del directorio de fondos (evita duplicar).
  static Future<String> copyToFondos({
    required String sourcePath,
    String? fileName,
    Stream<List<int>>? readStream,
  }) async {
    final fondosDir = await fondosDirectory;

    // Si ya está dentro del directorio de fondos, no copiar de nuevo
    if (sourcePath.startsWith(fondosDir)) {
      _log.fine('Archivo ya está en fondos, se omite copia: $sourcePath');
      return sourcePath;
    }

    final name = fileName ?? sourcePath.split(Platform.pathSeparator).last;
    final destPath = await _uniquePath(fondosDir, name);
    final destFile = File(destPath);

    if (readStream != null) {
      // content:// URI: usar stream de bytes
      await _copyFromStream(readStream, destFile);
    } else {
      // Ruta absoluta del sistema: copia directa
      await File(sourcePath).copy(destPath);
    }

    _log.info('Fondo copiado: $sourcePath → $destPath');
    return destPath;
  }

  /// Elimina el archivo en [path] **solo si** está dentro del directorio
  /// local de fondos de la app. Si el archivo está fuera (galería, etc.),
  /// no se toca para no dañar archivos del usuario.
  static Future<void> deleteIfAppFile(String path) async {
    final fondosDir = await fondosDirectory;
    if (!path.startsWith(fondosDir)) {
      _log.fine('Archivo fuera del directorio app, se omite: $path');
      return;
    }
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      _log.info('Archivo de fondo eliminado: $path');
    } else {
      _log.fine('Archivo no existe en disco, se omite: $path');
    }
  }

  // ─── helpers privados ───

  /// Copia bytes desde un [stream] a [destFile].
  /// Acepta `Stream<List<int>>` (el tipo que expone file_picker.readStream).
  static Future<void> _copyFromStream(
    Stream<List<int>> stream,
    File destFile,
  ) async {
    final sink = destFile.openWrite();
    try {
      await sink.addStream(stream);
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  /// Genera una ruta única en [dir] para el nombre [name].
  /// Si ya existe un archivo con ese nombre, agrega un sufijo numérico.
  static Future<String> _uniquePath(String dir, String name) async {
    // Sanitizar: solo caracteres seguros para el sistema de archivos
    final safeName = name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final base = '$dir/$safeName';
    if (!await File(base).exists()) return base;

    // Agregar sufijo numérico
    final dot = safeName.lastIndexOf('.');
    final stem = dot == -1 ? safeName : safeName.substring(0, dot);
    final ext = dot == -1 ? '' : safeName.substring(dot);

    for (int i = 1; i < 1000; i++) {
      final candidate = '$dir/${stem}_$i$ext';
      if (!await File(candidate).exists()) return candidate;
    }
    // Si llegamos aquí, algo raro pasa; usar timestamp
    return '$dir/${stem}_${DateTime.now().millisecondsSinceEpoch}$ext';
  }
}
