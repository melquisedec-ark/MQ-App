import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/core/enums/estrofa_tipo.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/core/errors/failures.dart';

import 'helpers/db_test_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() => cleanupTestDatabases());

  // ───────────────────────────────────────────────────────────────
  // Grupo 1: Búsqueda (searchHymns)
  // ───────────────────────────────────────────────────────────────
  group('searchHymns', () {
    test('returns all 3 active hymns when query is empty', () async {
      final bundle = await createRepoWithSeed();
      try {
        final results = await bundle.repo.searchHymns('');
        expect(results, hasLength(3));
      } finally {
        await bundle.db.close();
      }
    });

    test('filters by title text', () async {
      final bundle = await createRepoWithSeed();
      try {
        final results = await bundle.repo.searchHymns('Santo');
        expect(results, hasLength(1));
        expect(results[0].titulo, 'Santo, Santo, Santo');
      } finally {
        await bundle.db.close();
      }
    });

    test('partial text search returns multiple results', () async {
      final bundle = await createRepoWithSeed();
      try {
        // "grande" matches himnos 2 and 3
        final results = await bundle.repo.searchHymns('grande');
        expect(results, hasLength(2));
      } finally {
        await bundle.db.close();
      }
    });

    test('filters by hymn type (Oficial)', () async {
      final bundle = await createRepoWithSeed();
      try {
        final results = await bundle.repo.searchHymns('',
            tipo: HimnoTipo.oficial,);
        expect(results, hasLength(2));
        expect(results.every((h) => h.tipo == HimnoTipo.oficial), isTrue);
      } finally {
        await bundle.db.close();
      }
    });

    test('filters by hymn type (Inspirada)', () async {
      final bundle = await createRepoWithSeed();
      try {
        final results = await bundle.repo.searchHymns('',
            tipo: HimnoTipo.inspirada,);
        expect(results, hasLength(1));
        expect(results[0].tipo, HimnoTipo.inspirada);
      } finally {
        await bundle.db.close();
      }
    });

    test('combines text query and type filter', () async {
      final bundle = await createRepoWithSeed();
      try {
        // "Santo" + Oficial → 1 result
        final results = await bundle.repo.searchHymns('Santo',
            tipo: HimnoTipo.oficial,);
        expect(results, hasLength(1));
        expect(results[0].titulo, 'Santo, Santo, Santo');
      } finally {
        await bundle.db.close();
      }
    });

    test('returns empty list when no match', () async {
      final bundle = await createRepoWithSeed();
      try {
        final results = await bundle.repo.searchHymns('xyzNotFound');
        expect(results, isEmpty);
      } finally {
        await bundle.db.close();
      }
    });

    test('excludes soft-deleted hymns', () async {
      final bundle = await createRepoWithSeed();
      try {
        await bundle.repo.deleteHymn(2);

        final results = await bundle.repo.searchHymns('');
        expect(results, hasLength(2));
        expect(results.any((h) => h.id == 2), isFalse);
      } finally {
        await bundle.db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 2: Obtener himno por ID
  // ───────────────────────────────────────────────────────────────
  group('getHymnById', () {
    test('returns complete hymn with versions, stanzas and categories',
        () async {
      final bundle = await createRepoWithSeed();
      try {
        final himno = await bundle.repo.getHymnById(1);

        expect(himno.id, 1);
        expect(himno.titulo, 'Santo, Santo, Santo');
        expect(himno.numero, 1);
        expect(himno.tipo, HimnoTipo.oficial);
        expect(himno.activo, isTrue);

        // Versions
        expect(himno.versiones, hasLength(1));
        expect(himno.versiones[0].paisNombre, 'El Salvador');
        expect(himno.versiones[0].tonalidadOriginal, 'G');

        // Stanzas within version
        expect(himno.versiones[0].estrofas, hasLength(2));
        expect(himno.versiones[0].estrofas[0].orden, 1);
        expect(himno.versiones[0].estrofas[0].tipo, EstrofaTipo.estrofa);

        // Categories
        expect(himno.categorias, isNotNull);
        expect(himno.categorias!, hasLength(2));
        final catNames = himno.categorias!.map((c) => c.nombre).toList();
        expect(catNames, contains('Alabanza'));
        expect(catNames, contains('Adoración'));
      } finally {
        await bundle.db.close();
      }
    });

    test('throws NotFoundFailure for non-existent ID', () async {
      final bundle = await createRepoWithSeed();
      try {
        await expectLater(
          bundle.repo.getHymnById(999),
          throwsA(isA<NotFoundFailure>()),
        );
      } finally {
        await bundle.db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 3: Estrofas
  // ───────────────────────────────────────────────────────────────
  group('getStanzas', () {
    test('returns stanzas ordered by "orden"', () async {
      final bundle = await createRepoWithSeed();
      try {
        final stanzas = await bundle.repo.getStanzas(1);
        expect(stanzas, hasLength(2));
        expect(stanzas[0].orden, 1);
        expect(stanzas[1].orden, 2);
        expect(stanzas[0].versionPaisId, 1);
        expect(stanzas[0].tipo, EstrofaTipo.estrofa);
      } finally {
        await bundle.db.close();
      }
    });

    test('returns empty list for version without stanzas', () async {
      final bundle = await createRepoWithSeed();
      try {
        final db = bundle.db;
        await db.insert('Himno', {
          'id': 99,
          'titulo_principal': 'Empty Hymn',
          'tipo': 1,
          'activo': 1,
        });
        final vId = await db.insert('Version_Pais', {
          'himno_id': 99,
          'pais': 'Test Land',
          'tonalidad_original': 'C',
          'activo': 1,
        });

        final stanzas = await bundle.repo.getStanzas(vId);
        expect(stanzas, isEmpty);
      } finally {
        await bundle.db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 4: Categorías
  // ───────────────────────────────────────────────────────────────
  group('Categories', () {
    test('getCategories returns all categories alphabetically', () async {
      final bundle = await createRepoWithSeed();
      try {
        final cats = await bundle.repo.getCategories();
        expect(cats, hasLength(3));
        expect(cats[0].nombre, 'Adoración');
        expect(cats[1].nombre, 'Alabanza');
        expect(cats[2].nombre, 'Fe');
      } finally {
        await bundle.db.close();
      }
    });

    test('getAllCategorias returns same data as getCategories', () async {
      final bundle = await createRepoWithSeed();
      try {
        final cats1 = await bundle.repo.getCategories();
        final cats2 = await bundle.repo.getAllCategorias();
        expect(cats1, equals(cats2));
      } finally {
        await bundle.db.close();
      }
    });

    test('getHymnsByCategory returns hymns in that category', () async {
      final bundle = await createRepoWithSeed();
      try {
        // Categoría 1 = Alabanza → himnos 1 and 2
        final hymns = await bundle.repo.getHymnsByCategory(1);
        expect(hymns, hasLength(2));
        expect(hymns.any((h) => h.id == 1), isTrue);
        expect(hymns.any((h) => h.id == 2), isTrue);
      } finally {
        await bundle.db.close();
      }
    });

    test('getHymnsByCategory returns empty for unused category', () async {
      final bundle = await createRepoWithSeed();
      try {
        final db = bundle.db;
        await db.insert('Categoria', {'id': 99, 'nombre': 'Unused'});

        final hymns = await bundle.repo.getHymnsByCategory(99);
        expect(hymns, isEmpty);
      } finally {
        await bundle.db.close();
      }
    });

    test('createCategoria and retrieve it', () async {
      final bundle = await createRepoEmpty();
      try {
        final cat = await bundle.repo.createCategoria('Nueva Categoría');
        expect(cat.id, greaterThan(0));
        expect(cat.nombre, 'Nueva Categoría');

        final cats = await bundle.repo.getCategories();
        expect(cats, hasLength(1));
        expect(cats[0].nombre, 'Nueva Categoría');
      } finally {
        await bundle.db.close();
      }
    });

    test('deleteCategoria removes it', () async {
      final bundle = await createRepoWithSeed();
      try {
        await bundle.repo.deleteCategoria(3); // Fe
        final cats = await bundle.repo.getCategories();
        expect(cats, hasLength(2));
        expect(cats.any((c) => c.id == 3), isFalse);
      } finally {
        await bundle.db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 5: CRUD completo de himnos
  // ───────────────────────────────────────────────────────────────
  group('createHymn', () {
    test('creates hymn with versions, stanzas and categories', () async {
      final bundle = await createRepoEmpty();
      try {
        // Prepare categories first
        await bundle.repo.createCategoria('Alabanza');
        await bundle.repo.createCategoria('Adoración');

        const himno = Himno(
          id: 0,
          titulo: 'Nuevo Himno de Prueba',
          numero: 100,
          tipo: HimnoTipo.oficial,
          activo: true,
        );

        final versiones = [
          {'pais': 'El Salvador', 'tonalidad_original': 'D'},
          {'pais': 'Guatemala', 'tonalidad_original': 'C'},
        ];

        final estrofas = [
          {
            'version_idx': 0,
            'tipo': 'Estrofa',
            'orden': 1,
            'contenido': '[D]Primera estrofa',
          },
          {
            'version_idx': 0,
            'tipo': 'Coro',
            'orden': 2,
            'contenido': '[D]Coro de prueba',
          },
          {
            'version_idx': 1,
            'tipo': 'Estrofa',
            'orden': 1,
            'contenido': '[C]Versión Guatemala',
          },
        ];

        final himnoId = await bundle.repo.createHymn(
          himno,
          versiones,
          estrofas,
          [1, 2], // categorías Alabanza y Adoración
        );

        expect(himnoId, greaterThan(0));

        // Retrieve and verify
        final created = await bundle.repo.getHymnById(himnoId);
        expect(created.titulo, 'Nuevo Himno de Prueba');
        expect(created.numero, 100);
        expect(created.tipo, HimnoTipo.oficial);
        expect(created.versiones, hasLength(2));

        final vEs =
            created.versiones.firstWhere((v) => v.paisNombre == 'El Salvador');
        expect(vEs.tonalidadOriginal, 'D');
        expect(vEs.estrofas, hasLength(2));

        final vGt =
            created.versiones.firstWhere((v) => v.paisNombre == 'Guatemala');
        expect(vGt.tonalidadOriginal, 'C');
        expect(vGt.estrofas, hasLength(1));

        expect(created.categorias, hasLength(2));
      } finally {
        await bundle.db.close();
      }
    });
  });

  group('updateHymn', () {
    test('updates hymn data and replaces children', () async {
      final bundle = await createRepoWithSeed();
      try {
        // Update himno 1
        const himno = Himno(
          id: 1,
          titulo: 'Santo, Santo, Santo (Editado)',
          numero: 10,
          tipo: HimnoTipo.convencion,
          activo: true,
        );

        final versiones = [
          {'pais': 'México', 'tonalidad_original': 'A'},
        ];

        final estrofas = [
          {
            'version_idx': 0,
            'tipo': 'Intro',
            'orden': 1,
            'contenido': '[A]Nueva intro',
          },
          {
            'version_idx': 0,
            'tipo': 'Estrofa',
            'orden': 2,
            'contenido': '[A]Estrofa editada',
          },
        ];

        await bundle.repo.updateHymn(himno, versiones, estrofas, [1, 3]);

        // Verify
        final updated = await bundle.repo.getHymnById(1);
        expect(updated.titulo, 'Santo, Santo, Santo (Editado)');
        expect(updated.numero, 10);
        expect(updated.tipo, HimnoTipo.convencion);

        // Versions replaced
        expect(updated.versiones, hasLength(1));
        expect(updated.versiones[0].paisNombre, 'México');
        expect(updated.versiones[0].estrofas, hasLength(2));

        // Categories replaced
        expect(updated.categorias, hasLength(2));
        final catNames = updated.categorias!.map((c) => c.nombre).toList();
        expect(catNames, contains('Alabanza'));
        expect(catNames, contains('Fe'));
      } finally {
        await bundle.db.close();
      }
    });
  });

  group('deleteHymn', () {
    test('soft-deletes hymn (activo=0)', () async {
      final bundle = await createRepoWithSeed();
      try {
        await bundle.repo.deleteHymn(1);

        // Should not appear in search
        final results = await bundle.repo.searchHymns('Santo');
        expect(results, isEmpty);

        // Should throw NotFoundFailure on direct get
        await expectLater(
          bundle.repo.getHymnById(1),
          throwsA(isA<NotFoundFailure>()),
        );
      } finally {
        await bundle.db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 6: Referencias
  // ───────────────────────────────────────────────────────────────
  group('hymnHasReferences', () {
    test('returns false for hymn with no references', () async {
      final bundle = await createRepoWithSeed();
      try {
        final hasRefs = await bundle.repo.hymnHasReferences(1);
        expect(hasRefs, isFalse);
      } finally {
        await bundle.db.close();
      }
    });

    test('returns true when hymn has Pista_Audio', () async {
      final bundle = await createRepoWithSeed();
      try {
        await bundle.db.insert('Pista_Audio', {
          'himno_id': 1,
          'ruta_archivo': '/test/audio.mp3',
          'descripcion': 'Test track',
          'formato': 'mp3',
        });

        final hasRefs = await bundle.repo.hymnHasReferences(1);
        expect(hasRefs, isTrue);
      } finally {
        await bundle.db.close();
      }
    });

    test('returns true when hymn has Arreglo_Musical', () async {
      final bundle = await createRepoWithSeed();
      try {
        await bundle.db.insert('Arreglo_Musical', {
          'version_pais_id': 1,
          'usuario_id': 1,
          'nombre_arreglo': 'Test Arrangement',
          'tonalidad_base': 'C',
        });

        final hasRefs = await bundle.repo.hymnHasReferences(1);
        expect(hasRefs, isTrue);
      } finally {
        await bundle.db.close();
      }
    });

    test('returns true when hymn has Historial_Reproduccion', () async {
      final bundle = await createRepoWithSeed();
      try {
        await bundle.db.insert('Historial_Reproduccion', {
          'himno_id': 1,
        });

        final hasRefs = await bundle.repo.hymnHasReferences(1);
        expect(hasRefs, isTrue);
      } finally {
        await bundle.db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 7: Arreglos musicales
  // ───────────────────────────────────────────────────────────────
  group('createArrangement', () {
    test('creates arrangement with stanzas', () async {
      final bundle = await createRepoWithSeed();
      try {
        final arrangementId = await bundle.repo.createArrangement(
          versionPaisId: 1,
          usuarioId: 1,
          nombreArreglo: 'Mi Arreglo Personal',
          tonalidadBase: 'A',
          estrofas: [
            (tipo: 'Estrofa', orden: 1, contenido: '[A]Versión en La Mayor'),
            (tipo: 'Coro', orden: 2, contenido: '[A]Coro en La Mayor'),
          ],
        );

        expect(arrangementId, greaterThan(0));

        // Verify in DB directly
        final arrangements = await bundle.db.query(
          'Arreglo_Musical',
          where: 'id = ?',
          whereArgs: [arrangementId],
        );
        expect(arrangements, hasLength(1));
        expect(arrangements[0]['nombre_arreglo'], 'Mi Arreglo Personal');
        expect(arrangements[0]['tonalidad_base'], 'A');

        final stanzas = await bundle.db.query(
          'Estrofa_Arreglo',
          where: 'arreglo_musical_id = ?',
          whereArgs: [arrangementId],
          orderBy: 'orden',
        );
        expect(stanzas, hasLength(2));
        expect(stanzas[0]['tipo'], 'Estrofa');
        expect(stanzas[1]['tipo'], 'Coro');
      } finally {
        await bundle.db.close();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Grupo 8: Manejo de errores
  // ───────────────────────────────────────────────────────────────
  group('Error handling', () {
    test('searchHymns returns DatabaseFailure on DB error', () async {
      final bundle = await createRepoWithSeed();
      // Close the DB to simulate an error
      await bundle.db.close();

      expect(
        () => bundle.repo.searchHymns('test'),
        throwsA(isA<DatabaseFailure>()),
      );
    });

    test('getHymnById throws NotFoundFailure for soft-deleted hymn',
        () async {
      final bundle = await createRepoWithSeed();
      try {
        await bundle.repo.deleteHymn(3);

        await expectLater(
          bundle.repo.getHymnById(3),
          throwsA(isA<NotFoundFailure>()),
        );
      } finally {
        await bundle.db.close();
      }
    });
  });
}
