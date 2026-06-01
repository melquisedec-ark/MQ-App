import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/errors/exceptions.dart' as exc;
import '../../models/usuario_model.dart';

/// DataSource local para usuarios usando SQLite.
/// Encapsula todas las consultas SQL a la tabla Usuario.
class UserLocalDataSource {
  static final _log = Logger('UserLocalDataSource');

  final DatabaseHelper _dbHelper;

  UserLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Obtiene la instancia de BD.
  Future<Database> get _db => _dbHelper.database;

  /// Busca un usuario por username y password_hash para autenticación.
  /// Retorna `null` si no se encuentra coincidencia.
  Future<UsuarioModel?> login(String username, String passwordHash) async {
    try {
      final db = await _db;
      final result = await db.query(
        'Usuario',
        where: 'username = ? AND password_hash = ?',
        whereArgs: [username, passwordHash],
      );

      if (result.isEmpty) {
        _log.info(
          'Intento de login fallido para usuario: $username',
        );
        return null;
      }

      final usuario = UsuarioModel.fromMap(result.first);
      _log.info('Login exitoso para usuario: $username');
      return usuario;
    } catch (e) {
      _log.severe('Error en login: $e');
      throw exc.DatabaseException(
        'Error al autenticar usuario: $e',
        query: 'login',
      );
    }
  }

  /// Inserta un nuevo usuario en la base de datos.
  /// Retorna el ID auto-generado del nuevo registro.
  Future<int> insert(UsuarioModel usuario) async {
    try {
      final db = await _db;
      // Para inserts nuevos, omitimos el id para que SQLite auto-incremente
      final id = await db.insert('Usuario', usuario.toMap(includeId: false));
      _log.info('Usuario creado con ID: $id');
      return id;
    } catch (e) {
      _log.severe('Error en insert: $e');
      throw exc.DatabaseException(
        'Error al insertar usuario: $e',
        query: 'insert',
      );
    }
  }

  /// Obtiene un usuario por su ID.
  /// Retorna `null` si no existe.
  Future<UsuarioModel?> getById(int id) async {
    try {
      final db = await _db;
      final result = await db.query(
        'Usuario',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) return null;

      return UsuarioModel.fromMap(result.first);
    } catch (e) {
      _log.severe('Error en getById: $e');
      throw exc.DatabaseException(
        'Error al obtener usuario por ID: $e',
        query: 'getById',
      );
    }
  }

  /// Obtiene todos los usuarios ordenados por nombre.
  Future<List<UsuarioModel>> getAll() async {
    try {
      final db = await _db;
      final result = await db.query(
        'Usuario',
        orderBy: 'nombre ASC',
      );

      return result.map((m) => UsuarioModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getAll: $e');
      throw exc.DatabaseException(
        'Error al obtener usuarios: $e',
        query: 'getAll',
      );
    }
  }

  /// Actualiza un usuario existente.
  /// Retorna el número de filas afectadas (debe ser 1).
  Future<int> update(UsuarioModel usuario) async {
    try {
      final db = await _db;
      final rowsAffected = await db.update(
        'Usuario',
        usuario.toMap(),
        where: 'id = ?',
        whereArgs: [usuario.id],
      );

      _log.info(
        'Usuario ID ${usuario.id} actualizado ($rowsAffected fila(s))',
      );
      return rowsAffected;
    } catch (e) {
      _log.severe('Error en update: $e');
      throw exc.DatabaseException(
        'Error al actualizar usuario: $e',
        query: 'update',
      );
    }
  }

  /// Elimina un usuario por su ID.
  /// Retorna el número de filas eliminadas (debe ser 1 si existía).
  Future<int> delete(int id) async {
    try {
      final db = await _db;
      final rowsAffected = await db.delete(
        'Usuario',
        where: 'id = ?',
        whereArgs: [id],
      );

      _log.info(
        'Usuario ID $id eliminado ($rowsAffected fila(s))',
      );
      return rowsAffected;
    } catch (e) {
      _log.severe('Error en delete: $e');
      throw exc.DatabaseException(
        'Error al eliminar usuario: $e',
        query: 'delete',
      );
    }
  }
}
