import '../../../domain/entities/categoria.dart';
import '../../../domain/repositories/categoria_repository.dart';
import '../datasources/local/catalog_local_datasource.dart';

/// Implementación de [CategoriaRepository] usando [CatalogLocalDataSource].
class CategoriaRepositoryImpl implements CategoriaRepository {
  final CatalogLocalDataSource _dataSource;

  CategoriaRepositoryImpl(this._dataSource);

  @override
  Future<List<Categoria>> getAll() async {
    final models = await _dataSource.getAllCategorias();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> create(String nombre) => _dataSource.insertCategoria(nombre);

  @override
  Future<void> update(int id, String nombre) => _dataSource.updateCategoria(id, nombre);

  @override
  Future<void> delete(int id) => _dataSource.deleteCategoria(id);
}
