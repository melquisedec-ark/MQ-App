// =============================================================================
// build_biblia_db.dart
// =============================================================================
// Script de build offline que genera `assets/db/biblia.db` aplicando el
// schema (001_biblia_schema.sql) y poblando con datos de:
//
//   * RV1909: 31 102 versículos desde
//     https://github.com/iglesianazaret/biblia-reina-valera-1909-base-datos-sql
//     (copia local: assets/db/tools/source/rv1909/data.sql)
//
// Multi-version support:
//   El schema es multi-versión (tabla `version` con FKs CASCADE). Por ahora
//   solo RV1909 está poblada (decisión D1 de v1.0.1). Futuras versiones
//   (RV1960, NVI, RV1569 cuando se obtenga fuente estructurada, etc.) se
//   añaden reinsertando en la tabla `version` y poblando libros/capítulos/
//   versículos. Ver SOURCES.md §4 "Cómo añadir una nueva versión".
//
// Uso:
//   cd /home/melquisedec/Escritorio/Projects/Personales/MQ-App
//   dart run assets/db/tools/build_biblia_db.dart [opciones]
//
// Opciones:
//   --schema <ruta>     Ruta al schema SQL (default: assets/db/schema/001_biblia_schema.sql)
//   --rv1909 <ruta>     Ruta al data.sql de RV1909 (default: assets/db/tools/source/rv1909/data.sql)
//   --out <ruta>        Ruta del DB de salida (default: assets/db/biblia.db)
//   --cross-refs <ruta> Ruta al SQL de seed de cross_referencia
//                        (default: assets/db/seed_cross_referencias_rv1909.sql)
//                        Pasar --cross-refs='' para deshabilitar.
//   --keep-temp         Conserva el DB temporal en /tmp para debugging
//   --skip-validate     Omite las validaciones finales (NO recomendado)
//
// =============================================================================

import 'dart:io';
import 'dart:ffi';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';

import 'lib/books_canon.dart';

// ----------------------- CLI parsing ----------------------------------------

class CliOptions {
  String schemaPath;
  String rv1909SourcePath;
  String outPath;
  String? crossRefsPath; // null = no aplicar; '' = deshabilitar; ruta = aplicar
  bool keepTemp;
  bool skipValidate;

  CliOptions({
    required this.schemaPath,
    required this.rv1909SourcePath,
    required this.outPath,
    required this.crossRefsPath,
    required this.keepTemp,
    required this.skipValidate,
  });
}

CliOptions parseArgs(List<String> args, String projectRoot) {
  String schemaPath = pJoin(projectRoot, 'assets/db/schema/001_biblia_schema.sql');
  String rv1909Path = pJoin(projectRoot, 'assets/db/tools/source/rv1909/data.sql');
  String outPath    = pJoin(projectRoot, 'assets/db/biblia.db');
  String? crossRefsPath = pJoin(
      projectRoot, 'assets/db/seed_cross_referencias_rv1909.sql',
  );
  bool keepTemp = false;
  bool skipValidate = false;

  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    String? next() {
      if (i + 1 >= args.length) {
        stderr.writeln('ERROR: falta valor para $a');
        exit(2);
      }
      return args[++i];
    }

    switch (a) {
      case '--schema':        schemaPath = pAbs(next()!, projectRoot); break;
      case '--rv1909':        rv1909Path = pAbs(next()!, projectRoot); break;
      case '--out':           outPath    = pAbs(next()!, projectRoot); break;
      case '--cross-refs':
        final v = next()!;
        // '' explícito deshabilita; cualquier otra ruta se usa
        crossRefsPath = v.isEmpty ? null : pAbs(v, projectRoot);
        break;
      case '--keep-temp':     keepTemp   = true; break;
      case '--skip-validate': skipValidate = true; break;
      case '-h':
      case '--help':
        printUsage();
        exit(0);
      default:
        stderr.writeln('ERROR: argumento desconocido: $a');
        printUsage();
        exit(2);
    }
  }

  return CliOptions(
    schemaPath: schemaPath,
    rv1909SourcePath: rv1909Path,
    outPath: outPath,
    crossRefsPath: crossRefsPath,
    keepTemp: keepTemp,
    skipValidate: skipValidate,
  );
}

