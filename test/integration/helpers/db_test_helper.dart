import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:himnario_id_2/core/database/database_helper.dart';
import 'package:himnario_id_2/core/utils/string_utils.dart';
import 'package:himnario_id_2/data/datasources/local/hymn_local_datasource.dart';
import 'package:himnario_id_2/data/repositories/hymn_repository_impl.dart';

/// Set para llevar registro de directorios temporales creados para limpieza.
final Set<Directory> _tempDirs = {};

/// Crea una base de datos aislada con el esquema completo exactamente igual
/// al que crea [DatabaseHelper._onCreate].
///
/// Cada invocación crea un directorio temporal único usando
/// [Directory.systemTemp.createTempSync] para evitar que sqflite_common_ffi
/// cachee y comparta la misma BD entre distintos tests.
Future<Database> createEmptyDatabase() async {
  final dir = Directory.systemTemp.createTempSync('himnario_test_');
  _tempDirs.add(dir);
  final dbPath = p.join(dir.path, 'test.db');
  final db = await databaseFactory.openDatabase(dbPath);

  // Habilitar claves foráneas (por defecto SQLite las tiene desactivadas).
  await db.execute('PRAGMA foreign_keys = ON');

  // ─── Himno ───
  await db.execute('''
    CREATE TABLE Himno (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo_principal TEXT NOT NULL,
      numero_oficial INTEGER,
      tipo INTEGER NOT NULL CHECK(tipo IN (1, 2, 3)),
      activo INTEGER NOT NULL DEFAULT 1,
      fecha_creacion TEXT NOT NULL DEFAULT (datetime('now'))
    );
  ''');
  // ─── Version_Pais ───
  await db.execute('''
    CREATE TABLE Version_Pais (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      himno_id INTEGER NOT NULL,
      pais TEXT NOT NULL,
      tonalidad_original TEXT NOT NULL,
      activo INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
    );
  ''');
  // ─── Estrofa ───
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
  // ─── Categoria ───
  await db.execute('''
    CREATE TABLE Categoria (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL UNIQUE
    );
  ''');
  // ─── Himno_Categoria ───
  await db.execute('''
    CREATE TABLE Himno_Categoria (
      himno_id INTEGER NOT NULL,
      categoria_id INTEGER NOT NULL,
      PRIMARY KEY (himno_id, categoria_id),
      FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE,
      FOREIGN KEY (categoria_id) REFERENCES Categoria(id) ON DELETE CASCADE
    );
  ''');
  // ─── Usuario ───
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
  // ─── Arreglo_Musical ───
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
  // ─── Estrofa_Arreglo ───
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
  // ─── Pista_Audio ───
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
  // ─── Configuracion ───
  await db.execute('''
    CREATE TABLE Configuracion (
      clave TEXT PRIMARY KEY,
      valor TEXT NOT NULL
    );
  ''');
  // ─── Fondo_Pantalla ───
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
  // ─── Historial_Reproduccion ───
  await db.execute('''
    CREATE TABLE Historial_Reproduccion (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      himno_id INTEGER NOT NULL,
      version_pais_id INTEGER,
      timestamp TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
    );
  ''');
  // ─── Himno_Busqueda ───
  await db.execute('''
    CREATE TABLE Himno_Busqueda (
      himno_id INTEGER PRIMARY KEY,
      titulo_normalizado TEXT NOT NULL DEFAULT '',
      contenido_normalizado TEXT NOT NULL DEFAULT '',
      FOREIGN KEY (himno_id) REFERENCES Himno(id) ON DELETE CASCADE
    );
  ''');
  await db.execute(
    'CREATE INDEX idx_busqueda_titulo ON Himno_Busqueda(titulo_normalizado);',
  );
  await db.execute(
    'CREATE INDEX idx_busqueda_contenido ON Himno_Busqueda(contenido_normalizado);',
  );
  // ─── Índices ───
  await db.execute('CREATE INDEX idx_himno_numero ON Himno(numero_oficial);');
  await db.execute('CREATE INDEX idx_version_himno ON Version_Pais(himno_id);');
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

  // ─── Vistas ───
  await db.execute('''
    CREATE VIEW IF NOT EXISTS v_himno_resumen AS
    SELECT
      h.id,
      h.titulo_principal,
      h.numero_oficial,
      h.tipo,
      h.activo,
      vp.pais,
      vp.tonalidad_original
    FROM Himno h
    LEFT JOIN Version_Pais vp ON vp.himno_id = h.id AND vp.activo = 1
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

  return db;
}

/// Inserta los mismos datos de semilla que [DatabaseHelper._seedData].
Future<void> seedDatabase(Database db) async {
  // Categorías
  await db.insert('Categoria', {'id': 1, 'nombre': 'Alabanza'});
  await db.insert('Categoria', {'id': 2, 'nombre': 'Adoración'});
  await db.insert('Categoria', {'id': 3, 'nombre': 'Fe'});

  // Usuario admin
  final adminHash = sha256.convert(utf8.encode('admin123')).toString();
  await db.insert('Usuario', {
    'id': 1,
    'username': 'admin',
    'password_hash': adminHash,
    'nombre': 'Administrador',
    'rol': 'Admin',
  });

  // Himno 1: Santo, Santo, Santo
  await db.insert('Himno', {
    'id': 1,
    'titulo_principal': 'Santo, Santo, Santo',
    'numero_oficial': 1,
    'tipo': 1,
    'activo': 1,
  });
  await db.insert('Version_Pais', {
    'id': 1,
    'himno_id': 1,
    'pais': 'El Salvador',
    'tonalidad_original': 'G',
    'activo': 1,
  });
  await db.insert('Estrofa', {
    'version_pais_id': 1,
    'tipo': 'Estrofa',
    'orden': 1,
    'contenido': '[G]¡Santo, [Em]Santo, [D]Santo! [G]Señor omni[G7]potente,',
  });
  await db.insert('Estrofa', {
    'version_pais_id': 1,
    'tipo': 'Estrofa',
    'orden': 2,
    'contenido': '[C]siempre el [G]labio [Em]mío [G]loores [D7]te dar[G]á.',
  });
  await db.insert('Himno_Categoria', {'himno_id': 1, 'categoria_id': 1});
  await db.insert('Himno_Categoria', {'himno_id': 1, 'categoria_id': 2});

  // Himno 2: Cuán grande es Dios
  await db.insert('Himno', {
    'id': 2,
    'titulo_principal': 'Cuán grande es Dios',
    'numero_oficial': 2,
    'tipo': 2,
    'activo': 1,
  });
  await db.insert('Version_Pais', {
    'id': 2,
    'himno_id': 2,
    'pais': 'El Salvador',
    'tonalidad_original': 'C',
    'activo': 1,
  });
  await db.insert('Estrofa', {
    'version_pais_id': 2,
    'tipo': 'Estrofa',
    'orden': 1,
    'contenido': '[C]El esplendor de un Rey, [G]vestido en Ma[Am]jestad',
  });
  await db.insert('Estrofa', {
    'version_pais_id': 2,
    'tipo': 'Coro',
    'orden': 2,
    'contenido': '[C]Cuán Grande es Dios, [G/B]cántale, [Am]Cuán grande es Dios',
  });
  await db.insert('Himno_Categoria', {'himno_id': 2, 'categoria_id': 1});

  // Himno 3: Grande es tu fidelidad
  await db.insert('Himno', {
    'id': 3,
    'titulo_principal': 'Grande es tu fidelidad',
    'numero_oficial': 3,
    'tipo': 1,
    'activo': 1,
  });
  await db.insert('Version_Pais', {
    'id': 3,
    'himno_id': 3,
    'pais': 'El Salvador',
    'tonalidad_original': 'C',
    'activo': 1,
  });
  await db.insert('Estrofa', {
    'version_pais_id': 3,
    'tipo': 'Estrofa',
    'orden': 1,
    'contenido': '[C]Oh, Dios Eterno, [Am]tu misericordia',
  });
  await db.insert('Estrofa', {
    'version_pais_id': 3,
    'tipo': 'Coro',
    'orden': 2,
    'contenido': '[F]¡Oh, Tu fidelidad! [G]¡Oh, Tu fidelidad!',
  });
  await db.insert('Himno_Categoria', {'himno_id': 3, 'categoria_id': 2});
  await db.insert('Himno_Categoria', {'himno_id': 3, 'categoria_id': 3});

  // ─── Himno_Busqueda (índice plano de búsqueda) ───
  await db.insert('Himno_Busqueda', {
    'himno_id': 1,
    'titulo_normalizado': StringUtils.normalizeForSearch('Santo, Santo, Santo'),
    'contenido_normalizado': StringUtils.normalizeForSearch(
      '[G]¡Santo, [Em]Santo, [D]Santo! [G]Señor omni[G7]potente, '
      '[C]siempre el [G]labio [Em]mío [G]loores [D7]te dar[G]á.',
    ),
  });
  await db.insert('Himno_Busqueda', {
    'himno_id': 2,
    'titulo_normalizado': StringUtils.normalizeForSearch('Cuán grande es Dios'),
    'contenido_normalizado': StringUtils.normalizeForSearch(
      '[C]El esplendor de un Rey, [G]vestido en Ma[Am]jestad '
      '[C]Cuán Grande es Dios, [G/B]cántale, [Am]Cuán grande es Dios',
    ),
  });
  await db.insert('Himno_Busqueda', {
    'himno_id': 3,
    'titulo_normalizado': StringUtils.normalizeForSearch('Grande es tu fidelidad'),
    'contenido_normalizado': StringUtils.normalizeForSearch(
      '[C]Oh, Dios Eterno, [Am]tu misericordia '
      '[F]¡Oh, Tu fidelidad! [G]¡Oh, Tu fidelidad!',
    ),
  });
}

/// Crea una base de datos con esquema completo + semilla y devuelve
/// un [HymnRepositoryImpl] listo para usar.
Future<({Database db, HymnRepositoryImpl repo})> createRepoWithSeed() async {
  final db = await createEmptyDatabase();
  await seedDatabase(db);

  final helper = DatabaseHelper.forTesting(db);
  final dataSource = HymnLocalDataSource(dbHelper: helper);
  final repo = HymnRepositoryImpl(localDataSource: dataSource);

  return (db: db, repo: repo);
}

/// Crea una base de datos con esquema completo (sin semilla) y devuelve
/// un [HymnRepositoryImpl] listo para usar.
Future<({Database db, HymnRepositoryImpl repo})> createRepoEmpty() async {
  final db = await createEmptyDatabase();

  final helper = DatabaseHelper.forTesting(db);
  final dataSource = HymnLocalDataSource(dbHelper: helper);
  final repo = HymnRepositoryImpl(localDataSource: dataSource);

  return (db: db, repo: repo);
}

/// Elimina todos los directorios temporales creados durante las pruebas.
///
/// Debe llamarse desde [tearDownAll] en los archivos de prueba.
Future<void> cleanupTestDatabases() async {
  for (final dir in _tempDirs) {
    try {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Ignorar errores de limpieza — no deben hacer fallar las pruebas.
    }
  }
  _tempDirs.clear();
}
