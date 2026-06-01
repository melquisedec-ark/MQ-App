import 'package:logging/logging.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/fondo_pantalla.dart';
import '../../domain/repositories/fondo_repository.dart';
import '../datasources/local/catalog_local_datasource.dart';
import '../models/fondo_pantalla_model.dart';

/// Implementación del repositorio de fondos de pantalla.
///
/// Traduce las excepciones del datasource en [Failure] del dominio
/// y convierte modelos a entidades.
class FondoRepositoryImpl implements FondoRepository {
  static final _log = Logger('FondoRepositoryImpl');

  final CatalogLocalDataSource _dataSource;

  FondoRepositoryImpl(this._dataSource);

  @override
  Future<List<FondoPantalla>> getAll() async {
    try {
      final models = await _dataSource.getAllFondos();
      return models.map((m) => m.toEntity()).toList();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getAll: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getAll: $e');
      throw const DatabaseFailure(
        'Error inesperado al obtener fondos de pantalla',
      );
    }
  }

  @override
  Future<FondoPantalla?> getById(int id) async {
    try {
      final model = await _dataSource.getFondoById(id);
      return model?.toEntity();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getById: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getById: $e');
      throw const DatabaseFailure(
        'Error inesperado al obtener fondo por ID',
      );
    }
  }

  @override
  Future<FondoPantalla?> getDefault() async {
    try {
      final model = await _dataSource.getDefaultFondo();
      return model?.toEntity();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getDefault: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getDefault: $e');
      throw const DatabaseFailure(
        'Error inesperado al obtener fondo predeterminado',
      );
    }
  }

  @override
  Future<int> create(FondoPantalla fondo) async {
    try {
      final model = FondoPantallaModel(
        id: fondo.id,
        nombre: fondo.nombre,
        tipo: fondo.tipo.value,
        ruta_archivo: fondo.rutaArchivo,
        color_hex: fondo.colorHex,
        es_predeterminado: fondo.esPredeterminado ? 1 : 0,
        activo: fondo.activo ? 1 : 0,
      );
      return await _dataSource.insertFondo(model);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en create: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en create: $e');
      throw const DatabaseFailure(
        'Error inesperado al crear fondo de pantalla',
      );
    }
  }

  @override
  Future<void> update(FondoPantalla fondo) async {
    try {
      final model = FondoPantallaModel(
        id: fondo.id,
        nombre: fondo.nombre,
        tipo: fondo.tipo.value,
        ruta_archivo: fondo.rutaArchivo,
        color_hex: fondo.colorHex,
        es_predeterminado: fondo.esPredeterminado ? 1 : 0,
        activo: fondo.activo ? 1 : 0,
      );
      await _dataSource.updateFondo(model);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en update: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en update: $e');
      throw const DatabaseFailure(
        'Error inesperado al actualizar fondo de pantalla',
      );
    }
  }

  @override
  Future<bool> delete(int id) async {
    try {
      await _dataSource.deleteFondo(id);
      return true;
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en delete: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en delete: $e');
      throw const DatabaseFailure(
        'Error inesperado al eliminar fondo de pantalla',
      );
    }
  }
}
