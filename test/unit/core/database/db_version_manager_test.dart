import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/database/db_version_manager.dart';

void main() {
  group('DbVersionManager — needsUpdate (función pura)', () {
    test('retorna true cuando assetVersion > localVersion', () {
      expect(DbVersionManager.needsUpdate(2, 1), isTrue);
      expect(DbVersionManager.needsUpdate(5, 3), isTrue);
    });

    test('retorna false cuando assetVersion <= localVersion', () {
      expect(DbVersionManager.needsUpdate(1, 1), isFalse);
      expect(DbVersionManager.needsUpdate(1, 2), isFalse);
      expect(DbVersionManager.needsUpdate(0, 1), isFalse);
    });

    test('retorna false cuando ambas son 0 (sin asset, sin local)', () {
      expect(DbVersionManager.needsUpdate(0, 0), isFalse);
    });

    test('retorna true solo cuando asset estrictamente mayor', () {
      expect(DbVersionManager.needsUpdate(3, 2), isTrue);
      expect(DbVersionManager.needsUpdate(2, 3), isFalse);
      expect(DbVersionManager.needsUpdate(100, 99), isTrue);
    });
  });

  group(
    'DbVersionManager — readLocalVersion / writeLocalVersion (sistema de archivos)',
    () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('db_version_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('readLocalVersion retorna 0 cuando no existe archivo', () async {
        final version = await DbVersionManager.readLocalVersion(tempDir.path);
        expect(version, 0);
      });

      test('writeLocalVersion escribe y readLocalVersion lee correctamente',
          () async {
        await DbVersionManager.writeLocalVersion(tempDir.path, 3);
        final version = await DbVersionManager.readLocalVersion(tempDir.path);
        expect(version, 3);
      });

      test('readLocalVersion retorna 0 para contenido no numérico', () async {
        final file = File('${tempDir.path}/db_version_applied.txt');
        await file.writeAsString('no-es-un-numero');
        final version = await DbVersionManager.readLocalVersion(tempDir.path);
        expect(version, 0);
      });

      test('ciclo completo: write+read con versión 0', () async {
        await DbVersionManager.writeLocalVersion(tempDir.path, 0);
        final version = await DbVersionManager.readLocalVersion(tempDir.path);
        expect(version, 0);
      });

      test('write+read con versión alta (999)', () async {
        await DbVersionManager.writeLocalVersion(tempDir.path, 999);
        final version = await DbVersionManager.readLocalVersion(tempDir.path);
        expect(version, 999);
      });

      test('re-escritura actualiza la versión', () async {
        await DbVersionManager.writeLocalVersion(tempDir.path, 1);
        await DbVersionManager.writeLocalVersion(tempDir.path, 2);
        await DbVersionManager.writeLocalVersion(tempDir.path, 3);
        final version = await DbVersionManager.readLocalVersion(tempDir.path);
        expect(version, 3);
      });
    },
  );

  group('DbVersionManager — readAssetVersion (fallback en test)', () {
    test(
      'retorna 0 cuando el asset no existe en el entorno de test',
      () async {
        // En flutter_test sin asset configurado, rootBundle falla
        // y readAssetVersion retorna 0 (fallback seguro)
        final version = await DbVersionManager.readAssetVersion();
        expect(version, 0);
      },
    );
  });

  group('DbVersionManager — assetDbBytes (fallback en test)', () {
    test('retorna Uint8List vacío cuando no hay asset', () async {
      final bytes = await DbVersionManager.assetDbBytes();
      expect(bytes, isA<Uint8List>());
      // En flutter_test sin el asset empaquetado, retorna lista vacía
      expect(bytes.length, 0);
    });
  });
}
