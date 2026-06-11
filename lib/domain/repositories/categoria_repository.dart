import '../entities/categoria.dart';

/// Interfaz de repositorio para operaciones CRUD sobre categorías.
abstract class CategoriaRepository {
  /// Obtiene todas las categorías ordenadas alfabéticamente.
  Future<List<Categoria>> getAll();

  /// Crea una categoría con el [nombre] dado.
  /// Retorna el ID autogenerado.
  Future<int> create(String nombre);

  /// Actualiza el nombre de la categoría con [id].
  Future<void> update(int id, String nombre);

  /// Elimina la categoría con [id].
  Future<void> delete(int id);
}
