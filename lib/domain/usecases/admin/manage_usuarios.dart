import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/enums/usuario_rol.dart';
import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../../data/repositories/admin_repository_impl.dart';
import '../../entities/usuario.dart';
import '../../repositories/admin_repository.dart';

/// Caso de uso para obtener todos los usuarios.
class GetAllUsuariosUseCase {
  final AdminRepository _repository;
  GetAllUsuariosUseCase(this._repository);

  Future<List<Usuario>> execute() => _repository.getAllUsuarios();
}

/// Caso de uso para crear un usuario.
class CreateUsuarioUseCase {
  static final _log = Logger('CreateUsuarioUseCase');

  final AdminRepository _repository;
  CreateUsuarioUseCase(this._repository);

  Future<int> execute({
    required String username,
    required String passwordHash,
    required String nombre,
    required UsuarioRol rol,
  }) async {
    if (username.trim().isEmpty) {
      throw ArgumentError('El nombre de usuario no puede estar vacío');
    }
    if (nombre.trim().isEmpty) {
      throw ArgumentError('El nombre no puede estar vacío');
    }
    if (passwordHash.trim().isEmpty) {
      throw ArgumentError('La contraseña no puede estar vacía');
    }

    final usuario = Usuario(
      id: 0,
      username: username.trim(),
      passwordHash: passwordHash,
      nombre: nombre.trim(),
      rol: rol,
    );

    final id = await _repository.createUsuario(usuario);
    _log.info('Usuario "$nombre" creado con ID $id');
    return id;
  }
}

/// Caso de uso para actualizar un usuario.
class UpdateUsuarioUseCase {
  final AdminRepository _repository;
  UpdateUsuarioUseCase(this._repository);

  Future<void> execute(Usuario usuario) async {
    if (usuario.nombre.trim().isEmpty) {
      throw ArgumentError('El nombre no puede estar vacío');
    }
    await _repository.updateUsuario(usuario);
  }
}

/// Caso de uso para eliminar un usuario.
class DeleteUsuarioUseCase {
  final AdminRepository _repository;
  DeleteUsuarioUseCase(this._repository);

  Future<void> execute(int id) async {
    await _repository.deleteUsuario(id);
  }
}

final getAllUsuariosUseCaseProvider = Provider<GetAllUsuariosUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  final repository = AdminRepositoryImpl(dataSource);
  return GetAllUsuariosUseCase(repository);
});

final createUsuarioUseCaseProvider = Provider<CreateUsuarioUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  final repository = AdminRepositoryImpl(dataSource);
  return CreateUsuarioUseCase(repository);
});

final updateUsuarioUseCaseProvider = Provider<UpdateUsuarioUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  final repository = AdminRepositoryImpl(dataSource);
  return UpdateUsuarioUseCase(repository);
});

final deleteUsuarioUseCaseProvider = Provider<DeleteUsuarioUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  final repository = AdminRepositoryImpl(dataSource);
  return DeleteUsuarioUseCase(repository);
});
