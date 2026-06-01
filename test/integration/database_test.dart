import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/db_test_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() => cleanupTestDatabases());

  // ───────────────────────────────────────────────────────────────
  // Grupo 1: Schema
  // ───────────────────────────────────────────────────────────────
  group('Schema initialization', () {
    test('all tables exist after creation', () async {
      final db = await createEmptyDatabase();
      try {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
        );
        final tableNames = tables.map((r) => r['name'] as String).toList();

        expect(tableNames, contains('Himno'));
        expect(tableNames, contains('Version_Pais'));
        expect(tableNames, contains('Estrofa'));
        expect(tableNames, contains('Categoria'));
        expect(tableNames, contains('Himno_Categoria'));
        expect(tableNames, contains('Usuario'));
        expect(tableNames, contains('Arreglo_Musical'));
        expect(tableNames, contains('Estrofa_Arreglo'));
        expect(tableNames, contains('Pista_Audio'));
        expect(tableNames, contains('Configuracion'));
        expect(tableNames, contains('Fondo_Pantalla'));
        expect(tableNames, contains('Historial_Reproduccion'));
        expect(tableNames, contains('Himno_Busqueda'));

        // Excluimos sqlite_sequence (auto-generado por AUTOINCREMENT)
        // del conteo porque no es una tabla de la aplicación.
        final appTables =
            tableNames.where((n) => n != 'sqlite_sequence').toList();
        expect(appTables, hasLength(13));
      } finally {
        await db.close();
      }
    });

    test('indices are created', () async {
      final db = await createEmptyDatabase();
      try {
        final indices = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%' ORDER BY name",
        );
        final indexNames = indices.map((r) => r['name'] as String).toList();

        expect(indexNames, contains('idx_himno_numero'));
        expect(indexNames, contains('idx_version_himno'));
        expect(indexNames, contains('idx_estrofa_version'));
        expect(indexNames, contains('idx_arreglo_usuario'));
        expect(indexNames, contains('idx_estrofa_arreglo'));
        expect(indexNames, contains('idx_pista_himno'));
        expect(indexNames, contains('idx_historial_timestamp'));
        expect(indexNames, contains('idx_himno_activo'));
        expect(indexNames, contains('idx_busqueda_titulo'));
        expect(indexNames, contains('idx_busqueda_contenido'));
      } finally {
        await db.close();
      }
    });

    test('views are created', () async {
      final db = await createEmptyDatabase();
      try {
        final views = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='view' ORDER BY name",
        );
        final viewNames = views.map((r) => r['name'] as String).toList();

        expect(viewNames, contains('v_himno_resumen'));
        expect(viewNames, contains('v_himno_estrofas'));
      } finally {
        await db.close();
      }
    });

    test('CHECK constraint on Himno.tipo (1,2,3) is enforced', () async {
      final db = await createEmptyDatabase();
      try {
        // Valid tipo
        await db.insert('Himno', {
          'titulo_principal': 'Valid hymn',
          'tipo': 1,
          'activo': 1,
        });

        // Invalid tipo should fail
        expect(
          () => db.insert('Himno', {
            'titulo_principal': 'Invalid',
            'tipo': 99,
            'activo': 1,
          }),
          throwsA(isA<DatabaseException>()),
        );
      } finally {
        await db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 2: Seed Data
  // ───────────────────────────────────────────────────────────────
  group('Seed data', () {
    test('loads exactly 3 hymns', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final result = await db.rawQuery('SELECT COUNT(*) AS cnt FROM Himno');
        expect(result.first['cnt'], 3);
      } finally {
        await db.close();
      }
    });

    test('seed hymns have expected titles, numbers and types', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final hymns = await db.rawQuery(
          'SELECT titulo_principal, numero_oficial, tipo FROM Himno ORDER BY numero_oficial',
        );

        expect(hymns, hasLength(3));
        expect(hymns[0]['titulo_principal'], 'Santo, Santo, Santo');
        expect(hymns[0]['numero_oficial'], 1);
        expect(hymns[0]['tipo'], 1);

        expect(hymns[1]['titulo_principal'], 'Cuán grande es Dios');
        expect(hymns[1]['numero_oficial'], 2);
        expect(hymns[1]['tipo'], 2);

        expect(hymns[2]['titulo_principal'], 'Grande es tu fidelidad');
        expect(hymns[2]['numero_oficial'], 3);
        expect(hymns[2]['tipo'], 1);
      } finally {
        await db.close();
      }
    });

    test('seed has 3 categories', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final cats = await db.rawQuery(
          'SELECT nombre FROM Categoria ORDER BY id',
        );
        expect(cats, hasLength(3));
        expect(cats[0]['nombre'], 'Alabanza');
        expect(cats[1]['nombre'], 'Adoración');
        expect(cats[2]['nombre'], 'Fe');
      } finally {
        await db.close();
      }
    });

    test('each hymn has a country version', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final versions = await db.rawQuery(
          'SELECT himno_id, pais, tonalidad_original FROM Version_Pais ORDER BY himno_id',
        );
        expect(versions, hasLength(3));
        for (final v in versions) {
          expect(v['pais'], 'El Salvador');
        }
        expect(versions[0]['tonalidad_original'], 'G');
        expect(versions[1]['tonalidad_original'], 'C');
        expect(versions[2]['tonalidad_original'], 'C');
      } finally {
        await db.close();
      }
    });

    test('seed creates admin user with correct hash', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final users = await db.rawQuery('SELECT * FROM Usuario WHERE id = 1');
        expect(users, hasLength(1));
        expect(users[0]['username'], 'admin');
        expect(users[0]['rol'], 'Admin');
        expect(users[0]['password_hash'], isNotEmpty);
      } finally {
        await db.close();
      }
    });

    test('seed creates 5 hymn-category associations', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final assocs = await db.rawQuery(
          'SELECT himno_id, categoria_id FROM Himno_Categoria ORDER BY himno_id, categoria_id',
        );
        expect(assocs, hasLength(5));
      } finally {
        await db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 3: CRUD Operations
  // ───────────────────────────────────────────────────────────────
  group('CRUD operations', () {
    test('insert hymn with auto-increment', () async {
      final db = await createEmptyDatabase();
      try {
        final id1 = await db.insert('Himno', {
          'titulo_principal': 'Hymn A',
          'numero_oficial': 100,
          'tipo': 1,
          'activo': 1,
        });
        expect(id1, 1);

        final id2 = await db.insert('Himno', {
          'titulo_principal': 'Hymn B',
          'numero_oficial': 101,
          'tipo': 2,
          'activo': 1,
        });
        expect(id2, 2);
      } finally {
        await db.close();
      }
    });

    test('insert hymn with full relational data', () async {
      final db = await createEmptyDatabase();
      try {
        // 1. Insert hymn
        final himnoId = await db.insert('Himno', {
          'titulo_principal': 'Full Test Hymn',
          'numero_oficial': 10,
          'tipo': 1,
          'activo': 1,
        });

        // 2. Insert category
        await db.insert('Categoria', {'id': 10, 'nombre': 'Test Category'});

        // 3. Insert country version
        final versionId = await db.insert('Version_Pais', {
          'himno_id': himnoId,
          'pais': 'México',
          'tonalidad_original': 'D',
          'activo': 1,
        });

        // 4. Insert stanzas
        await db.insert('Estrofa', {
          'version_pais_id': versionId,
          'tipo': 'Estrofa',
          'orden': 1,
          'contenido': '[D]Primera estrofa de prueba',
        });
        await db.insert('Estrofa', {
          'version_pais_id': versionId,
          'tipo': 'Coro',
          'orden': 2,
          'contenido': '[D]Coro de prueba',
        });

        // 5. Associate category
        await db.insert('Himno_Categoria', {
          'himno_id': himnoId,
          'categoria_id': 10,
        });

        // ─── Verify ───
        final hymns =
            await db.query('Himno', where: 'id = ?', whereArgs: [himnoId]);
        expect(hymns, hasLength(1));
        expect(hymns[0]['titulo_principal'], 'Full Test Hymn');

        final versions = await db.query(
          'Version_Pais',
          where: 'himno_id = ?',
          whereArgs: [himnoId],
        );
        expect(versions, hasLength(1));
        expect(versions[0]['pais'], 'México');

        final stanzas = await db.query(
          'Estrofa',
          where: 'version_pais_id = ?',
          whereArgs: [versionId],
          orderBy: 'orden',
        );
        expect(stanzas, hasLength(2));
        expect(stanzas[0]['tipo'], 'Estrofa');
        expect(stanzas[1]['tipo'], 'Coro');

        final cats = await db.rawQuery('''
          SELECT c.nombre FROM Categoria c
          INNER JOIN Himno_Categoria hc ON hc.categoria_id = c.id
          WHERE hc.himno_id = ?
        ''', [himnoId],);
        expect(cats, hasLength(1));
        expect(cats[0]['nombre'], 'Test Category');
      } finally {
        await db.close();
      }
    });

    test('update hymn fields', () async {
      final db = await createEmptyDatabase();
      try {
        final id = await db.insert('Himno', {
          'titulo_principal': 'Original',
          'numero_oficial': 5,
          'tipo': 1,
          'activo': 1,
        });

        await db.update(
          'Himno',
          {'titulo_principal': 'Updated', 'tipo': 2},
          where: 'id = ?',
          whereArgs: [id],
        );

        final result = await db.query('Himno', where: 'id = ?', whereArgs: [id]);
        expect(result[0]['titulo_principal'], 'Updated');
        expect(result[0]['tipo'], 2);
        expect(result[0]['numero_oficial'], 5); // unchanged
      } finally {
        await db.close();
      }
    });

    test('soft delete (set activo=0)', () async {
      final db = await createEmptyDatabase();
      try {
        final id = await db.insert('Himno', {
          'titulo_principal': 'To Delete',
          'numero_oficial': 99,
          'tipo': 1,
          'activo': 1,
        });

        await db.update(
          'Himno',
          {'activo': 0},
          where: 'id = ?',
          whereArgs: [id],
        );

        final row = await db.query('Himno', where: 'id = ?', whereArgs: [id]);
        expect(row[0]['activo'], 0);

        // Should not appear in active-only queries
        final active = await db.query(
          'Himno',
          where: 'activo = 1 AND id = ?',
          whereArgs: [id],
        );
        expect(active, isEmpty);
      } finally {
        await db.close();
      }
    });

    test('CASCADE delete removes child records', () async {
      final db = await createEmptyDatabase();
      try {
        final himnoId = await db.insert('Himno', {
          'titulo_principal': 'Cascade Parent',
          'tipo': 1,
          'activo': 1,
        });
        final versionId = await db.insert('Version_Pais', {
          'himno_id': himnoId,
          'pais': 'Test',
          'tonalidad_original': 'C',
          'activo': 1,
        });
        await db.insert('Estrofa', {
          'version_pais_id': versionId,
          'tipo': 'Estrofa',
          'orden': 1,
          'contenido': 'Will be cascaded',
        });

        // Delete parent hymn
        await db.delete('Himno', where: 'id = ?', whereArgs: [himnoId]);

        // Version should be gone via CASCADE
        final versions = await db.query(
          'Version_Pais',
          where: 'himno_id = ?',
          whereArgs: [himnoId],
        );
        expect(versions, isEmpty);

        // Estrofa should be gone via CASCADE
        final stanzas = await db.query(
          'Estrofa',
          where: 'version_pais_id = ?',
          whereArgs: [versionId],
        );
        expect(stanzas, isEmpty);
      } finally {
        await db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 4: Search & Filtering
  // ───────────────────────────────────────────────────────────────
  group('Search', () {
    test('search by title returns matching hymns', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final results = await db.rawQuery(
          'SELECT id, titulo_principal FROM Himno WHERE titulo_principal LIKE ? AND activo = 1 ORDER BY numero_oficial',
          ['%Santo%'],
        );
        expect(results, hasLength(1));
        expect(results[0]['titulo_principal'], 'Santo, Santo, Santo');
      } finally {
        await db.close();
      }
    });

    test('partial text search matches multiple hymns', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        // "grande" appears in hymn 2 ("Cuán grande es Dios")
        // and hymn 3 ("Grande es tu fidelidad")
        final results = await db.rawQuery(
          'SELECT id FROM Himno WHERE titulo_principal LIKE ? AND activo = 1 ORDER BY numero_oficial',
          ['%grande%'],
        );
        expect(results, hasLength(2));
      } finally {
        await db.close();
      }
    });

    test('search with no match returns empty list', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final results = await db.rawQuery(
          'SELECT id FROM Himno WHERE titulo_principal LIKE ? AND activo = 1',
          ['%NonExistentHymn%'],
        );
        expect(results, isEmpty);
      } finally {
        await db.close();
      }
    });

    test('search by hymn number', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final results = await db.rawQuery(
          'SELECT id, titulo_principal FROM Himno WHERE CAST(numero_oficial AS TEXT) LIKE ? AND activo = 1',
          ['%2%'],
        );
        expect(results, hasLength(1));
        expect(results[0]['titulo_principal'], 'Cuán grande es Dios');
      } finally {
        await db.close();
      }
    });

    test('filter by type (Oficial = 1)', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final results = await db.rawQuery(
          'SELECT id, tipo FROM Himno WHERE tipo = ? AND activo = 1',
          [1],
        );
        expect(results, hasLength(2)); // himnos 1 and 3
      } finally {
        await db.close();
      }
    });

    test('filter by type (Inspirada = 2)', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final results = await db.rawQuery(
          'SELECT id, titulo_principal FROM Himno WHERE tipo = ? AND activo = 1',
          [2],
        );
        expect(results, hasLength(1));
        expect(results[0]['titulo_principal'], 'Cuán grande es Dios');
      } finally {
        await db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 5: Views
  // ───────────────────────────────────────────────────────────────
  group('Views', () {
    test('v_himno_resumen returns hymn data with country info', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final results = await db.rawQuery(
          'SELECT id, titulo_principal, pais, tonalidad_original FROM v_himno_resumen ORDER BY numero_oficial',
        );
        expect(results, hasLength(3));
        expect(results[0]['pais'], 'El Salvador');
      } finally {
        await db.close();
      }
    });

    test('v_himno_estrofas returns stanza counts', () async {
      final db = await createEmptyDatabase();
      try {
        await seedDatabase(db);

        final results = await db.rawQuery(
          'SELECT himno_id, total_estrofas FROM v_himno_estrofas ORDER BY himno_id',
        );
        expect(results, hasLength(3));
        expect(results[0]['himno_id'], 1);
        expect((results[0]['total_estrofas'] as int), greaterThanOrEqualTo(1));
        expect(results[1]['himno_id'], 2);
        expect((results[1]['total_estrofas'] as int), greaterThanOrEqualTo(1));
        expect(results[2]['himno_id'], 3);
        expect((results[2]['total_estrofas'] as int), greaterThanOrEqualTo(1));
      } finally {
        await db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 6: Constraints & Integrity
  // ───────────────────────────────────────────────────────────────
  group('Constraints & Integrity', () {
    test('Estrofa.tipo CHECK constraint enforces valid types', () async {
      final db = await createEmptyDatabase();
      try {
        final himnoId = await db.insert('Himno', {
          'titulo_principal': 'Check Test',
          'tipo': 1,
          'activo': 1,
        });
        final versionId = await db.insert('Version_Pais', {
          'himno_id': himnoId,
          'pais': 'Test',
          'tonalidad_original': 'C',
          'activo': 1,
        });

        // Valid
        await db.insert('Estrofa', {
          'version_pais_id': versionId,
          'tipo': 'Intro',
          'orden': 1,
          'contenido': 'Valid intro',
        });

        // Invalid type
        expect(
          () => db.insert('Estrofa', {
            'version_pais_id': versionId,
            'tipo': 'InvalidType',
            'orden': 2,
            'contenido': 'Should fail',
          }),
          throwsA(isA<DatabaseException>()),
        );
      } finally {
        await db.close();
      }
    });

    test('Fondo_Pantalla.tipo CHECK constraint', () async {
      final db = await createEmptyDatabase();
      try {
        await db.insert('Fondo_Pantalla', {
          'nombre': 'Valid',
          'tipo': 'imagen',
          'activo': 1,
        });

        expect(
          () => db.insert('Fondo_Pantalla', {
            'nombre': 'Invalid',
            'tipo': 'gif_animado',
            'activo': 1,
          }),
          throwsA(isA<DatabaseException>()),
        );

        // 'video' ya no es un tipo válido
        expect(
          () => db.insert('Fondo_Pantalla', {
            'nombre': 'Video Legacy',
            'tipo': 'video',
            'activo': 1,
          }),
          throwsA(isA<DatabaseException>()),
        );
      } finally {
        await db.close();
      }
    });

    test('Usuario.username UNIQUE constraint', () async {
      final db = await createEmptyDatabase();
      try {
        await db.insert('Usuario', {
          'username': 'unique_user',
          'password_hash': 'hash1',
          'nombre': 'User 1',
          'rol': 'Musico',
        });

        expect(
          () => db.insert('Usuario', {
            'username': 'unique_user',
            'password_hash': 'hash2',
            'nombre': 'User 2',
            'rol': 'Musico',
          }),
          throwsA(isA<DatabaseException>()),
        );
      } finally {
        await db.close();
      }
    });

    test('Categoria.nombre UNIQUE constraint', () async {
      final db = await createEmptyDatabase();
      try {
        await db.insert('Categoria', {'nombre': 'Unique'});

        expect(
          () => db.insert('Categoria', {'nombre': 'Unique'}),
          throwsA(isA<DatabaseException>()),
        );
      } finally {
        await db.close();
      }
    });

    test('Usuario.rol CHECK constraint (Admin, Musico, Visualizador)', () async {
      final db = await createEmptyDatabase();
      try {
        await db.insert('Usuario', {
          'username': 'admin_role',
          'password_hash': 'h',
          'nombre': 'Admin',
          'rol': 'Admin',
        });
        await db.insert('Usuario', {
          'username': 'musico_role',
          'password_hash': 'h',
          'nombre': 'Musician',
          'rol': 'Musico',
        });
        await db.insert('Usuario', {
          'username': 'visual_role',
          'password_hash': 'h',
          'nombre': 'Viewer',
          'rol': 'Visualizador',
        });

        expect(
          () => db.insert('Usuario', {
            'username': 'bad_role',
            'password_hash': 'h',
            'nombre': 'Bad',
            'rol': 'SuperAdmin',
          }),
          throwsA(isA<DatabaseException>()),
        );
      } finally {
        await db.close();
      }
    });
  });
}
