import '../entities/usuario.dart';

/// Repositorio administrativo para CRUD de catálogos del sistema.
///
/// Define el contrato para operaciones administrativas sobre entidades
/// como usuarios, países, categorías, etc.
abstract class AdminRepository {
  /// Obtiene todos los usuarios.
  Future<List<Usuario>> getAllUsuarios();

  /// Crea un nuevo usuario y retorna su ID.
  Future<int> createUsuario(Usuario usuario);

  /// Actualiza un usuario existente.
  Future<void> updateUsuario(Usuario usuario);

  /// Elimina un usuario por su ID.
  Future<void> deleteUsuario(int id);
}
