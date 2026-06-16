import 'dart:io' show Platform, File, Directory;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'bible_schema_version.dart';

/// Logger estructurado para eventos de la base de datos de Biblia.
final _log = Logger('BibleDatabaseHelper');

/// Helper singleton para la gestión de `biblia.db`.
///
/// Esta base de datos es **independiente** de `mqapp.db` (la del himnario),
/// según la decisión arquitectónica #5 de Fase 1. Cada BD tiene su propio
/// ciclo de migraciones y se bundlea como asset separado.
///
/// La DB se copia desde `assets/db/biblia.db` en la primera ejecución
/// (o cuando la versión del asset sea mayor que la local). Una vez copiada,
/// se abre con FFI en TODAS las plataformas (mismo backend que el himnario,
/// ver `lib/core/database/database_helper.dart` para los detalles).
///
/// ## Versionado
///
/// Hay dos números de versión:
///
/// 1. `kSchemaVersion` (int): controla migraciones estructurales aplicadas
///    por sqflite (`onUpgrade`). Se incrementa cuando cambia el DDL.
/// 2. Asset version (`bible_schema_version.dart`): controla cuándo se debe
///    reemplazar la BD completa. Se incrementa cuando cambia el seed data
///    (nuevos versículos, corrección de texto, etc.).
class BibleDatabaseHelper {
  BibleDatabaseHelper._();

  /// Instancia singleton (mismo patrón que `DatabaseHelper` del himnario).
  static final BibleDatabaseHelper instance = BibleDatabaseHelper._();

  /// Crea un helper respaldado por una BD ya abierta. Solo para testing.
  /// El llamador es responsable de haber creado la BD con el esquema correcto.
  factory BibleDatabaseHelper.forTesting(Database database) {
    final helper = BibleDatabaseHelper._();
    helper._database = database;
    return helper;
  }

  /// Nombre del archivo de BD dentro de los assets y en el sistema de archivos.
  static const String dbFileName = 'biblia.db';

  /// Versión del esquema (migraciones estructurales de tabla/columna).
  /// Incrementar solo cuando se cambie DDL en `assets/db/schema/`.
  ///
  /// Historial:
  /// * v1: esquema inicial (6 tablas + FTS5 + config + schema_version).
  /// * v2: añade tabla `cross_referencia` (migración 004). Triggers de
  ///       validación version_id↔libro_id en ambas FKs. Índices FROM, TO,
  ///       y por votos. ~340k refs precargadas del dataset openbible.
  static const int kSchemaVersion = 2;

  Database? _database;

  /// Devuelve la instancia abierta de la BD, inicializándola si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la BD: copia desde assets si es primera ejecución o si la
  /// versión del asset es mayor que la local, y luego abre con FFI.
  Future<Database> _initDatabase() async {
    final stopwatch = Stopwatch()..start();

    // ── Modo desarrollo (desktop + debug): BD directa del proyecto ──
    // Mismo patrón que `DatabaseHelper` del himnario: en debug desktop se
    // apunta a `assets/db/biblia.db` directamente (cuando exista) para
    // iterar rápido sin reinstalar.
    if (kDebugMode && !Platform.isAndroid && !Platform.isIOS) {
      final projectDb = p.join(
        Directory.current.path,
        'assets/db/${BibleDatabaseHelper.dbFileName}',
      );
      final f = File(projectDb);
      if (f.existsSync()) {
        _log.info('Debug mode: usando BD del proyecto en $projectDb');
        final db = await _openDatabasePlatform(projectDb);
        _log.info(
          'BibleDatabaseHelper abierta (schema v$kSchemaVersion) en '
          '${stopwatch.elapsedMilliseconds}ms',
        );
        return db;
      }
      _log.warning(
        'Debug mode: no existe $projectDb todavía '
        '(pendiente de generación por @back). '
        'Se abrirá BD vacía en memoria con el esquema aplicado.',
      );
      // Fallback: BD en memoria con el esquema aplicado, útil para que la
      // app no se rompa durante el desarrollo de UI antes de tener la DB.
      final db = await _openInMemoryWithSchema();
      _log.info(
        'BibleDatabaseHelper abierta in-memory (schema v$kSchemaVersion) en '
        '${stopwatch.elapsedMilliseconds}ms',
      );
      return db;
    }

    // ── Modo release / mobile ───────────────────────────────────
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, BibleDatabaseHelper.dbFileName);
    final localFile = File(dbPath);

