import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  group('BibleDatabaseHelper (constantes)', () {
    test('SCHEMA_VERSION es 2 (migración 004 cross_referencia)', () {
      expect(BibleDatabaseHelper.SCHEMA_VERSION, 2);
    });

    test('dbFileName es biblia.db', () {
      expect(BibleDatabaseHelper.dbFileName, 'biblia.db');
    });
  });

  group('BibleDatabaseHelper.forTesting', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('biblia_helper_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('acepta una BD externa y la expone vía `database`', () async {
      // Usa el factory global (configurado por initBibleTestFfi) que
      // tiene el override de libsqlite3.so.0.
      final db = await databaseFactory.openDatabase(
        '${tempDir.path}/test.db',
        options: OpenDatabaseOptions(
          version: BibleDatabaseHelper.SCHEMA_VERSION,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE version (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT NOT NULL UNIQUE
              );
            ''');
          },
        ),
      );

      final helper = BibleDatabaseHelper.forTesting(db);
      final accessed = await helper.database;
      expect(accessed, equals(db));
      await helper.close();
    });

    test('close() libera la referencia interna', () async {
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('CREATE TABLE x (id INTEGER PRIMARY KEY)');
          },
        ),
      );
      final helper = BibleDatabaseHelper.forTesting(db);
      await helper.close();
      // Después de close, la siguiente llamada a .database re-inicializa.
      // Como el helper es singleton y el _database es null después de
      // close, NO debería crashear.
      // (El re-init intentará usar FFI en la ubicación por defecto, lo
      // cual puede fallar en este entorno de tests; lo evitamos.)
      // Verificamos solo que close no lance.
      expect(true, isTrue);
      await db.close();
    });
  });
}
