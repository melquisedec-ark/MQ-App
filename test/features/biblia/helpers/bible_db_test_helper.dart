import 'dart:ffi';
import 'dart:io';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_search_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/cross_referencias_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/historial_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/notas_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

/// Inicializa FFI una vez por proceso de test.
///
/// Workaround: en Linux, el sistema tiene `libsqlite3.so.0` pero no
/// `libsqlite3.so` (symlink). El `sqlite3` FFI busca el primero sin
/// el sufijo de versión. Usamos `createDatabaseFactoryFfi` con un
/// `ffiInit` callback que se ejecuta en el isolate de FFI y aplica
/// el override. Esto es solo para el entorno de tests; en runtime
/// la app usa `sqlite3_flutter_libs` que bundlea su propia lib.
///
/// IMPORTANTE: la función `ffiInit` DEBE ser top-level (o static)
/// porque sqflite_common_ffi la envía a través de un Isolate, y los
/// closures locales no se pueden serializar.
bool _ffiTestInit = false;
void initBibleTestFfi() {
  if (_ffiTestInit) return;
  _ffiTestInit = true;

  // Crea un factory con el callback de init; asigna como `databaseFactory`
  // global para que las llamadas `db.query(...)` lo usen.
  // Usamos `noIsolate: true` para que el FFI corra en el isolate principal
  // (el override se aplica directamente sin necesidad de enviar callbacks
  // a través de un isolate).
  if (Platform.isLinux) {
    open.overrideFor(
      OperatingSystem.linux,
      _openLibsqliteLinux,
    );
  }
  databaseFactory = createDatabaseFactoryFfi(noIsolate: true);
}

/// Top-level `OpenLibrary` para Linux. DEBE ser top-level porque
/// `sqlite3` la invoca en el isolate de FFI.
DynamicLibrary _openLibsqliteLinux() {
  return DynamicLibrary.open('libsqlite3.so.0');
}

/// Set para llevar registro de directorios temporales creados para limpieza.
final Set<Directory> _tempDirs = {};

/// Crea una base de datos aislada con el esquema completo de Biblia
/// (igual a `BibleDatabaseHelper._onCreate`).
///
/// Cada invocación crea un directorio temporal único para evitar que
/// sqflite_common_ffi cachee y comparta la BD entre tests.
Future<Database> createBibleTestDb() async {
  final dir = Directory.systemTemp.createTempSync('biblia_test_');
  _tempDirs.add(dir);
  final dbPath = '${dir.path}/test.db';
  // Usa el `databaseFactory` global (configurado por `initBibleTestFfi`
  // con el override de libsqlite3.so.0 y `noIsolate: true`).
  final db = await databaseFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: BibleDatabaseHelper.SCHEMA_VERSION,
      onCreate: (db, version) async {
        await _applyBibleSchema(db);
      },
    ),
  );
  await db.execute('PRAGMA foreign_keys = ON');
  return db;
}

