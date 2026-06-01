import '../entities/usuario.dart';

/// Repositorio de usuarios.
/// Define el contrato para la gestión de usuarios del sistema de arreglos.
abstract class UserRepository {
  /// Crea un nuevo usuario.
  Future<Usuario> createUser(String nombre);

  /// Obtiene un usuario por su ID.
  Future<Usuario?> getById(int id);

  /// Obtiene un usuario por su nombre.
  Future<Usuario?> getByName(String nombre);

  /// Autentica un usuario con username y contraseña.
  /// Retorna `null` si las credenciales son inválidas.
  Future<Usuario?> login(String username, String password);

  /// Crea un nuevo usuario con contraseña hasheada.
  Future<Usuario> create(Usuario usuario, String password);

  /// Actualiza los datos de un usuario existente.
  Future<Usuario> update(Usuario usuario);

  /// Elimina un usuario por su ID.
  /// Retorna `true` si se eliminó correctamente.
  Future<bool> delete(int id);

  /// Obtiene todos los usuarios del sistema.
  Future<List<Usuario>> getAll();
}