    // Leer versiones antes de tocar la BD
    final assetVersion = await BibleSchemaVersion.readAssetVersion();
    final localVersion =
        await BibleSchemaVersion.readLocalVersion(dir.path);

    if (!localFile.existsSync()) {
      // ── Primera instalación: copiar BD del asset ──
      _log.info('No existe biblia.db local, copiando desde assets...');
      await _copyAssetDb(localFile);
    } else if (BibleSchemaVersion.needsUpdate(assetVersion, localVersion)) {
      // ── Actualización: backup → reemplazar → restore ──
      // Las tablas de usuario (nota, favorito_versiculo, historial_versiculo,
      // config) SÍ se respaldan antes de reemplazar la BD, y se restauran
      // después para preservar los datos del usuario a través de actualizaciones.
      _log.info(
        'biblia.db desactualizada: assetVersion=$assetVersion > '
        'localVersion=$localVersion — realizando backup/restore',
      );
      try {
        // 1. Backup datos de usuario desde la BD actual
        _log.info('Respaldando datos de usuario de biblia.db...');
        final backup = await _backupBibleUserData(dbPath);

        // 2. Cerrar conexión y reemplazar BD
        await _database?.close();
        _database = null;
        if (localFile.existsSync()) {
          await localFile.delete();
        }
        await _copyAssetDb(localFile);

        // 3. Restaurar datos de usuario sobre la BD nueva
        final newDb = await _openDatabaseRaw(dbPath);
        await newDb.execute('PRAGMA user_version = $kSchemaVersion;');
        await _restoreBibleUserData(newDb, backup);
        await newDb.close();

        _log.info('biblia.db actualizada — datos de usuario restaurados');
      } catch (e, st) {
        _log.severe('Error en backup/restore de biblia.db: $e\n$st');
        // Si falla, la app continúa con la BD nueva sin datos de usuario.
        // Es preferible a tener una BD corrupta con datos inconsistentes.
      }
    }

    // Abrir BD (actualizada o recién copiada)
    final db = await _openDatabasePlatform(dbPath);

    // Persistir versión local
    if (assetVersion > 0) {
      await BibleSchemaVersion.writeLocalVersion(dir.path, assetVersion);
    }