void printUsage() {
  stdout.writeln('Uso: dart run assets/db/tools/build_biblia_db.dart [opciones]');
  stdout.writeln('Opciones:');
  stdout.writeln('  --schema <ruta>     ruta al schema (default: 001_biblia_schema.sql)');
  stdout.writeln('  --rv1909 <ruta>     ruta al data.sql RV1909');
  stdout.writeln('  --out <ruta>        ruta del DB de salida (default: biblia.db)');
  stdout.writeln('  --cross-refs <ruta> ruta al seed SQL de cross_referencia (default: assets/db/seed_cross_referencias_rv1909.sql)');
  stdout.writeln('                      Pasar --cross-refs="" para deshabilitar el paso.');
  stdout.writeln('  --keep-temp         conserva el DB temporal');
  stdout.writeln('  --skip-validate     salta validaciones finales (no recomendado)');
}

// ----------------------- Helpers ---------------------------------------------

void _configureSqliteNative() {
  // 1. Honour $LIBSQLITE3_PATH if set.
  // 2. Try /tmp/libsqlite3.so (a known-good 3.52.0 build from a gradle cache).
  // 3. Try the system libsqlite3.so.0 by symlinking to a temp .so.
  // 4. Fall through to default (will fail with helpful error if not found).

  final envPath = Platform.environment['LIBSQLITE3_PATH'];
  // Priority: env > system lib (Linux/Windows/macOS) > others.
  final candidates = <String>[
    if (envPath != null && envPath.isNotEmpty) envPath,
    '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0',
    '/usr/lib/x86_64-linux-gnu/libsqlite3.so',
    '/usr/lib/libsqlite3.so.0',
    '/usr/lib/libsqlite3.so',
    '/usr/local/lib/libsqlite3.so.0',
    '/usr/local/lib/libsqlite3.so',
    '/opt/homebrew/lib/libsqlite3.dylib',
    '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0.8.6',
  ];

  for (final c in candidates) {
    if (File(c).existsSync()) {
      open.overrideForAll(() => DynamicLibrary.open(c));
      stdout.writeln('🔌 libsqlite3 nativa: $c');
      return;
    }
  }
  stdout.writeln('⚠️  No se encontró libsqlite3.so explícita; usando default (puede fallar).');
}

