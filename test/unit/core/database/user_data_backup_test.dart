import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:himnario_id_2/core/database/user_data_backup.dart';

void main() {
  // Inicializar sqflite_ffi para tests (no requiere plataforma nativa)
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('UserDataBackup — exportUserData', () {
    late Database db;
    late String dbPath;

    setUp(() async {
      final dir = Directory.systemTemp.createTempSync('backup_test_');
      dbPath = p.join(dir.path, 'test.db');
      db = await databaseFactory.openDatabase(dbPath);
      await _createSchema(db);
    });

    tearDown(() async {
      await db.close();
      // Limpiar archivo de BD
      final file = File(dbPath);
      if (file.existsSync()) await file.delete();
    });

    test('exporta tablas vacías como listas vacías', () async {
      final data = await UserDataBackup.exportUserData(db);
      expect(data.containsKey('Usuario'), isTrue);
      expect(data.containsKey('Fondo_Pantalla'), isTrue);
      expect(data['Usuario'], isEmpty);
      expect(data['Configuracion'], isEmpty);
    });

    test('exporta datos insertados correctamente', () async {
      // Insertar datos de prueba
      await db.insert('Usuario', {
        'username': 'test_user',
        'password_hash': 'abc123',
        'nombre': 'Test User',
        'rol': 'Musico',
      });
      await db.insert('Fondo_Pantalla', {
        'nombre': 'Fondo Azul',
        'tipo': 'color_solido',
        'color_hex': '#0000FF',
        'es_predeterminado': 1,
        'activo': 1,
      });
      await db.insert('Configuracion', {
        'clave': 'tema_oscuro',
        'valor': 'true',
      });

      final data = await UserDataBackup.exportUserData(db);

      expect(data['Usuario'], hasLength(1));
      expect(data['Usuario']![0]['username'], 'test_user');

      expect(data['Fondo_Pantalla'], hasLength(1));
      expect(data['Fondo_Pantalla']![0]['nombre'], 'Fondo Azul');

      expect(data['Configuracion'], hasLength(1));
      expect(data['Configuracion']![0]['clave'], 'tema_oscuro');
    });

    test('exporta múltiples filas de varias tablas', () async {
      // Usuario
      await db.insert('Usuario', {
        'username': 'user1',
        'password_hash': 'h1',
        'nombre': 'User 1',
        'rol': 'Admin',
      });
      await db.insert('Usuario', {
        'username': 'user2',
        'password_hash': 'h2',
        'nombre': 'User 2',
        'rol': 'Musico',
      });

      // Configuracion
      await db.insert('Configuracion', {'clave': 'k1', 'valor': 'v1'});
      await db.insert('Configuracion', {'clave': 'k2', 'valor': 'v2'});

      final data = await UserDataBackup.exportUserData(db);

      expect(data['Usuario'], hasLength(2));
      expect(data['Configuracion'], hasLength(2));
      // Las demás tablas deben estar vacías pero presentes
      expect(data['Fondo_Pantalla'], isEmpty);
      expect(data['Arreglo_Musical'], isEmpty);
      expect(data['Estrofa_Arreglo'], isEmpty);
      expect(data['Pista_Audio'], isEmpty);
      expect(data['Historial_Reproduccion'], isEmpty);
    });
  });

  group('UserDataBackup — importUserData', () {
    late Database db;
    late String dbPath;

    setUp(() async {
      final dir = Directory.systemTemp.createTempSync('restore_test_');
      dbPath = p.join(dir.path, 'test.db');
      db = await databaseFactory.openDatabase(dbPath);
      await _createSchema(db);
    });

    tearDown(() async {
      await db.close();
      final file = File(dbPath);
      if (file.existsSync()) await file.delete();
    });

    test('importa datos en BD vacía', () async {
      final data = <String, List<Map<String, dynamic>>>{
        'Usuario': [
          {
            'username': 'restored_user',
            'password_hash': 'hash123',
            'nombre': 'Restored',
            'rol': 'Visualizador',
          },
        ],
        'Configuracion': [
          {'clave': 'idioma', 'valor': 'es'},
        ],
      };

      await UserDataBackup.importUserData(db, data);

      final users = await db.query('Usuario');
      expect(users, hasLength(1));
      expect(users[0]['username'], 'restored_user');

      final configs = await db.query('Configuracion');
      expect(configs, hasLength(1));
      expect(configs[0]['valor'], 'es');
    });

    test('INSERT OR IGNORE evita duplicados', () async {
      // Primera importación
      final data1 = <String, List<Map<String, dynamic>>>{
        'Configuracion': [
          {'clave': 'tema', 'valor': 'oscuro'},
        ],
      };
      await UserDataBackup.importUserData(db, data1);

      // Segunda importación con la misma clave
      final data2 = <String, List<Map<String, dynamic>>>{
        'Configuracion': [
          {'clave': 'tema', 'valor': 'claro'},
        ],
      };
      await UserDataBackup.importUserData(db, data2);

      final configs = await db.query('Configuracion');
      // INSERT OR IGNORE → se mantiene el valor original
      expect(configs, hasLength(1));
      expect(configs[0]['valor'], 'oscuro');
    });

    test('importa relación completa Usuario→Arreglo_Musical', () async {
      // Primero exportar datos
      final userId = await db.insert('Usuario', {
        'username': 'musician',
        'password_hash': 'h',
        'nombre': 'Músico',
        'rol': 'Musico',
      });
      final arrId = await db.insert('Arreglo_Musical', {
        'version_pais_id': 1,
        'usuario_id': userId,
        'nombre_arreglo': 'Versión Acústica',
        'tonalidad_base': 'G',
      });

      final exported = await UserDataBackup.exportUserData(db);

      // Crear nueva BD
      await db.close();
      final file = File(dbPath);
      if (file.existsSync()) await file.delete();
      db = await databaseFactory.openDatabase(dbPath);
      await _createSchema(db);

      // Re-importar
      await UserDataBackup.importUserData(db, exported);

      final users = await db.query('Usuario');
      expect(users, hasLength(1));
      expect(users[0]['username'], 'musician');

      final arreglos = await db.query('Arreglo_Musical');
      expect(arreglos, hasLength(1));
      expect(arreglos[0]['nombre_arreglo'], 'Versión Acústica');
    });

    test('omite id AUTOINCREMENT en tablas de usuario', () async {
      // Exportar datos incluyendo id explícito
      final data = <String, List<Map<String, dynamic>>>{
        'Usuario': [
          {
            'id': 99, // id explícito que debería omitirse
            'username': 'id_test',
            'password_hash': 'h',
            'nombre': 'ID Test',
            'rol': 'Admin',
          },
        ],
      };

      await UserDataBackup.importUserData(db, data);

      final users = await db.query('Usuario');
      expect(users, hasLength(1));
      expect(users[0]['username'], 'id_test');
      // El id NO debería ser 99, SQLite lo re-asignó
      expect(users[0]['id'], isNot(99));
      expect(users[0]['id'], 1);
    });

    test('maneja datos vacíos sin errores', () async {
      await UserDataBackup.importUserData(db, {});
      await UserDataBackup.importUserData(db, {'Usuario': []});
      // Ninguna excepción debe lanzarse
      expect(true, isTrue);
    });
  });
}

/// Crea el esquema mínimo necesario para los tests de backup.
Future<void> _createSchema(Database db) async {
  // Desactivar FKs para tests de importación (las tablas padre de seed
  // data no siempre existen en el esquema reducido de test)
  await db.execute('PRAGMA foreign_keys = OFF');

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

  // Tablas padre necesarias para FKs en tablas de usuario
  await db.execute('''
    CREATE TABLE Himno (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      titulo_principal TEXT NOT NULL,
      tipo INTEGER NOT NULL CHECK(tipo IN (1, 2, 3)),
      activo INTEGER NOT NULL DEFAULT 1
    );
  ''');
  await db.execute('''
    CREATE TABLE Version_Pais (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      himno_id INTEGER NOT NULL,
      pais_id INTEGER,
      tonalidad_original TEXT NOT NULL DEFAULT 'C',
      activo INTEGER NOT NULL DEFAULT 1
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
}
