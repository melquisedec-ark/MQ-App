import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import '../../core/enums/usuario_rol.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/user_local_datasource.dart';
import '../models/usuario_model.dart';

/// Implementación del repositorio de usuarios.
///
/// Traduce las excepciones del datasource en Failure del dominio,
/// hashea las contraseñas con SHA256 y convierte modelos a entidades.
class UserRepositoryImpl implements UserRepository {
  static final _log = Logger('UserRepositoryImpl');

  final UserLocalDataSource _dataSource;

  UserRepositoryImpl(this._dataSource);

  /// Genera el hash SHA256 de una contraseña.
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  @override
  Future<Usuario?> login(String username, String password) async {
    try {
      final hash = _hashPassword(password);
      final model = await _dataSource.login(username, hash);
      return model?.toEntity();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en login: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en login: $e');
      throw const DatabaseFailure('Error inesperado al iniciar sesión');
    }
  }

  @override
  Future<Usuario> create(Usuario usuario, String password) async {
    try {
      final hash = _hashPassword(password);
      final model = UsuarioModel(
        id: usuario.id,
        username: usuario.username,
        passwordHash: hash,
        nombre: usuario.nombre,
        rol: usuario.rol.value,
      );
      final id = await _dataSource.insert(model);
      _log.info('Usuario creado con ID $id: ${usuario.username}');
      return usuario.copyWith(id: id);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en create: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en create: $e');
      throw const DatabaseFailure('Error inesperado al crear usuario');
    }
  }

  @override
  Future<Usuario> update(Usuario usuario) async {
    try {
      // Obtener el modelo existente para preservar password_hash
      final existing = await _dataSource.getById(usuario.id);
      final model = UsuarioModel(
        id: usuario.id,
        username: usuario.username,
        passwordHash: existing?.passwordHash ?? '',
        nombre: usuario.nombre,
        rol: usuario.rol.value,
      );
      await _dataSource.update(model);
      _log.info('Usuario ID ${usuario.id} actualizado: ${usuario.username}');
      return usuario;
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en update: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en update: $e');
      throw const DatabaseFailure('Error inesperado al actualizar usuario');
    }
  }

  @override
  Future<bool> delete(int id) async {
    try {
      final rows = await _dataSource.delete(id);
      final deleted = rows > 0;
      if (deleted) {
        _log.info('Usuario ID $id eliminado correctamente');
      } else {
        _log.warning('Intento de eliminar usuario ID $id no encontrado');
      }
      return deleted;
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en delete: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en delete: $e');
      throw const DatabaseFailure('Error inesperado al eliminar usuario');
    }
  }

  @override
  Future<List<Usuario>> getAll() async {
    try {
      final models = await _dataSource.getAll();
      return models.map((m) => m.toEntity()).toList();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getAll: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getAll: $e');
      throw const DatabaseFailure('Error inesperado al obtener usuarios');
    }
  }

  // ─── Métodos legacy de la interfaz original ─────────────────────

  @override
  Future<Usuario> createUser(String nombre) async {
    try {
      final model = UsuarioModel(
        id: 0,
        username: nombre.toLowerCase().replaceAll(' ', '_'),
        passwordHash: _hashPassword('temporal123'),
        nombre: nombre,
        rol: 'Musico',
      );
      final id = await _dataSource.insert(model);
      _log.info('Usuario legacy creado con ID $id: $nombre');
      return Usuario(
        id: id,
        username: model.username,
        passwordHash: model.passwordHash,
        nombre: nombre,
        rol: UsuarioRol.musico,
      );
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en createUser: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en createUser: $e');
      throw const DatabaseFailure('Error inesperado al crear usuario');
    }
  }

  @override
  Future<Usuario?> getById(int id) async {
    try {
      final model = await _dataSource.getById(id);
      return model?.toEntity();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getById: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getById: $e');
      throw const DatabaseFailure('Error inesperado al obtener usuario');
    }
  }

  @override
  Future<Usuario?> getByName(String nombre) async {
    try {
      final users = await _dataSource.getAll();
      // Búsqueda case-insensitive por nombre
      final match = users.cast<UsuarioModel?>().firstWhere(
        (u) => u!.nombre.toLowerCase() == nombre.toLowerCase(),
        orElse: () => null,
      );
      return match?.toEntity();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getByName: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getByName: $e');
      throw const DatabaseFailure('Error inesperado al buscar usuario');
    }
  }
}
