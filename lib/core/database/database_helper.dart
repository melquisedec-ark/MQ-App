import 'dart:io' show Platform, File, Directory;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as desktop;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

import 'db_version_manager.dart';
/// Logger estructurado para eventos de base de datos.
final _log = Logger('DatabaseHelper');

/// Helper singleton para la gestión de la base de datos SQLite.
/// Encapsula la inicialización, migraciones y acceso a la BD.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  /// Creates a helper backed by an already-open database instance (for testing).
  /// The caller is responsible for creating the database with the proper schema.
  factory DatabaseHelper.forTesting(Database database) {
    final helper = DatabaseHelper._();
    helper._database = database;
    return helper;
  }

  Database? _database;

  /// Versión del esquema SQLite (migraciones de tabla/columna).
  ///
  /// SCHEMA_VERSION: controla las migraciones estructurales de la BD
  /// mediante onUpgrade(). Es independiente de la versión del asset
  /// (db_version.json) que controla actualizaciones de seed data.
  static const int SCHEMA_VERSION = 7;

  /// Obtiene la instancia de la base de datos, inicializándola si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos con respaldo y reemplazo completo.
  ///
  /// En primera instalacion copia la BD del asset directamente.
  /// En actualizaciones (assetVersion > localVersion) hace:
  ///   backup datos de usuario → reemplazar BD completa → restaurar datos
  ///
  /// Esto evita cualquier problema de merge o corrupcion de datos entre
  /// versiones, a costo de que el usuario pierda datos no respaldados
  /// como pistas de audio locales o historial detallado.
  Future<Database> _initDatabase() async {
    final stopwatch = Stopwatch()..start();

    // ── Modo desarrollo (desktop + debug): BD directa del proyecto ──
    if (kDebugMode && !Platform.isAndroid && !Platform.isIOS) {
      final projectDb = p.join(
        Directory.current.path,
        'assets/db/himnario_id.db',
      );
      _log.info('Debug mode: using project DB at $projectDb');
      final db = await _openDatabasePlatform(projectDb);
      _log.info(
        'Database opened (schema v$SCHEMA_VERSION) in '
        '${stopwatch.elapsedMilliseconds}ms',
      );
      return db;
    }

    // ── Modo release / mobile ───────────────────────────────────
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'himnario_id.db');
    final localFile = File(dbPath);

    // Leer versiones antes de tocar la BD
    final assetVersion = await DbVersionManager.readAssetVersion();
    final localVersion = await DbVersionManager.readLocalVersion(dir.path);

    if (!localFile.existsSync()) {
      // ── Primera instalacion: copiar BD del asset ──
      _log.info('No local DB found, copying from assets...');
      await _copyAssetDb(localFile);
    } else if (DbVersionManager.needsUpdate(assetVersion, localVersion)) {
      // ── Actualizacion: backup → reemplazar → restore ──
      _log.info(
        'DB update: assetVersion=$assetVersion > localVersion=$localVersion',
      );

      try {
        // 1. Backup datos de usuario desde la BD actual
        _log.info('Backing up user data...');
        final backup = await _backupUserData(dbPath);

        // 2. Cerrar conexion actual y reemplazar BD
        await _database?.close();
        _database = null;
        await localFile.delete();
        await _copyAssetDb(localFile);

        // 3. Restaurar datos de usuario sobre la BD nueva
        final newDb = await _openDatabaseRaw(dbPath);
        await newDb.execute('PRAGMA user_version = $SCHEMA_VERSION;');
        await _restoreUserData(newDb, backup);
        await newDb.close();

        _log.info('DB replacement complete — user data restored');
      } catch (e) {
        _log.severe('Failed to replace DB: $e');
        // Si falla, la app continua con la BD nueva sin datos de usuario.
        // Es preferible a tener una BD corrupta con datos inconsistentes.
      }
    }

    // Abrir BD (actualizada o existente)
    final db = await _openDatabasePlatform(dbPath);

    // Escribir version local
    if (assetVersion > 0) {
      await DbVersionManager.writeLocalVersion(dir.path, assetVersion);
    }

    _log.info(
      'Database opened (schema v$SCHEMA_VERSION) in '
      '${stopwatch.elapsedMilliseconds}ms',
    );
    return db;
  }

  /// Respaldar datos de usuario antes de reemplazar la BD.
  ///
  /// Abre la BD actual en modo raw (sin gestion de versiones) y
  /// extrae todas las tablas de usuario para restaurarlas luego.
  Future<Map<String, List<Map<String, dynamic>>>> _backupUserData(
    String dbPath,
  ) async {
    final db = await _openDatabaseRaw(dbPath);
    try {
      final backup = <String, List<Map<String, dynamic>>>{
        'Usuario': await db.query('Usuario'),
        'Configuracion': await db.query('Configuracion'),
        'Fondo_Pantalla': await db.query('Fondo_Pantalla'),
        'Arreglo_Musical': await db.query('Arreglo_Musical'),
        'Estrofa_Arreglo': await db.query('Estrofa_Arreglo'),
        'Historial_Reproduccion': await db.query('Historial_Reproduccion'),
      };
      _log.info(
        'Backup: ${backup['Usuario']!.length} users, '
        '${backup['Configuracion']!.length} configs, '
        '${backup['Fondo_Pantalla']!.length} backgrounds, '
        '${backup['Arreglo_Musical']!.length} arrangements, '
        '${backup['Estrofa_Arreglo']!.length} stanzas, '
        '${backup['Historial_Reproduccion']!.length} history',
      );
      return backup;
    } finally {
      await db.close();
    }
  }

  /// Restaurar datos de usuario en la BD recien copiada del asset.
  ///
  /// El orden respeta las FK:
  ///   1. Configuracion (sin FK)
  ///   2. Usuario (sin FK, referenciado por Arreglo_Musical)
  ///   3. Fondo_Pantalla (sin FK)
  ///   4. Arreglo_Musical (FK: usuario_id, version_pais_id)
  ///   5. Estrofa_Arreglo (FK: arreglo_musical_id)
  ///   6. Historial_Reproduccion (FK: himno_id)
  Future<void> _restoreUserData(
    Database db,
    Map<String, List<Map<String, dynamic>>> backup,
  ) async {
    // Desactivar FK temporalmente para evitar errores de orden
    await db.execute('PRAGMA foreign_keys = OFF;');
    try {
      int count = 0;

      for (final row in backup['Configuracion'] ?? []) {
        await db.insert('Configuracion', row,
            conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }
      for (final row in backup['Usuario'] ?? []) {
        await db.insert('Usuario', row,
            conflictAlgorithm: ConflictAlgorithm.ignore);
        count++;
      }
      for (final row in backup['Fondo_Pantalla'] ?? []) {
        await db.insert('Fondo_Pantalla', row,
            conflictAlgorithm: ConflictAlgorithm.ignore);
        count++;
      }
      for (final row in backup['Arreglo_Musical'] ?? []) {
        await db.insert('Arreglo_Musical', row,
            conflictAlgorithm: ConflictAlgorithm.ignore);
        count++;
      }
      for (final row in backup['Estrofa_Arreglo'] ?? []) {
        await db.insert('Estrofa_Arreglo', row,
            conflictAlgorithm: ConflictAlgorithm.ignore);
        count++;
      }
      for (final row in backup['Historial_Reproduccion'] ?? []) {
        await db.insert('Historial_Reproduccion', row,
            conflictAlgorithm: ConflictAlgorithm.ignore);
        count++;
      }

      _log.info('Restore complete: $count records restored');
    } finally {
      await db.execute('PRAGMA foreign_keys = ON;');
    }
  }

  /// Copia la BD del asset empaquetado al sistema de archivos local.
  Future<void> _copyAssetDb(File destFile) async {
    final bytes = await DbVersionManager.assetDbBytes();
    if (bytes.isEmpty) {
      _log.warning('Asset DB is empty, DB schema will be created fresh');
      return;
    }
    await destFile.writeAsBytes(bytes);
    _log.info('Asset DB copied to ${destFile.path} (${bytes.length} bytes)');
  }

  /// Abre una base de datos SQLite sin gestión de versiones.
  ///
  /// Útil para operaciones de backup/restore donde no se necesita
  /// onCreate/onUpgrade. Activa PRAGMA foreign_keys para mantener
  /// integridad referencial durante el restore.
  Future<Database> _openDatabaseRaw(String path) async {
    final Database db;
    if (Platform.isAndroid || Platform.isIOS) {
      db = await mobile.openDatabase(path);
    } else {
      desktop.sqfliteFfiInit();
      db = await desktop.databaseFactoryFfi.openDatabase(path);
    }
    await db.execute('PRAGMA foreign_keys = ON;');
    return db;
  }

  /// Abre una base de datos SQLite con gestión completa de versiones
  /// (onCreate + onUpgrade), seleccionando automáticamente el backend
  /// adecuado según la plataforma.
  Future<Database> _openDatabasePlatform(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await mobile.openDatabase(
        path,
        version: SCHEMA_VERSION,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      desktop.sqfliteFfiInit();
      return await desktop.databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: SCHEMA_VERSION,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    // ─── TABLAS ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE Himno (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo_principal TEXT NOT NULL,
        numero_oficial INTEGER,
        tipo INTEGER NOT NULL CHECK(tipo IN (1, 2, 3)),
        evento TEXT,
        activo INTEGER NOT NULL DEFAULT 1,
        fecha_creacion TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');

    await db.execute('''
      CREATE TABLE Pais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        codigo TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE Version_Pais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        himno_id INTEGER NOT NULL,
        pais_id INTEGER NOT NULL REFERENCES Pais(id),
        tonalidad_original TEXT NOT NULL DEFAULT 'C',
        activo INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Estrofa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_pais_id INTEGER NOT NULL,
        tipo TEXT NOT NULL CHECK(tipo IN ('Coro', 'Estrofa', 'Puente', 'Intro', 'Final')),
        orden INTEGER NOT NULL,
        contenido TEXT NOT NULL,
        FOREIGN KEY (version_pais_id) REFERENCES Version_Pais(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      );
    ''');

    await db.execute('''
      CREATE TABLE Himno_Categoria (
        himno_id INTEGER NOT NULL,
        categoria_id INTEGER NOT NULL,
        PRIMARY KEY (himno_id, categoria_id),
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE,
        FOREIGN KEY (categoria_id) REFERENCES Categoria(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        nombre TEXT NOT NULL,
        rol TEXT NOT NULL DEFAULT 'Musico' CHECK(rol IN ('Admin', 'Musico', 'Visualizador')),
        fecha_registro TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');

    await db.execute('''
      CREATE TABLE Arreglo_Musical (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_pais_id INTEGER NOT NULL,
        usuario_id INTEGER NOT NULL,
        nombre_arreglo TEXT NOT NULL,
        tonalidad_base TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        fecha_creacion TEXT NOT NULL DEFAULT (datetime('now')),
        fecha_modificacion TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (version_pais_id) REFERENCES Version_Pais(id) ON DELETE CASCADE,
        FOREIGN KEY (usuario_id) REFERENCES Usuario(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Estrofa_Arreglo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        arreglo_musical_id INTEGER NOT NULL,
        tipo TEXT NOT NULL CHECK(tipo IN ('Coro', 'Estrofa', 'Puente', 'Intro', 'Final')),
        orden INTEGER NOT NULL,
        contenido TEXT NOT NULL,
        FOREIGN KEY (arreglo_musical_id) REFERENCES Arreglo_Musical(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE Pista_Audio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        himno_id INTEGER NOT NULL,
        ruta_archivo TEXT NOT NULL,
        descripcion TEXT,
        origen TEXT NOT NULL DEFAULT 'local',
        duracion_segundos REAL,
        formato TEXT,
        usuario_donante_id INTEGER,
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE,
        FOREIGN KEY (usuario_donante_id) REFERENCES Usuario(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Configuracion (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Fondo_Pantalla (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'color_solido')),
        ruta_archivo TEXT,
        color_hex TEXT,
        es_predeterminado INTEGER NOT NULL DEFAULT 0,
        activo INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE Historial_Reproduccion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        himno_id INTEGER NOT NULL,
        version_pais_id INTEGER,
        timestamp TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
      );
    ''');

    // ─── Himno_Busqueda (índice plano de búsqueda) ───
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Himno_Busqueda (
        himno_id INTEGER PRIMARY KEY,
        titulo_normalizado TEXT NOT NULL DEFAULT '',
        contenido_normalizado TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_busqueda_titulo ON Himno_Busqueda(titulo_normalizado);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_busqueda_contenido ON Himno_Busqueda(contenido_normalizado);',
    );

    // Crear índices
    await db.execute('CREATE INDEX idx_himno_numero ON Himno(numero_oficial);');
    await db
        .execute('CREATE INDEX idx_version_himno ON Version_Pais(himno_id);');
    await db.execute(
      'CREATE UNIQUE INDEX idx_version_pais_unica ON Version_Pais(himno_id, pais_id);',
    );
    await db.execute(
      'CREATE INDEX idx_estrofa_version ON Estrofa(version_pais_id, orden);',
    );
    await db.execute(
      'CREATE INDEX idx_arreglo_usuario ON Arreglo_Musical(usuario_id);',
    );
    await db.execute(
      'CREATE INDEX idx_estrofa_arreglo ON Estrofa_Arreglo(arreglo_musical_id, orden);',
    );
    await db.execute('CREATE INDEX idx_pista_himno ON Pista_Audio(himno_id);');
    await db.execute(
      'CREATE INDEX idx_historial_timestamp ON Historial_Reproduccion(timestamp DESC);',
    );
    await db.execute('CREATE INDEX idx_himno_activo ON Himno(activo);');
    await db.execute(
      'CREATE INDEX idx_hc_categoria ON Himno_Categoria(categoria_id);',
    );

    // Crear vistas
    await db.execute('''
      CREATE VIEW IF NOT EXISTS v_himno_resumen AS
      SELECT
        h.id,
        h.titulo_principal,
        h.numero_oficial,
        h.tipo,
        h.activo,
        p.nombre AS pais,
        vp.tonalidad_original
      FROM Himno h
      LEFT JOIN Version_Pais vp ON vp.himno_id = h.id AND vp.activo = 1
      LEFT JOIN Pais p ON p.id = vp.pais_id
      ORDER BY h.numero_oficial;
    ''');

    await db.execute('''
      CREATE VIEW IF NOT EXISTS v_himno_estrofas AS
      SELECT
        vp.himno_id,
        vp.id AS version_pais_id,
        COUNT(e.id) AS total_estrofas,
        SUM(CASE WHEN e.tipo = 'Coro' THEN 1 ELSE 0 END) AS total_coros
      FROM Version_Pais vp
      LEFT JOIN Estrofa e ON e.version_pais_id = vp.id
      GROUP BY vp.himno_id, vp.id;
    ''');

  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migración de versión 1 a 2:
      // Agregar columnas username y password_hash a Usuario
      await db.execute('ALTER TABLE Usuario ADD COLUMN username TEXT');
      await db.execute('ALTER TABLE Usuario ADD COLUMN password_hash TEXT');

      // Crear tabla Fondo_Pantalla
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Fondo_Pantalla (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'color_solido')),
          ruta_archivo TEXT,
          color_hex TEXT,
          es_predeterminado INTEGER NOT NULL DEFAULT 0,
          activo INTEGER NOT NULL DEFAULT 1
        );
      ''');
    }

    if (oldVersion < 3) {
      // Migración de versión 2 a 3:
      // 1. Crear tabla Pais y poblar con países existentes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Pais (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL UNIQUE,
          codigo TEXT
        );
      ''');

      await db.execute('''
        INSERT OR IGNORE INTO Pais (nombre)
        SELECT DISTINCT pais FROM Version_Pais;
      ''');

      // 2. Agregar columna pais_id a Version_Pais
      await db.execute('ALTER TABLE Version_Pais ADD COLUMN pais_id INTEGER');

      // 3. Migrar datos: asociar cada fila al país correspondiente
      await db.execute('''
        UPDATE Version_Pais
        SET pais_id = (SELECT id FROM Pais WHERE Pais.nombre = Version_Pais.pais)
        WHERE pais_id IS NULL;
      ''');

      // 4. Reemplazar índice único (pasa de pais TEXT a pais_id INTEGER)
      await db.execute('DROP INDEX IF EXISTS idx_version_pais_unica');
      await db.execute('''
        CREATE UNIQUE INDEX idx_version_pais_unica ON Version_Pais(himno_id, pais_id);
      ''');

      // 5. Eliminar la columna vieja pais (TEXT NOT NULL) que ya no se usa
      //    SQLite 3.35.0+ soporta DROP COLUMN
      await db.execute('DROP INDEX IF EXISTS idx_version_himno');
      try {
        await db.execute('ALTER TABLE Version_Pais DROP COLUMN pais');
      } catch (_) {
        // Si la versión de SQLite no soporta DROP COLUMN, se ignora
        // La columna obsoleta se mantendrá pero no se usará en el código nuevo
      }
      await db.execute('CREATE INDEX IF NOT EXISTS idx_version_himno ON Version_Pais(himno_id)');

      // 6. Recrear vistas afectadas
      await db.execute('DROP VIEW IF EXISTS v_himno_resumen');
      await db.execute('''
        CREATE VIEW IF NOT EXISTS v_himno_resumen AS
        SELECT
          h.id,
          h.titulo_principal,
          h.numero_oficial,
          h.tipo,
          h.activo,
          p.nombre AS pais,
          vp.tonalidad_original
        FROM Himno h
        LEFT JOIN Version_Pais vp ON vp.himno_id = h.id AND vp.activo = 1
        LEFT JOIN Pais p ON p.id = vp.pais_id
        ORDER BY h.numero_oficial;
      ''');

      await db.execute('DROP VIEW IF EXISTS v_himno_estrofas');
      await db.execute('''
        CREATE VIEW IF NOT EXISTS v_himno_estrofas AS
        SELECT
          vp.himno_id,
          vp.id AS version_pais_id,
          COUNT(e.id) AS total_estrofas,
          SUM(CASE WHEN e.tipo = 'Coro' THEN 1 ELSE 0 END) AS total_coros
        FROM Version_Pais vp
        LEFT JOIN Estrofa e ON e.version_pais_id = vp.id
        GROUP BY vp.himno_id, vp.id;
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Himno_Busqueda (
          himno_id INTEGER PRIMARY KEY,
          titulo_normalizado TEXT NOT NULL DEFAULT '',
          contenido_normalizado TEXT NOT NULL DEFAULT '',
          FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_busqueda_titulo ON Himno_Busqueda(titulo_normalizado);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_busqueda_contenido ON Himno_Busqueda(contenido_normalizado);',
      );
    }

    if (oldVersion < 5) {
      // Migración de versión 4 a 5:
      // Agregar columna evento a Himno (para registrar a qué evento pertenece el himno)
      try {
        await db.execute('ALTER TABLE Himno ADD COLUMN evento TEXT');
      } catch (_) {
        // Si la columna ya existe (ej: BD ya modificada directamente), ignorar
      }
    }

    if (oldVersion < 6) {
      // Migración de versión 5 a 6:
      // Eliminar 'video' del CHECK constraint de Fondo_Pantalla.tipo
      // (FondoPantallaTipo.video fue eliminado del enum Dart)
      // SQLite no permite ALTER CHECK, así que se recrea la tabla.
      await db.execute('DELETE FROM Fondo_Pantalla WHERE tipo = \'video\'');
      await db.execute('''
        CREATE TABLE Fondo_Pantalla_v6 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          tipo TEXT NOT NULL CHECK(tipo IN ('imagen', 'color_solido')),
          ruta_archivo TEXT,
          color_hex TEXT,
          es_predeterminado INTEGER NOT NULL DEFAULT 0,
          activo INTEGER NOT NULL DEFAULT 1
        );
      ''');
      await db.execute(
        'INSERT INTO Fondo_Pantalla_v6 SELECT * FROM Fondo_Pantalla',
      );
      await db.execute('DROP TABLE Fondo_Pantalla');
      await db.execute('ALTER TABLE Fondo_Pantalla_v6 RENAME TO Fondo_Pantalla');
    }

    if (oldVersion < 7) {
      // Forzar reindexación del contenido de búsqueda para ignorar acordes ChordPro.
      // La tabla Himno_Busqueda se reconstruye automáticamente en el próximo
      // searchHymns() vía _doInitializeSearchIndex().
      await db.execute('DELETE FROM Himno_Busqueda');
    }
  }

  /// Guarda un valor en la tabla Configuracion.
  /// Si la clave ya existe, la actualiza.
  Future<void> setConfig(String key, String value) async {
    final db = await database;
    await db.insert(
      'Configuracion',
      {'clave': key, 'valor': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lee un valor de la tabla Configuracion.
  /// Retorna `null` si la clave no existe.
  Future<String?> getConfig(String key) async {
    final db = await database;
    final result = await db.query(
      'Configuracion',
      where: 'clave = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['valor'] as String;
  }
}