/// Aplica el DDL de Biblia directamente a una BD abierta.
/// Es una copia del DDL de `BibleDatabaseHelper._onCreate` para uso de
/// tests. Mantener sincronizado manualmente con el helper.
Future<void> _applyBibleSchema(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON;');

  // version
  await db.execute('''
    CREATE TABLE IF NOT EXISTS version (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL UNIQUE,
      abreviatura TEXT NOT NULL UNIQUE,
      idioma TEXT NOT NULL,
      descripcion TEXT,
      anio_publicacion INTEGER,
      es_dominio_publico INTEGER NOT NULL DEFAULT 1 CHECK(es_dominio_publico IN (0, 1)),
      activa INTEGER NOT NULL DEFAULT 1 CHECK(activa IN (0, 1))
    );
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_version_activa ON version(activa);');

  // libro
  await db.execute('''
    CREATE TABLE IF NOT EXISTS libro (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      version_id INTEGER NOT NULL,
      nombre TEXT NOT NULL,
      abreviatura TEXT NOT NULL,
      testamento TEXT NOT NULL CHECK(testamento IN ('AT', 'NT')),
      numero INTEGER NOT NULL CHECK(numero BETWEEN 1 AND 66),
      total_capitulos INTEGER NOT NULL CHECK(total_capitulos > 0),
      FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
      UNIQUE (version_id, numero)
    );
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_libro_version ON libro(version_id);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_libro_testamento ON libro(testamento);');

  // capitulo
  await db.execute('''
    CREATE TABLE IF NOT EXISTS capitulo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      libro_id INTEGER NOT NULL,
      numero INTEGER NOT NULL CHECK(numero > 0),
      total_versiculos INTEGER NOT NULL CHECK(total_versiculos >= 0),
      FOREIGN KEY (libro_id) REFERENCES libro(id) ON DELETE CASCADE,
      UNIQUE (libro_id, numero)
    );
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_capitulo_libro ON capitulo(libro_id);');

  // versiculo
  await db.execute('''
    CREATE TABLE IF NOT EXISTS versiculo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      capitulo_id INTEGER NOT NULL,
      numero INTEGER NOT NULL CHECK(numero > 0),
      texto TEXT NOT NULL,
      FOREIGN KEY (capitulo_id) REFERENCES capitulo(id) ON DELETE CASCADE,
      UNIQUE (capitulo_id, numero)
    );
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_versiculo_capitulo ON versiculo(capitulo_id);');

  // versiculo_fts (FTS5)
  await db.execute('''
    CREATE VIRTUAL TABLE IF NOT EXISTS versiculo_fts USING fts5(
      texto,
      content='versiculo',
      content_rowid='id',
      tokenize='unicode61 remove_diacritics 2'
    );
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS versiculo_ai AFTER INSERT ON versiculo BEGIN
      INSERT INTO versiculo_fts(rowid, texto) VALUES (new.id, new.texto);
    END;
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS versiculo_ad AFTER DELETE ON versiculo BEGIN
      INSERT INTO versiculo_fts(versiculo_fts, rowid, texto) VALUES('delete', old.id, old.texto);
    END;
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS versiculo_au AFTER UPDATE ON versiculo BEGIN
      INSERT INTO versiculo_fts(versiculo_fts, rowid, texto) VALUES('delete', old.id, old.texto);
      INSERT INTO versiculo_fts(rowid, texto) VALUES (new.id, new.texto);
    END;
  ''');

  // favorito_versiculo
  await db.execute('''
    CREATE TABLE IF NOT EXISTS favorito_versiculo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      version_id INTEGER NOT NULL,
      libro_id INTEGER NOT NULL,
      capitulo INTEGER NOT NULL CHECK(capitulo > 0),
      numero INTEGER NOT NULL CHECK(numero > 0),
      fecha_agregado INTEGER NOT NULL,
      FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
      FOREIGN KEY (libro_id) REFERENCES libro(id) ON DELETE CASCADE,
      UNIQUE (version_id, libro_id, capitulo, numero)
    );
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_favorito_lookup ON favorito_versiculo(version_id, libro_id, capitulo, numero);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_favorito_fecha ON favorito_versiculo(fecha_agregado DESC);');

  // nota
  await db.execute('''
    CREATE TABLE IF NOT EXISTS nota (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      version_id INTEGER NOT NULL,
      libro_id INTEGER NOT NULL,
      capitulo INTEGER NOT NULL CHECK(capitulo > 0),
      numero INTEGER NOT NULL CHECK(numero > 0),
      contenido TEXT NOT NULL,
      color TEXT NOT NULL CHECK(color IN ('amarillo', 'verde', 'azul', 'ninguno')),
      fecha_creacion INTEGER NOT NULL,
      fecha_modificacion INTEGER NOT NULL,
      FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
      FOREIGN KEY (libro_id) REFERENCES libro(id) ON DELETE CASCADE,
      UNIQUE (version_id, libro_id, capitulo, numero)
    );
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_nota_lookup ON nota(version_id, libro_id, capitulo, numero);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_nota_fecha_mod ON nota(fecha_modificacion DESC);');

  // Triggers de validación
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS favorito_versiculo_bi
    BEFORE INSERT ON favorito_versiculo
    FOR EACH ROW
    WHEN NOT EXISTS (
      SELECT 1 FROM libro
      WHERE libro.id = NEW.libro_id
        AND libro.version_id = NEW.version_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'favorito_versiculo: libro_id no pertenece a version_id');
    END;
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS favorito_versiculo_bu
    BEFORE UPDATE ON favorito_versiculo
    FOR EACH ROW
    WHEN NOT EXISTS (
      SELECT 1 FROM libro
      WHERE libro.id = NEW.libro_id
        AND libro.version_id = NEW.version_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'favorito_versiculo: libro_id no pertenece a version_id');
    END;
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS nota_bi
    BEFORE INSERT ON nota
    FOR EACH ROW
    WHEN NOT EXISTS (
      SELECT 1 FROM libro
      WHERE libro.id = NEW.libro_id
        AND libro.version_id = NEW.version_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'nota: libro_id no pertenece a version_id');
    END;
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS nota_bu
    BEFORE UPDATE ON nota
    FOR EACH ROW
    WHEN NOT EXISTS (
      SELECT 1 FROM libro
      WHERE libro.id = NEW.libro_id
        AND libro.version_id = NEW.version_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'nota: libro_id no pertenece a version_id');
    END;
  ''');

  // historial_versiculo
  await db.execute('''
    CREATE TABLE IF NOT EXISTS historial_versiculo (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      version_id INTEGER NOT NULL,
      libro_id INTEGER NOT NULL,
      capitulo INTEGER NOT NULL CHECK(capitulo > 0),
      numero INTEGER NOT NULL CHECK(numero > 0),
      fecha_lectura INTEGER NOT NULL,
      FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
      FOREIGN KEY (libro_id) REFERENCES libro(id) ON DELETE CASCADE
    );
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_historial_fecha ON historial_versiculo(fecha_lectura DESC);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_historial_lookup ON historial_versiculo(version_id, libro_id, capitulo, numero);');

  // config
  await db.execute('''
    CREATE TABLE IF NOT EXISTS config (
      clave TEXT PRIMARY KEY,
      valor TEXT NOT NULL,
      fecha_modificacion INTEGER NOT NULL
    );
  ''');

  // schema_version
  await db.execute('''
    CREATE TABLE IF NOT EXISTS schema_version (
      version INTEGER PRIMARY KEY,
      descripcion TEXT NOT NULL,
      fecha_aplicacion INTEGER NOT NULL
    );
  ''');

  // cross_referencia (migración 004) — copia del DDL de
  // BibleDatabaseHelper._onCreate. Mantener sincronizado manualmente.
  await db.execute('''
    CREATE TABLE IF NOT EXISTS cross_referencia (
      id                  INTEGER PRIMARY KEY AUTOINCREMENT,
      version_id          INTEGER NOT NULL,
      from_libro_id       INTEGER NOT NULL,
      from_capitulo       INTEGER NOT NULL CHECK(from_capitulo > 0),
      from_versiculo      INTEGER NOT NULL CHECK(from_versiculo > 0),
      to_libro_id         INTEGER NOT NULL,
      to_capitulo         INTEGER NOT NULL CHECK(to_capitulo > 0),
      to_versiculo_inicio INTEGER NOT NULL CHECK(to_versiculo_inicio > 0),
      to_versiculo_fin    INTEGER NOT NULL CHECK(to_versiculo_fin >= to_versiculo_inicio),
      votos               INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (version_id)    REFERENCES version(id) ON DELETE CASCADE,
      FOREIGN KEY (from_libro_id) REFERENCES libro(id)   ON DELETE CASCADE,
      FOREIGN KEY (to_libro_id)   REFERENCES libro(id)   ON DELETE CASCADE
    );
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_cross_ref_from '
    'ON cross_referencia(version_id, from_libro_id, from_capitulo, from_versiculo);',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_cross_ref_to '
    'ON cross_referencia(version_id, to_libro_id, to_capitulo, to_versiculo_inicio);',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_cross_ref_votos '
    'ON cross_referencia(version_id, votos DESC);',
  );

  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS cross_referencia_bi
    BEFORE INSERT ON cross_referencia
    FOR EACH ROW
    WHEN NOT EXISTS (
      SELECT 1 FROM libro
      WHERE libro.id = NEW.from_libro_id
        AND libro.version_id = NEW.version_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'cross_referencia: from_libro_id no pertenece a version_id');
    END;
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS cross_referencia_bi_to
    BEFORE INSERT ON cross_referencia
    FOR EACH ROW
    WHEN NOT EXISTS (
      SELECT 1 FROM libro
      WHERE libro.id = NEW.to_libro_id
        AND libro.version_id = NEW.version_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'cross_referencia: to_libro_id no pertenece a version_id');
    END;
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS cross_referencia_bu
    BEFORE UPDATE ON cross_referencia
    FOR EACH ROW
    WHEN NOT EXISTS (
      SELECT 1 FROM libro
      WHERE libro.id = NEW.from_libro_id
        AND libro.version_id = NEW.version_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'cross_referencia: from_libro_id no pertenece a version_id');
    END;
  ''');
  await db.execute('''
    CREATE TRIGGER IF NOT EXISTS cross_referencia_bu_to
    BEFORE UPDATE ON cross_referencia
    FOR EACH ROW
    WHEN NOT EXISTS (
      SELECT 1 FROM libro
      WHERE libro.id = NEW.to_libro_id
        AND libro.version_id = NEW.version_id
    )
    BEGIN
      SELECT RAISE(ABORT, 'cross_referencia: to_libro_id no pertenece a version_id');
    END;
  ''');
}

/// Datos de prueba mínimos: 2 versiones, 4 libros, 6 capítulos,
/// ~10 versículos. Suficiente para tests unitarios.
Future<void> seedBibleTestDb(Database db) async {
  // Versiones
  await db.insert('version', {
    'id': 1,
    'nombre': 'Reina Valera 1909',
    'abreviatura': 'RVR1909',
    'idioma': 'es',
    'descripcion': 'Versión de dominio público',
    'anio_publicacion': 1909,
    'es_dominio_publico': 1,
    'activa': 1,
  });
  await db.insert('version', {
    'id': 2,
    'nombre': 'Reina Valera 1569',
    'abreviatura': 'RVR1569',
    'idioma': 'es',
    'descripcion': 'Biblia del Oso',
    'anio_publicacion': 1569,
    'es_dominio_publico': 1,
    'activa': 1,
  });

  // Libros (Génesis=1, Salmos=19, Mateo=40, Juan=43, 1 Juan=62)
  await db.insert('libro', {
    'id': 1, 'version_id': 1, 'nombre': 'Génesis', 'abreviatura': 'Gn',
    'testamento': 'AT', 'numero': 1, 'total_capitulos': 50,
  });
  await db.insert('libro', {
    'id': 2, 'version_id': 1, 'nombre': 'Éxodo', 'abreviatura': 'Ex',
    'testamento': 'AT', 'numero': 2, 'total_capitulos': 40,
  });
  await db.insert('libro', {
    'id': 3, 'version_id': 1, 'nombre': 'Salmos', 'abreviatura': 'Sal',
    'testamento': 'AT', 'numero': 19, 'total_capitulos': 150,
  });
  await db.insert('libro', {
    'id': 4, 'version_id': 1, 'nombre': 'Juan', 'abreviatura': 'Jn',
    'testamento': 'NT', 'numero': 43, 'total_capitulos': 21,
  });
  // 1 Juan canónico (libro_id=62 en orden canónico, pero como solo es
  // para tests, lo creamos con id=6 — el orden canónico no se usa en
  // los cross-refs, solo libro.id).
  await db.insert('libro', {
    'id': 6, 'version_id': 1, 'nombre': '1 Juan', 'abreviatura': '1Jn',
    'testamento': 'NT', 'numero': 62, 'total_capitulos': 5,
  });
  // Libro "fantasma" de la versión 2 para test cross-version
  await db.insert('libro', {
    'id': 5, 'version_id': 2, 'nombre': 'Juan', 'abreviatura': 'Jn',
    'testamento': 'NT', 'numero': 43, 'total_capitulos': 21,
  });

  // Capítulos
  await db.insert('capitulo', {
    'id': 1, 'libro_id': 1, 'numero': 1, 'total_versiculos': 31,
  });
  await db.insert('capitulo', {
    'id': 2, 'libro_id': 1, 'numero': 2, 'total_versiculos': 25,
  });
  await db.insert('capitulo', {
    'id': 3, 'libro_id': 4, 'numero': 3, 'total_versiculos': 36,
  });
  await db.insert('capitulo', {
    'id': 4, 'libro_id': 3, 'numero': 23, 'total_versiculos': 6,
  });
  await db.insert('capitulo', {
    'id': 5, 'libro_id': 5, 'numero': 3, 'total_versiculos': 36,
  });
  // 1 Juan cap 4 (libro_id=6) — necesario para el rango destino
  await db.insert('capitulo', {
    'id': 6, 'libro_id': 6, 'numero': 4, 'total_versiculos': 21,
  });

  // Versículos (Génesis 1:1, 1:2; Juan 3:16, 3:17, 3:18; Salmos 23:1-6)
  await db.insert('versiculo', {
    'capitulo_id': 1, 'numero': 1,
    'texto': 'En el principio creó Dios los cielos y la tierra.',
  });
  await db.insert('versiculo', {
    'capitulo_id': 1, 'numero': 2,
    'texto': 'Y la tierra estaba desordenada y vacía, y las tinieblas '
        'estaban sobre la faz del abismo, y el Espíritu de Dios se movía '
        'sobre la faz de las aguas.',
  });
  await db.insert('versiculo', {
    'capitulo_id': 3, 'numero': 16,
    'texto': 'Porque de tal manera amó Dios al mundo, que ha dado a su '
        'Hijo unigénito, para que todo aquel que en él cree, no se pierda, '
        'mas tenga vida eterna.',
  });
  await db.insert('versiculo', {
    'capitulo_id': 3, 'numero': 17,
    'texto': 'Porque no envió Dios a su Hijo al mundo para condenar al '
        'mundo, sino para que el mundo sea salvo por él.',
  });
  await db.insert('versiculo', {
    'capitulo_id': 3, 'numero': 18,
    'texto': 'El que en él cree, no es condenado; pero el que no cree, '
        'ya ha sido condenado, porque no ha creído en el nombre del '
        'unigénito Hijo de Dios.',
  });
  await db.insert('versiculo', {
    'capitulo_id': 4, 'numero': 1,
    'texto': 'Jehová es mi pastor; nada me faltará.',
  });
  await db.insert('versiculo', {
    'capitulo_id': 4, 'numero': 2,
    'texto': 'En lugares de delicados pastos me hará descansar; junto a '
        'aguas de reposo me pastoreará.',
  });
}

/// Inserta un set mínimo de cross-references de prueba.
///
/// 6 referencias usando los libros/capítulos/versículos del seed:
///   Génesis 1:1 → Génesis 1:2 (1 voto)             [versículo único]
///   Génesis 1:1 → Génesis 2:4 (1 voto)             [versículo único]
///   Juan 3:16   → Génesis 22:12 (5 votos)          [rango destino: 12-14]
///   Juan 3:16   → 1 Juan 4:9 (3 votos)             [rango destino: 9-10]
///   Juan 3:16   → Juan 3:17 (2 votos)              [versículo único]
///   Salmos 23:1 → Juan 10:11 (4 votos)             [versículo único]
///
/// Diseñado para ejercitar:
///   * FROM lookup (3 refs desde Juan 3:16, 1 desde Génesis 1:1, etc.)
///   * TO lookup por coincidencia exacta de versículo único
///   * TO lookup por coincidencia de rango (Génesis 22:12 cae en 22:12-14)
///   * Orden por votos DESC (Génesis 22:12-14 con 5 votos debe ir primero)
///   * esRango = true vs false
///   * version 2 (libro fantasma de RV1569) sin refs (las 6 son de v1)
Future<void> seedCrossReferenciasTestDb(Database db) async {
  // version 1 (RV1909) refs
  // Génesis 1:1 → Génesis 1:2 (1 voto)
  await db.insert('cross_referencia', {
    'version_id': 1,
    'from_libro_id': 1,
    'from_capitulo': 1,
    'from_versiculo': 1,
    'to_libro_id': 1,
    'to_capitulo': 1,
    'to_versiculo_inicio': 2,
    'to_versiculo_fin': 2,
    'votos': 1,
  });
  // Génesis 1:1 → Génesis 2:4 (1 voto)
  await db.insert('cross_referencia', {
    'version_id': 1,
    'from_libro_id': 1,
    'from_capitulo': 1,
    'from_versiculo': 1,
    'to_libro_id': 1,
    'to_capitulo': 2,
    'to_versiculo_inicio': 4,
    'to_versiculo_fin': 4,
    'votos': 1,
  });
  // Juan 3:16 → Génesis 22:12-14 (5 votos) — TOP ref por votos
  await db.insert('cross_referencia', {
    'version_id': 1,
    'from_libro_id': 4,
    'from_capitulo': 3,
    'from_versiculo': 16,
    'to_libro_id': 1,
    'to_capitulo': 22,
    'to_versiculo_inicio': 12,
    'to_versiculo_fin': 14,
    'votos': 5,
  });
  // Juan 3:16 → 1 Juan 4:9-10 (3 votos)
  await db.insert('cross_referencia', {
    'version_id': 1,
    'from_libro_id': 4,
    'from_capitulo': 3,
    'from_versiculo': 16,
    'to_libro_id': 6, // 1 Juan (id=6 en el seed de tests)
    'to_capitulo': 4,
    'to_versiculo_inicio': 9,
    'to_versiculo_fin': 10,
    'votos': 3,
  });
  // Juan 3:16 → Juan 3:17 (2 votos)
  await db.insert('cross_referencia', {
    'version_id': 1,
    'from_libro_id': 4,
    'from_capitulo': 3,
    'from_versiculo': 16,
    'to_libro_id': 4,
    'to_capitulo': 3,
    'to_versiculo_inicio': 17,
    'to_versiculo_fin': 17,
    'votos': 2,
  });
  // Salmos 23:1 → Juan 10:11 (4 votos)
  await db.insert('cross_referencia', {
    'version_id': 1,
    'from_libro_id': 3,
    'from_capitulo': 23,
    'from_versiculo': 1,
    'to_libro_id': 4,
    'to_capitulo': 10,
    'to_versiculo_inicio': 11,
    'to_versiculo_fin': 11,
    'votos': 4,
  });
}

/// Crea un bundle de repositorios con BD sembrada. Devuelve un record
/// con la BD y los repos.
Future<({
  Database db,
  BibliaRepository biblia,
  BibliaSearchRepository search,
  FavoritosRepository favoritos,
  NotasRepository notas,
  HistorialRepository historial,
  CrossReferenciasRepository crossRefs,
})> createBibleReposWithSeed({
  bool includeCrossRefs = false,
}) async {
  final db = await createBibleTestDb();
  await seedBibleTestDb(db);
  if (includeCrossRefs) {
    await seedCrossReferenciasTestDb(db);
  }

  final helper = BibleDatabaseHelper.forTesting(db);
  return (
    db: db,
    biblia: BibliaRepository(helper),
    search: BibliaSearchRepository(helper),
    favoritos: FavoritosRepository(helper),
    notas: NotasRepository(helper),
    historial: HistorialRepository(helper),
    crossRefs: CrossReferenciasRepository(helper),
  );
}

/// Crea un bundle de repositorios con BD vacía (sin seed).
Future<({
  Database db,
  BibliaRepository biblia,
  BibliaSearchRepository search,
  FavoritosRepository favoritos,
  NotasRepository notas,
  HistorialRepository historial,
  CrossReferenciasRepository crossRefs,
})> createBibleReposEmpty() async {
  final db = await createBibleTestDb();

  final helper = BibleDatabaseHelper.forTesting(db);
  return (
    db: db,
    biblia: BibliaRepository(helper),
    search: BibliaSearchRepository(helper),
    favoritos: FavoritosRepository(helper),
    notas: NotasRepository(helper),
    historial: HistorialRepository(helper),
    crossRefs: CrossReferenciasRepository(helper),
  );
}

/// Cierra los repositorios (libera los StreamControllers internos) y la BD.
Future<void> closeBibleRepos({
  required Database db,
  required FavoritosRepository favoritos,
  required NotasRepository notas,
  required HistorialRepository historial,
}) async {
  await favoritos.dispose();
  await notas.dispose();
  await historial.dispose();
  await db.close();
}

/// Elimina todos los directorios temporales creados durante las pruebas.
Future<void> cleanupBibleTestDatabases() async {
  for (final dir in _tempDirs) {
    try {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Ignorar errores de limpieza.
    }
  }
  _tempDirs.clear();
}
