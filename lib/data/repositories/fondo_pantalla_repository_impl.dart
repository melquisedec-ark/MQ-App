import '../../core/enums/fondo_pantalla_tipo.dart';
import '../../domain/entities/fondo_pantalla.dart';
import '../../domain/repositories/fondo_pantalla_repository.dart';
import '../datasources/local/catalog_local_datasource.dart';
import '../models/fondo_pantalla_model.dart';

/// Implementación de [FondoPantallaRepository] usando [CatalogLocalDataSource].
class FondoPantallaRepositoryImpl implements FondoPantallaRepository {
  final CatalogLocalDataSource _dataSource;

  FondoPantallaRepositoryImpl(this._dataSource);

  @override
  Future<List<FondoPantalla>> getAll() async {
    final models = await _dataSource.getAllFondos();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<FondoPantalla?> getById(int id) async {
    final model = await _dataSource.getFondoById(id);
    return model?.toEntity();
  }

  @override
  Future<int> create({
    required String nombre,
    required FondoPantallaTipo tipo,
    String? rutaArchivo,
    String? colorHex,
    bool esPredeterminado = false,
    bool activo = true,
  }) {
    final model = FondoPantallaModel(
      id: 0,
      nombre: nombre,
      tipo: tipo.value,
      ruta_archivo: rutaArchivo,
      color_hex: colorHex,
      es_predeterminado: esPredeterminado ? 1 : 0,
      activo: activo ? 1 : 0,
    );
    return _dataSource.insertFondo(model);
  }

  @override
  Future<void> update({
    required int id,
    required String nombre,
    required FondoPantallaTipo tipo,
    String? rutaArchivo,
    String? colorHex,
    required bool esPredeterminado,
    required bool activo,
  }) {
    final model = FondoPantallaModel(
      id: id,
      nombre: nombre,
      tipo: tipo.value,
      ruta_archivo: rutaArchivo,
      color_hex: colorHex,
      es_predeterminado: esPredeterminado ? 1 : 0,
      activo: activo ? 1 : 0,
    );
    return _dataSource.updateFondo(model);
  }

  @override
  Future<void> delete(int id) => _dataSource.deleteFondo(id);
}
