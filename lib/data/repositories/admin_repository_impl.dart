import '../../domain/entities/usuario.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/local/catalog_local_datasource.dart';
import '../models/usuario_model.dart';

/// Implementación del [AdminRepository] usando [CatalogLocalDataSource].
class AdminRepositoryImpl implements AdminRepository {
  final CatalogLocalDataSource _localDataSource;

  AdminRepositoryImpl(this._localDataSource);

  @override
  Future<List<Usuario>> getAllUsuarios() async {
    final models = await _localDataSource.getAllUsuarios();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> createUsuario(Usuario usuario) async {
    final model = UsuarioModel(
      id: 0,
      username: usuario.username,
      passwordHash: usuario.passwordHash,
      nombre: usuario.nombre,
      rol: usuario.rol.value,
    );
    return await _localDataSource.insertUsuario(model);
  }

  @override
  Future<void> updateUsuario(Usuario usuario) async {
    final model = UsuarioModel(
      id: usuario.id,
      username: usuario.username,
      passwordHash: usuario.passwordHash,
      nombre: usuario.nombre,
      rol: usuario.rol.value,
    );
    await _localDataSource.updateUsuario(model);
  }

  @override
  Future<void> deleteUsuario(int id) async {
    await _localDataSource.deleteUsuario(id);
  }
}
