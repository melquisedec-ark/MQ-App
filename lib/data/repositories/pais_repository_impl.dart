import '../../domain/entities/pais.dart';
import '../../../domain/repositories/pais_repository.dart';
import '../datasources/local/catalog_local_datasource.dart';
import '../models/pais_model.dart';

/// Implementación de [PaisRepository] usando [CatalogLocalDataSource].
class PaisRepositoryImpl implements PaisRepository {
  final CatalogLocalDataSource _dataSource;

  PaisRepositoryImpl(this._dataSource);

  @override
  Future<List<Pais>> getAll() async {
    final models = await _dataSource.getAllPaises();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> create({required String nombre, String? codigo}) =>
      _dataSource.insertPais(nombre, codigo: codigo);

  @override
  Future<void> update({required int id, required String nombre, String? codigo}) =>
      _dataSource.updatePais(PaisModel(id: id, nombre: nombre, codigo: codigo));

  @override
  Future<void> delete(int id) => _dataSource.deletePais(id);
}