String pJoin(String a, String b) {
  if (a.endsWith('/') || a.endsWith(r'\')) return '$a$b';
  return '$a${Platform.pathSeparator}$b';
}

String pAbs(String p, String root) {
  if (p.startsWith('/') || p.contains(':')) return p;
  return pJoin(root, p);
}

String findProjectRoot() {
  var dir = Directory.current;
  while (!File(pJoin(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw Exception('No se encontró pubspec.yaml; ejecuta desde el root del proyecto.');
    }
    dir = parent;
  }
  return dir.path;
}

class Timings {
  final Stopwatch total = Stopwatch()..start();
  final Stopwatch schema = Stopwatch();
  final Stopwatch versions = Stopwatch();
  final Stopwatch books = Stopwatch();
  final Stopwatch chapters = Stopwatch();
  final Stopwatch verses = Stopwatch();
  final Stopwatch crossRefs = Stopwatch();

  void printSummary() {
    stdout.writeln('');
    stdout.writeln('⏱️  Tiempos (ms):');
    stdout.writeln('   schema     : ${schema.elapsedMilliseconds}');
    stdout.writeln('   versions   : ${versions.elapsedMilliseconds}');
    stdout.writeln('   books      : ${books.elapsedMilliseconds}');
    stdout.writeln('   chapters   : ${chapters.elapsedMilliseconds}');
    stdout.writeln('   verses     : ${verses.elapsedMilliseconds}');
    stdout.writeln('   cross-refs : ${crossRefs.elapsedMilliseconds}');
    stdout.writeln('   TOTAL      : ${total.elapsedMilliseconds}');
  }
}

class Stats {
  int versionCount = 0;
  int bookCount = 0;
  int chapterCount = 0;
  int verseCount = 0;
  int crossRefCount = 0;
  Map<int, int> versesByVersion = {};
  Map<int, int> booksByVersion = {};
  Map<int, int> crossRefsByVersion = {};

  void printSummary(String dbPath) {
    final sizeBytes = File(dbPath).lengthSync();
    final sizeMb = sizeBytes / 1024 / 1024;
    stdout.writeln('');
    stdout.writeln('📊 Estadísticas finales:');
    stdout.writeln('   Versiones        : $versionCount');
    stdout.writeln('   Libros           : $bookCount (esperado 66)');
    stdout.writeln('   Capítulos        : $chapterCount (esperado 1 189)');
    stdout.writeln('   Versículos       : $verseCount (esperado ~31 102)');
    stdout.writeln('   Cross-references : $crossRefCount (esperado ~340 000)');
    stdout.writeln('   Tamaño           : ${sizeMb.toStringAsFixed(2)} MB ($sizeBytes bytes)');
    for (final entry in versesByVersion.entries) {
      stdout.writeln('     • version_id=${entry.key}: ${entry.value} versículos');
    }
    for (final entry in crossRefsByVersion.entries) {
      stdout.writeln('     • version_id=${entry.key}: ${entry.value} cross-refs');
    }
  }
}

// ----------------------- Main pipeline ---------------------------------------

Future<int> main(List<String> args) async {
  final projectRoot = findProjectRoot();
  final opts = parseArgs(args, projectRoot);
  final timings = Timings();
  final stats = Stats();

  stdout.writeln('╔════════════════════════════════════════════════════════════════╗');
  stdout.writeln('║  build_biblia_db.dart — Generador de biblia.db (Fase 2)       ║');
  stdout.writeln('╚════════════════════════════════════════════════════════════════╝');
  stdout.writeln('');
  stdout.writeln('📂 Rutas:');
  stdout.writeln('   Proyecto   : $projectRoot');
  stdout.writeln('   Schema     : ${opts.schemaPath}');
  stdout.writeln('   RV1909 src : ${opts.rv1909SourcePath}');
  stdout.writeln('   Salida     : ${opts.outPath}');

  if (!File(opts.schemaPath).existsSync()) {
    stderr.writeln('❌ No existe schema: ${opts.schemaPath}');
    return 1;
  }
  if (!File(opts.rv1909SourcePath).existsSync()) {
    stderr.writeln('❌ No existe fuente RV1909: ${opts.rv1909SourcePath}');
    return 1;
  }

  // Configure sqlite3 native library.
  // On Linux, package:sqlite3 looks for `libsqlite3.so` (development symlink).
  // Most distros ship only the versioned `libsqlite3.so.0`, so we either:
  //   (a) honour $LIBSQLITE3_PATH if the caller provides one
  //   (b) try a few common locations
  _configureSqliteNative();

  final tempDir = Directory.systemTemp.createTempSync('mq_build_');
  final tempDbPath = pJoin(tempDir.path, 'biblia_build.db');
  if (File(tempDbPath).existsSync()) File(tempDbPath).deleteSync();
  stdout.writeln('');
  stdout.writeln('🗂️  DB temporal: $tempDbPath');

  final db = sqlite3.open(tempDbPath);
  db.execute('PRAGMA foreign_keys = ON;');
  db.execute('PRAGMA journal_mode = WAL;');
  db.execute('PRAGMA synchronous = NORMAL;');
  db.execute('PRAGMA temp_store = MEMORY;');
  db.execute('PRAGMA cache_size = -20000;'); // 20 MB

  try {
    // ---------- 1) Schema ----------
    timings.schema.start();
    _applySchema(db, opts.schemaPath);
    timings.schema.stop();
    stdout.writeln('✅ Schema aplicado (migración 001)');

    // ---------- 2) Versions ----------
    timings.versions.start();
    final versionIds = _insertVersions(db);
    timings.versions.stop();
    stats.versionCount = versionIds.length;
    stdout.writeln('✅ Versiones insertadas: ${versionIds.length} (RV1909)');

    // ---------- 3) Books (66) ----------
    timings.books.start();
    final booksByVersion = _insertBooks(db, versionIds);
    timings.books.stop();
    stats.bookCount = booksByVersion.values.fold(0, (a, b) => a + b.length);
    stats.booksByVersion = booksByVersion.map((k, v) => MapEntry(k, v.length));
    stdout.writeln('✅ Libros insertados: ${stats.bookCount}');

    // ---------- 4) Chapters (1 189) ----------
    timings.chapters.start();
    final chapterIdsByVersion = _insertChapters(db, booksByVersion);
    timings.chapters.stop();
    int capTotal = 0;
    for (final perBook in chapterIdsByVersion.values) {
      for (final chList in perBook.values) {
        capTotal += chList.length;
      }
    }
    stats.chapterCount = capTotal;
    stdout.writeln('✅ Capítulos insertados: $capTotal');

    // ---------- 5) Verses from RV1909 SQL ----------
    timings.verses.start();
    final versesByVersion = _insertVerses(
      db,
      chapterIdsByVersion,
      rv1909Path: opts.rv1909SourcePath,
    );
    timings.verses.stop();
    stats.verseCount = versesByVersion.values.fold(0, (a, b) => a + b);
    stats.versesByVersion = versesByVersion;
    stdout.writeln('✅ Versículos insertados: ${stats.verseCount}');

    // ---------- 6) Config ----------
    _insertConfig(db, versesByVersion);
    stdout.writeln('✅ Config insertada');

    // ---------- 7) Cross-references (migración 004) ----------
    if (opts.crossRefsPath != null) {
      if (!File(opts.crossRefsPath!).existsSync()) {
        stderr.writeln('');
        stderr.writeln('❌ No existe seed de cross-references: ${opts.crossRefsPath}');
        stderr.writeln('   Para generarlo:');
        stderr.writeln('     curl -L -o assets/db/tools/source/scrollmapper/cross_references.txt \\');
        stderr.writeln('       https://raw.githubusercontent.com/scrollmapper/bible_databases/master/sources/extras/cross_references.txt');
        stderr.writeln('     dart run assets/db/tools/generate_cross_references_seed.dart');
        stderr.writeln('   O re-corre este script con --cross-refs="" para omitir el paso.');
        return 5;
      }
      timings.crossRefs.start();
      final crossRefCounts = _applyCrossRefsSeed(db, opts.crossRefsPath!);
      timings.crossRefs.stop();
      stats.crossRefCount = crossRefCounts.values.fold(0, (a, b) => a + b);
      stats.crossRefsByVersion = crossRefCounts;
      stdout.writeln('✅ Cross-references insertadas: ${stats.crossRefCount}');
    } else {
      stdout.writeln('⚠️  Cross-references omitidas (--cross-refs="")');
    }

    // ---------- 8) ANALYZE ----------
    db.execute('ANALYZE;');
    stdout.writeln('✅ ANALYZE ejecutado');

    // ---------- 9) Validations ----------
    if (!opts.skipValidate) {
      final ok = runValidations(db);
      if (!ok) {
        stderr.writeln('❌ Validaciones fallaron — abortando.');
        return 3;
      }
    } else {
      stdout.writeln('⚠️  Validaciones omitidas (--skip-validate)');
    }

    // ---------- 10) Copy to final destination ----------
    db.dispose();
    final outDir = Directory(File(opts.outPath).parent.path);
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    if (File(opts.outPath).existsSync()) File(opts.outPath).deleteSync();
    File(tempDbPath).copySync(opts.outPath);
    stdout.writeln('');
    stdout.writeln('📦 DB final copiado a: ${opts.outPath}');

    stats.printSummary(opts.outPath);
    timings.printSummary();

    if (opts.keepTemp) {
      stdout.writeln('🗂️  DB temporal conservado en: $tempDir');
    } else {
      tempDir.deleteSync(recursive: true);
    }
  } catch (e, st) {
    stderr.writeln('❌ ERROR: $e');
    stderr.writeln(st);
    try { db.dispose(); } catch (_) {}
    return 4;
  }

  stdout.writeln('');
  stdout.writeln('🎉 build_biblia_db.dart terminado con éxito.');
  return 0;
}

// ----------------------- Pipeline steps --------------------------------------

void _applySchema(Database db, String schemaPath) {
  final schemaSql = File(schemaPath).readAsStringSync();
  db.execute(schemaSql);
  // ── Migración 004 (cross_referencia) ──
  // Se aplica DESPUÉS de 001_biblia_schema.sql (que crea las tablas base
  // version/libro/capitulo que cross_referencia referencia por FK). Si el
  // 001 ya incluye la tabla, el CREATE IF NOT EXISTS es no-op.
  final migrationPath = schemaPath.replaceFirst(
    RegExp(r'001_biblia_schema\.sql$'),
    '004_cross_referencias.sql',
  );
  if (File(migrationPath).existsSync()) {
    final migrationSql = File(migrationPath).readAsStringSync();
    db.execute(migrationSql);
  } else {
    stderr.writeln('⚠️  No se encontró $migrationPath; la tabla cross_referencia NO se creará.');
  }
}

/// Aplica el SQL de seed de cross-references a la BD.
///
/// Lee el archivo completo y lo ejecuta con `db.execute()`. Las
/// migraciones usan BEGIN/COMMIT por lote (--batch-size), así que la
/// performance es comparable a un script generado dinámicamente.
///
/// Devuelve un mapa `version_id → cantidad_insertada`.
Map<int, int> _applyCrossRefsSeed(Database db, String seedPath) {
  final sql = File(seedPath).readAsStringSync();
  // El seed incluye `DELETE FROM cross_referencia WHERE version_id = N;`
  // como primer paso (idempotente). Después INSERTs en transacciones.
  db.execute(sql);
  // Conteo por versión
  final rs = db.select('''
    SELECT version_id, COUNT(*) AS c
    FROM cross_referencia
    GROUP BY version_id
  ''');
  final result = <int, int>{};
  for (final row in rs) {
    final v = row['version_id'];
    final c = row['c'];
    if (v is int && c is int) {
      result[v] = c;
    }
  }
  return result;
}

Map<String, int> _insertVersions(Database db) {
  final versionIds = <String, int>{};
  final stmt = db.prepare('''
    INSERT INTO version (nombre, abreviatura, idioma, descripcion, anio_publicacion,
                         es_dominio_publico, activa)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ''');

  void insertVersion(
    String nombre,
    String abrev,
    String idioma,
    String desc,
    int anio,
    int esDP,
    int activa,
  ) {
    stmt.execute([nombre, abrev, idioma, desc, anio, esDP, activa]);
    versionIds[nombre] = db.lastInsertRowId;
  }

  // v1.0.1 (decisión D1): solo RV1909 está poblada. El schema es
  // multi-versión (esta tabla y las FKs CASCADE), así que añadir RV1569,
  // RV1960, NVI, etc. en el futuro es solo reinsertar aquí y poblar
  // libros/capítulos/versículos. Ver SOURCES.md §4.
  insertVersion(
    'Reina Valera 1909',
    'RVR1909',
    'es',
    'Revisión de 1909 de la Reina Valera. Basada en el texto de Cipriano de '
        'Valera (1602) con revisiones posteriores. Dominio público en la mayoría '
        'de jurisdicciones por antigüedad (>100 años desde publicación).',
    1909, 1, 1,
  );

  stmt.dispose();
  return {
    'RV1909': versionIds['Reina Valera 1909']!,
  };
}

Map<int, List<int>> _insertBooks(Database db, Map<String, int> versionIds) {
  final stmt = db.prepare('''
    INSERT INTO libro (version_id, nombre, abreviatura, testamento, numero, total_capitulos)
    VALUES (?, ?, ?, ?, ?, ?)
  ''');

  final result = <int, List<int>>{};

  // v1.0.1: solo RV1909 (ver SOURCES.md §4 para añadir nuevas versiones).
  final versionId = versionIds['RV1909']!;
  final bookIds = <int>[];
  for (final book in kBookCanon) {
    stmt.execute([
      versionId,
      book.nombre,
      book.abreviatura,
      book.testamento,
      book.numero,
      book.totalCapitulos,
    ]);
    bookIds.add(db.lastInsertRowId);
  }
  result[versionId] = bookIds;

  stmt.dispose();
  return result;
}

Map<int, Map<int, List<int>>> _insertChapters(
  Database db,
  Map<int, List<int>> booksByVersion,
) {
  final stmt = db.prepare('''
    INSERT INTO capitulo (libro_id, numero, total_versiculos)
    VALUES (?, ?, 0)
  ''');

  final result = <int, Map<int, List<int>>>{};

  for (final entry in booksByVersion.entries) {
    final versionId = entry.key;
    final bookIds = entry.value;
    final perBook = <int, List<int>>{};

    for (int i = 0; i < bookIds.length; i++) {
      final bookId = bookIds[i];
      final book = kBookCanon[i];
      final chapterIds = <int>[];
      for (int ch = 1; ch <= book.totalCapitulos; ch++) {
        stmt.execute([bookId, ch]);
        chapterIds.add(db.lastInsertRowId);
      }
      perBook[bookId] = chapterIds;
    }
    result[versionId] = perBook;
  }

  stmt.dispose();
  return result;
}

Map<int, int> _insertVerses(
  Database db,
  Map<int, Map<int, List<int>>> chapterIdsByVersion, {
  required String rv1909Path,
}) {
  stdout.writeln('   Parseando fuente RV1909...');
  final rv1909Verses = _parseRv1909Sql(rv1909Path);
  stdout.writeln('   ✓ ${rv1909Verses.length} versículos parseados');

  final versionIds = chapterIdsByVersion.keys.toList();
  final rv1909VersionId = versionIds.first;

  // Group source verses by (book, chapter) for fast lookup
  final versesByBookChapter = <int, Map<int, List<Rv1909Verse>>>{};
  for (final v in rv1909Verses) {
    versesByBookChapter
        .putIfAbsent(v.bookId, () => <int, List<Rv1909Verse>>{})
        .putIfAbsent(v.chapter, () => <Rv1909Verse>[])
        .add(v);
  }

  final verseStmt = db.prepare('''
    INSERT INTO versiculo (capitulo_id, numero, texto) VALUES (?, ?, ?)
  ''');
  final updateCapStmt = db.prepare('''
    UPDATE capitulo SET total_versiculos = ? WHERE id = ?
  ''');

  const kBatchSize = 1000;
  int totalInserted = 0;
  int batchCount = 0;

  // v1.0.1: solo RV1909 se inserta (sin placeholder de RV1569).
  void insertForVersion(
    int versionId,
    Map<int, List<int>> bookChapterIds,
  ) {
    // bookChapterIds keys are libro_ids, in insertion order.
    final libroIds = bookChapterIds.keys.toList();
    for (int bookIdx = 0; bookIdx < kBookCanon.length; bookIdx++) {
      final book = kBookCanon[bookIdx];
      final libroId = libroIds[bookIdx];
      final chapterIds = bookChapterIds[libroId]!;

      for (int ch = 1; ch <= book.totalCapitulos; ch++) {
        final chapterId = chapterIds[ch - 1];
        final verses = versesByBookChapter[book.numero]?[ch] ?? const <Rv1909Verse>[];
        if (verses.isEmpty) {
          updateCapStmt.execute([0, chapterId]);
          continue;
        }
        db.execute('BEGIN');
        try {
          for (final v in verses) {
            verseStmt.execute([chapterId, v.verse, v.text]);
            totalInserted++;
            if (totalInserted % kBatchSize == 0) {
              db.execute('COMMIT');
              batchCount++;
              if (batchCount % 10 == 0) {
                stdout.write('\r   ... $totalInserted versículos insertados');
              }
              db.execute('BEGIN');
            }
          }
          updateCapStmt.execute([verses.length, chapterId]);
          db.execute('COMMIT');
        } catch (e) {
          db.execute('ROLLBACK');
          rethrow;
        }
      }
    }
  }

  stdout.write('   Insertando versículos RV1909...');
  totalInserted = 0;
  insertForVersion(rv1909VersionId, chapterIdsByVersion[rv1909VersionId]!);
  final rv1909Count = totalInserted;
  stdout.writeln('\r   ✓ RV1909: $rv1909Count versículos insertados');

  verseStmt.dispose();
  updateCapStmt.dispose();

  return {rv1909VersionId: rv1909Count};
}

void _insertConfig(Database db, Map<int, int> versesByVersion) {
  final stmt = db.prepare('''
    INSERT OR REPLACE INTO config (clave, valor, fecha_modificacion)
    VALUES (?, ?, strftime('%s', 'now'))
  ''');
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  stmt.execute(['biblia.db.build_timestamp', now.toString()]);
  stmt.execute(['biblia.db.build_script_version', '1.0.1']);
  stmt.execute(['biblia.db.rv1909_verses', versesByVersion.values.first.toString()]);
  stmt.dispose();
}

// ----------------------- Parsing --------------------------------------------

class Rv1909Verse {
  final int bookId;
  final int chapter;
  final int verse;
  final String text;
  Rv1909Verse(this.bookId, this.chapter, this.verse, this.text);
}

/// Parses the iglesia-nazaret SQL dump. Each line in the `INSERT INTO verses`
/// block is `(book_id, chapter, verse, 'text')`. The text is single-quoted and
/// may contain escaped quotes (`\'` or `''`).
List<Rv1909Verse> _parseRv1909Sql(String path) {
  final raw = File(path).readAsLinesSync();
  final out = <Rv1909Verse>[];
  final rowRegex = RegExp(r'^\s*\((\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*');
  for (final line in raw) {
    final m = rowRegex.firstMatch(line);
    if (m == null) continue;
    final bookId = int.parse(m.group(1)!);
    final chapter = int.parse(m.group(2)!);
    final verse = int.parse(m.group(3)!);
    final firstQuote = line.indexOf("'", m.end);
    if (firstQuote < 0) continue;
    int endQuote = -1;
    for (int i = firstQuote + 1; i < line.length; i++) {
      final c = line[i];
      if (c == r'\' && i + 1 < line.length && line[i + 1] == "'") {
        i++;
        continue;
      }
      if (c == "'") {
        if (i + 1 < line.length && line[i + 1] == "'") {
          i++;
          continue;
        }
        endQuote = i;
        break;
      }
    }
    if (endQuote < 0) {
      endQuote = line.lastIndexOf("'");
      if (endQuote <= firstQuote) continue;
    }
    final rawText = line.substring(firstQuote + 1, endQuote);
    final text = _unescapeSqlString(rawText);
    out.add(Rv1909Verse(bookId, chapter, verse, text));
  }
  return out;
}

String _unescapeSqlString(String s) {
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final c = s[i];
    if (c == r'\' && i + 1 < s.length) {
      final next = s[i + 1];
      switch (next) {
        case 'n':  buf.write('\n'); i++; break;
        case 'r':  buf.write('\r'); i++; break;
        case 't':  buf.write('\t'); i++; break;
        case '\\': buf.write('\\'); i++; break;
        case "'":  buf.write("'");  i++; break;
        case '"':  buf.write('"');  i++; break;
        case '0':  buf.write(' '); i++; break;
        default:   buf.write(c);   break;
      }
    } else if (c == "'" && i + 1 < s.length && s[i + 1] == "'") {
      buf.write("'");
      i++;
    } else {
      buf.write(c);
    }
  }
  return buf.toString();
}

// ----------------------- Validations ----------------------------------------

bool runValidations(Database db) {
  stdout.writeln('');
  stdout.writeln('🔍 Ejecutando validaciones...');
  int passed = 0;
  int failed = 0;
  void check(String name, bool cond, String detail) {
    if (cond) {
      stdout.writeln('   ✅ $name${detail.isNotEmpty ? ' — $detail' : ''}');
      passed++;
    } else {
      stderr.writeln('   ❌ $name${detail.isNotEmpty ? ' — $detail' : ''}');
      failed++;
    }
  }

  final versionCount = scalarQuery(db, 'SELECT COUNT(*) FROM version');
  check('COUNT(version) = 1', versionCount == 1, 'actual=$versionCount');

  final libroCount = scalarQuery(db, 'SELECT COUNT(*) FROM libro');
  check('COUNT(libro) = 66', libroCount == 66, 'actual=$libroCount');

  final capCount = scalarQuery(db, 'SELECT COUNT(*) FROM capitulo');
  check('COUNT(capitulo) = 1 189', capCount == 1189, 'actual=$capCount');

  final verseCount = scalarQuery(db, 'SELECT COUNT(*) FROM versiculo');
  check(
    'COUNT(versiculo) ≈ 31 102',
    verseCount >= 31000 && verseCount <= 31200,
    'actual=$verseCount',
  );

  final diosCount = scalarQuery(db, "SELECT COUNT(*) FROM versiculo WHERE texto LIKE '%Dios%'");
  check(
    'COUNT(versiculo WHERE texto LIKE %Dios%) > 1 000',
    diosCount > 1000,
    'actual=$diosCount',
  );

  // FTS5 tokeniza con `unicode61`: la palabra "Dios," y "Dios" generan tokens
  // distintos ("dios," vs "dios"). Para que LIKE y FTS5 arrojen resultados
  // comparables, se usa `Dios*` (prefix query), que es la forma idiomática de
  // buscar en FTS5.
  final ftsDiosCount = scalarQuery(db, "SELECT COUNT(*) FROM versiculo_fts WHERE versiculo_fts MATCH 'Dios*'");
  check(
    'FTS5 MATCH Dios* ≈ LIKE %Dios% (dentro de 5%)',
    ftsDiosCount > 0 && (ftsDiosCount - diosCount).abs() / diosCount < 0.05,
    'fts=$ftsDiosCount, like=$diosCount',
  );

  final ftsJoseCount = scalarQuery(db, "SELECT COUNT(*) FROM versiculo_fts WHERE versiculo_fts MATCH 'jose*'");
  check(
    'FTS5 MATCH jose* (sin tilde) > 100',
    ftsJoseCount > 100,
    'actual=$ftsJoseCount',
  );

  // FTS5: insensibilidad a tildes
  final ftsJoseTildeCount = scalarQuery(db, "SELECT COUNT(*) FROM versiculo_fts WHERE versiculo_fts MATCH 'josé*'");
  check(
    'FTS5 insensibilidad a tildes: josé* == jose*',
    (ftsJoseTildeCount - ftsJoseCount).abs() / ftsJoseCount < 0.01,
    'con_tilde=$ftsJoseTildeCount, sin_tilde=$ftsJoseCount',
  );

  final integrity = stringQuery(db, 'PRAGMA integrity_check');
  check('PRAGMA integrity_check = ok', integrity == 'ok', 'actual=$integrity');

  final fkResult = queryAll(db, 'PRAGMA foreign_key_check');
  check(
    'PRAGMA foreign_key_check = [] (sin violaciones FK)',
    fkResult.isEmpty,
    'violations=${fkResult.length}',
  );

  final rv1909Count = scalarQuery(db, '''
    SELECT COUNT(*) FROM versiculo v
      JOIN capitulo c ON v.capitulo_id = c.id
      JOIN libro l ON c.libro_id = l.id
      JOIN version ver ON l.version_id = ver.id
    WHERE ver.abreviatura = 'RVR1909'
  ''');
  check('RVR1909 = 31 102 versículos', rv1909Count == 31102, 'actual=$rv1909Count');

  // ── Validaciones de cross_referencia (migración 004) ──────────────
  // Si el paso de cross-refs fue deshabilitado, no chequeamos nada.
  final crossRefCount = scalarQuery(db, 'SELECT COUNT(*) FROM cross_referencia');
  if (crossRefCount > 0) {
    check(
      'cross_referencia: ~340k refs (±15%)',
      crossRefCount >= 280000 && crossRefCount <= 360000,
      'actual=$crossRefCount',
    );

    // Top-5 versículos con más refs SALIENTES (sanity check)
    final topFromRs = db.select('''
      SELECT from_libro_id, from_capitulo, from_versiculo, COUNT(*) AS c
      FROM cross_referencia
      GROUP BY from_libro_id, from_capitulo, from_versiculo
      ORDER BY c DESC
      LIMIT 5
    ''');
    stdout.writeln('   📊 Top-5 versículos con más refs salientes:');
    for (final row in topFromRs) {
      stdout.writeln(
        '     • ${row['from_libro_id']}:${row['from_capitulo']}:${row['from_versiculo']} (${row['c']} refs)',
      );
    }
  } else {
    stdout.writeln('   ⚠️  cross_referencia vacía — omitiendo validaciones de cross-refs');
  }

  stdout.writeln('');
  stdout.writeln('🧪 Validaciones: $passed pasaron, $failed fallaron');
  return failed == 0;
}

int scalarQuery(Database db, String sql) {
  final rs = db.select(sql);
  if (rs.isEmpty) return 0;
  final row = rs.first;
  final v = row.values.first;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v == null) return 0;
  return 0;
}

String stringQuery(Database db, String sql) {
  final rs = db.select(sql);
  if (rs.isEmpty) return '';
  final row = rs.first;
  final v = row.values.first;
  if (v == null) return '';
  return v.toString();
}

List<Row> queryAll(Database db, String sql) {
  return db.select(sql).toList();
}
