import '../entities/pais.dart';

/// Interfaz de repositorio para operaciones CRUD sobre países.
abstract class PaisRepository {
  /// Obtiene todos los países ordenados alfabéticamente.
  Future<List<Pais>> getAll();

  /// Crea un país con [nombre] y opcional [codigo].
  /// Retorna el ID autogenerado.
  Future<int> create({required String nombre, String? codigo});

  /// Actualiza los datos del país con [id].
  Future<void> update({required int id, required String nombre, String? codigo});

  /// Elimina el país con [id].
  Future<void> delete(int id);
}