    _log.info(
      'BibleDatabaseHelper abierta (schema v$kSchemaVersion) en '
      '${stopwatch.elapsedMilliseconds}ms',
    );
    return db;
  }

  /// Nombres de las tablas de usuario en biblia.db que deben respaldarse
  /// antes de una actualización completa del asset.
  static const _bibleUserTables = [
    'nota',
    'favorito_versiculo',
    'historial_versiculo',
    'config',
  ];

  /// Respaldar datos de usuario de biblia.db antes de reemplazar el asset.
  ///
  /// Abre la BD actual en modo raw (sin gestión de versiones) y extrae
  /// todas las tablas de usuario para restaurarlas luego.
  Future<Map<String, List<Map<String, dynamic>>>> _backupBibleUserData(
    String dbPath,
  ) async {
    final db = await _openDatabaseRaw(dbPath);
    try {
      final backup = <String, List<Map<String, dynamic>>>{};

      for (final table in _bibleUserTables) {
        try {
          backup[table] = await db.query(table);
          _log.info('Backup biblia.$table: ${backup[table]!.length} filas');
        } catch (e) {
          // La tabla puede no existir en versiones antiguas
          _log.warning('No se pudo respaldar biblia.$table: $e');
          backup[table] = [];
        }
      }

      return backup;
    } finally {
      await db.close();
    }
  }

  /// Restaurar datos de usuario en la BD recién copiada del asset.
  ///
  /// El orden restaura primero `config` (sin FK), luego las tablas con FK.
  /// Usa INSERT OR REPLACE para nota (UNIQUE constraint) e INSERT OR IGNORE
  /// para favorito_versiculo e historial_versiculo (para no duplicar si
  /// el asset ya contiene algunos datos semilla).
  ///
  /// La restauración se hace con PRAGMA foreign_keys = OFF para evitar
  /// errores de orden (ej: un favorito cuya FK versión/libro aún no se
  /// ha insertado en la nueva BD).
  Future<void> _restoreBibleUserData(
    Database db,
    Map<String, List<Map<String, dynamic>>> backup,
  ) async {
    await db.execute('PRAGMA foreign_keys = OFF;');
    try {
      int count = 0;

      // config: sin FK, simple key-value. REEMPLAZAR si ya existe.
      for (final row in backup['config'] ?? []) {
        await db.insert('config', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }

      // favorito_versiculo: UNIQUE(version_id, libro_id, capitulo, numero).
      // Usar IGNORE para no duplicar si el_asset ya trae algún favorito.
      for (final row in backup['favorito_versiculo'] ?? []) {
        try {
          await db.insert('favorito_versiculo', row,
              conflictAlgorithm: ConflictAlgorithm.ignore);
          count++;
        } catch (e) {
          _log.warning('No se pudo restaurar favorito: $e');
        }
      }

      // nota: UNIQUE(version_id, libro_id, capitulo, numero).
      // Usar REPLACE para mantener las notas del usuario si el asset
      // trae alguna nota por defecto (poco probable pero defensivo).
      for (final row in backup['nota'] ?? []) {
        try {
          await db.insert('nota', row,
              conflictAlgorithm: ConflictAlgorithm.replace);
          count++;
        } catch (e) {
          _log.warning('No se pudo restaurar nota: $e');
        }
      }

      // historial_versiculo: sin UNIQUE constraint más allá de id.
      // Usar IGNORE para evitar conflictos de PK.
      for (final row in backup['historial_versiculo'] ?? []) {
        try {
          await db.insert('historial_versiculo', row,
              conflictAlgorithm: ConflictAlgorithm.ignore);
          count++;
        } catch (e) {
          _log.warning('No se pudo restaurar historial: $e');
        }
      }

      _log.info('Restore biblia.db completo: $count registros restaurados');
    } finally {
      await db.execute('PRAGMA foreign_keys = ON;');
    }
  }

  /// Copia la BD del asset empaquetado al sistema de archivos local.
  /// Si el asset no existe (aún no generado por @back), no hace nada y la
  /// app continúa (el caller debe manejar el caso de BD vacía).
  Future<void> _copyAssetDb(File destFile) async {
    final bytes = await BibleSchemaVersion.assetDbBytes();
    if (bytes.isEmpty) {
      _log.warning(
        'Asset de biblia.db aún no generado por @back. '
        'La BD estará vacía hasta que se genere el archivo.',
      );
      return;
    }
    await destFile.writeAsBytes(bytes);
    _log.info(
      'biblia.db copiada a ${destFile.path} (${bytes.length} bytes)',
    );
  }

  /// Abre la BD con FFI y PRAGMA foreign_keys = ON.
  Future<Database> _openDatabasePlatform(String path) async {
    _ensureFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: kSchemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    await db.execute('PRAGMA foreign_keys = ON;');
    await _checkSqliteVersion(db);
    return db;
  }

  /// Abre una base de datos SQLite SIN gestión de versiones (raw mode).
  ///
  /// Útil para operaciones de backup/restore donde no se necesita onCreate/
  /// onUpgrade. Activa PRAGMA foreign_keys para mantener integridad
  /// referencial durante el restore.
  Future<Database> _openDatabaseRaw(String path) async {
    _ensureFfiInit();
    final db = await databaseFactoryFfi.openDatabase(path);
    await db.execute('PRAGMA foreign_keys = ON;');
    return db;
  }

  /// Crea una BD en memoria con el esquema aplicado. Usado en:
  /// - Modo debug desktop cuando `assets/db/biblia.db` aún no existe.
  /// - Tests como fallback de integración.
  Future<Database> _openInMemoryWithSchema() async {
    _ensureFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: kSchemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    await db.execute('PRAGMA foreign_keys = ON;');
    return db;
  }

  /// Inicializa el backend FFI una sola vez por proceso.
  static bool _ffiInitialized = false;
  static void _ensureFfiInit() {
    if (!_ffiInitialized) {
      sqfliteFfiInit();
      _ffiInitialized = true;
    }
  }

  /// Verifica versión de SQLite en runtime (>= 3.39 requerido para
  /// `remove_diacritics 2` de FTS5).
  Future<void> _checkSqliteVersion(Database db) async {
    try {
      final result = await db.rawQuery('SELECT sqlite_version() AS v');
      final versionStr = (result.first['v'] as String).trim();
      _log.info('SQLite version: $versionStr');

      final parts =
          versionStr.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      if (parts.length < 2) return;
      final major = parts[0];
      final minor = parts[1];
      if (major < 3 || (major == 3 && minor < 39)) {
        _log.warning(
          'SQLite $versionStr detectado. remove_diacritics 2 requiere 3.39+; '
          'la búsqueda acento-insensible puede fallar.',
        );
      }
    } catch (e) {
      _log.warning('No se pudo verificar la versión de SQLite: $e');
    }
  }

  /// Crea el esquema desde cero (DDL puro, equivalente a 001_biblia_schema.sql).
  ///
  /// NOTA: Esta función es la **fuente de verdad** del esquema en el cliente.
  /// Si se modifica el archivo `assets/db/schema/00X_*.sql`, hay que
  /// sincronizar este método (o ejecutar el SQL desde el asset directamente).
  /// Por simplicidad y consistencia con `DatabaseHelper` del himnario, el
  /// DDL vive aquí. Las migraciones se leen de
  /// `assets/db/schema/00X_*.sql` y se aplican en `_onUpgrade`.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON;');

    // ── version ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS version (
        id                 INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre             TEXT    NOT NULL UNIQUE,
        abreviatura        TEXT    NOT NULL UNIQUE,
        idioma             TEXT    NOT NULL,
        descripcion        TEXT,
        anio_publicacion   INTEGER,
        es_dominio_publico INTEGER NOT NULL DEFAULT 1 CHECK(es_dominio_publico IN (0, 1)),
        activa             INTEGER NOT NULL DEFAULT 1 CHECK(activa IN (0, 1))
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_version_activa ON version(activa);',
    );

    // ── libro ──────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS libro (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        version_id      INTEGER NOT NULL,
        nombre          TEXT    NOT NULL,
        abreviatura     TEXT    NOT NULL,
        testamento      TEXT    NOT NULL CHECK(testamento IN ('AT', 'NT')),
        numero          INTEGER NOT NULL CHECK(numero BETWEEN 1 AND 66),
        total_capitulos INTEGER NOT NULL CHECK(total_capitulos > 0),
        FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
        UNIQUE (version_id, numero)
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_libro_version ON libro(version_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_libro_testamento ON libro(testamento);',
    );

    // ── capitulo ───────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS capitulo (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        libro_id         INTEGER NOT NULL,
        numero           INTEGER NOT NULL CHECK(numero > 0),
        total_versiculos INTEGER NOT NULL CHECK(total_versiculos >= 0),
        FOREIGN KEY (libro_id) REFERENCES libro(id) ON DELETE CASCADE,
        UNIQUE (libro_id, numero)
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_capitulo_libro ON capitulo(libro_id);',
    );

    // ── versiculo ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS versiculo (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        capitulo_id INTEGER NOT NULL,
        numero      INTEGER NOT NULL CHECK(numero > 0),
        texto       TEXT    NOT NULL,
        FOREIGN KEY (capitulo_id) REFERENCES capitulo(id) ON DELETE CASCADE,
        UNIQUE (capitulo_id, numero)
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_versiculo_capitulo ON versiculo(capitulo_id);',
    );

    // ── versiculo_fts (FTS5 con contenido externo) ─────────────
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS versiculo_fts USING fts5(
        texto,
        content='versiculo',
        content_rowid='id',
        tokenize='unicode61 remove_diacritics 2'
      );
    ''');

    // Triggers: sincronizan versiculo → versiculo_fts
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

    // ── favorito_versiculo ─────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorito_versiculo (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        version_id     INTEGER NOT NULL,
        libro_id       INTEGER NOT NULL,
        capitulo       INTEGER NOT NULL CHECK(capitulo > 0),
        numero         INTEGER NOT NULL CHECK(numero > 0),
        fecha_agregado INTEGER NOT NULL,
        FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
        FOREIGN KEY (libro_id)   REFERENCES libro(id)   ON DELETE CASCADE,
        UNIQUE (version_id, libro_id, capitulo, numero)
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_favorito_lookup ON favorito_versiculo(version_id, libro_id, capitulo, numero);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_favorito_fecha ON favorito_versiculo(fecha_agregado DESC);',
    );

    // ── nota ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS nota (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        version_id          INTEGER NOT NULL,
        libro_id            INTEGER NOT NULL,
        capitulo            INTEGER NOT NULL CHECK(capitulo > 0),
        numero              INTEGER NOT NULL CHECK(numero > 0),
        contenido           TEXT    NOT NULL,
        color               TEXT    NOT NULL CHECK(color IN ('amarillo', 'verde', 'azul', 'ninguno')),
        fecha_creacion      INTEGER NOT NULL,
        fecha_modificacion  INTEGER NOT NULL,
        FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
        FOREIGN KEY (libro_id)   REFERENCES libro(id)   ON DELETE CASCADE,
        UNIQUE (version_id, libro_id, capitulo, numero)
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nota_lookup ON nota(version_id, libro_id, capitulo, numero);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_nota_fecha_mod ON nota(fecha_modificacion DESC);',
    );

    // Triggers de validación version_id ↔ libro_id
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

    // ── historial_versiculo ───────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS historial_versiculo (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        version_id     INTEGER NOT NULL,
        libro_id       INTEGER NOT NULL,
        capitulo       INTEGER NOT NULL CHECK(capitulo > 0),
        numero         INTEGER NOT NULL CHECK(numero > 0),
        fecha_lectura  INTEGER NOT NULL,
        FOREIGN KEY (version_id) REFERENCES version(id) ON DELETE CASCADE,
        FOREIGN KEY (libro_id)   REFERENCES libro(id)   ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_historial_fecha ON historial_versiculo(fecha_lectura DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_historial_lookup ON historial_versiculo(version_id, libro_id, capitulo, numero);',
    );

    // ── config ─────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS config (
        clave              TEXT PRIMARY KEY,
        valor              TEXT NOT NULL,
        fecha_modificacion INTEGER NOT NULL
      );
    ''');

    // ── schema_version ─────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schema_version (
        version          INTEGER PRIMARY KEY,
        descripcion      TEXT    NOT NULL,
        fecha_aplicacion INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      INSERT OR IGNORE INTO schema_version (version, descripcion, fecha_aplicacion)
      VALUES (1, 'Esquema inicial: 9 tablas + FTS5 + 7 triggers', strftime('%s', 'now'));
    ''');

    // ── cross_referencia (migración 004) ──────────────────────
    // Tabla para refs bíblicas FROM→TO con soporte de rangos en destino.
    // ~340k filas precargadas desde el dataset openbible (CC-BY 4.0).
    // Doc: assets/db/schema/004_cross_referencias.sql
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

    // Triggers de validación: coherencia version_id ↔ libro_id
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

    await db.execute('''
      INSERT OR IGNORE INTO schema_version (version, descripcion, fecha_aplicacion)
      VALUES (
        4,
        'Cross-references bíblicas: tabla cross_referencia con 2 FKs a libro, '
        || '2 índices (FROM, TO) + 1 índice por votos, 4 triggers de validación '
        || 'version_id ↔ libro_id. Seed: ~340k refs de openbible.info (CC-BY 4.0).',
        strftime('%s', 'now')
      );
    ''');
  }

  /// Aplica migraciones incrementales en base a `oldVersion`.
  ///
  /// Las migraciones se numeran consecutivamente y se ejecutan en orden:
  /// - v1 → v2: crea la tabla `cross_referencia` con sus índices, triggers
  ///   y registra la migración 004 en `schema_version` (cuerpo copiado
  ///   desde `assets/db/schema/004_cross_referencias.sql` para mantener
  ///   la fuente de verdad unificada con `_onCreate`).
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _log.info('onUpgrade biblia.db: v$oldVersion -> v$newVersion');

    // ── v1 → v2: cross_referencia (migración 004) ─────────────
    if (oldVersion < 2) {
      _log.info('Aplicando migración 004 (cross_referencia)...');
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
      await db.execute('''
        INSERT OR IGNORE INTO schema_version (version, descripcion, fecha_aplicacion)
        VALUES (
          4,
          'Cross-references bíblicas: tabla cross_referencia con 2 FKs a libro, '
          || '2 índices (FROM, TO) + 1 índice por votos, 4 triggers de validación '
          || 'version_id ↔ libro_id. Seed: ~340k refs de openbible.info (CC-BY 4.0).',
          strftime('%s', 'now')
        );
      ''');
    }

    // Futuras migraciones (v2 → v3, v3 → v4, ...) se agregan aquí
    // siguiendo el mismo patrón.
  }

  /// Cierra la conexión (usado en tests y al apagar la app).
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
