import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/core/database/bible_schema_version.dart';

void main() {
  group('BibleSchemaVersion — needsUpdate (función pura)', () {
    test('retorna true cuando assetVersion > localVersion', () {
      expect(BibleSchemaVersion.needsUpdate(2, 1), isTrue);
      expect(BibleSchemaVersion.needsUpdate(5, 3), isTrue);
    });

    test('retorna false cuando assetVersion <= localVersion', () {
      expect(BibleSchemaVersion.needsUpdate(1, 1), isFalse);
      expect(BibleSchemaVersion.needsUpdate(1, 2), isFalse);
      expect(BibleSchemaVersion.needsUpdate(0, 1), isFalse);
    });

    test('retorna false cuando ambas son 0 (sin asset, sin local)', () {
      expect(BibleSchemaVersion.needsUpdate(0, 0), isFalse);
    });
  });

  group('BibleSchemaVersion — readLocalVersion / writeLocalVersion', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('biblia_version_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('readLocalVersion retorna 0 cuando no existe archivo', () async {
      final version = await BibleSchemaVersion.readLocalVersion(tempDir.path);
      expect(version, 0);
    });

    test('writeLocalVersion escribe y readLocalVersion lee correctamente',
        () async {
      await BibleSchemaVersion.writeLocalVersion(tempDir.path, 3);
      final version = await BibleSchemaVersion.readLocalVersion(tempDir.path);
      expect(version, 3);
    });

    test('readLocalVersion retorna 0 para contenido no numérico', () async {
      final file = File('${tempDir.path}/biblia_version_applied.txt');
      await file.writeAsString('no-es-un-numero');
      final version = await BibleSchemaVersion.readLocalVersion(tempDir.path);
      expect(version, 0);
    });

    test('ciclo completo: write+read con versión 0', () async {
      await BibleSchemaVersion.writeLocalVersion(tempDir.path, 0);
      final version = await BibleSchemaVersion.readLocalVersion(tempDir.path);
      expect(version, 0);
    });

    test('write+read con versión alta (999)', () async {
      await BibleSchemaVersion.writeLocalVersion(tempDir.path, 999);
      final version = await BibleSchemaVersion.readLocalVersion(tempDir.path);
      expect(version, 999);
    });
  });
}
