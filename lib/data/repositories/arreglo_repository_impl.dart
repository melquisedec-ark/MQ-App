import 'package:logging/logging.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/arreglo_musical.dart';
import '../../domain/entities/estrofa_arreglo.dart';
import '../../domain/repositories/arreglo_repository.dart';
import '../datasources/local/arreglo_local_datasource.dart';
import '../models/arreglo_musical_model.dart';
import '../models/estrofa_arreglo_model.dart';

/// Implementación del repositorio de arreglos musicales.
///
/// Traduce las excepciones del datasource en [Failure] del dominio
/// y convierte modelos a entidades.
class ArregloRepositoryImpl implements ArregloRepository {
  static final _log = Logger('ArregloRepositoryImpl');

  final ArregloLocalDataSource _dataSource;

  ArregloRepositoryImpl(this._dataSource);

  @override
  Future<ArregloMusical> createArreglo(
    ArregloMusical arreglo,
    List<EstrofaArreglo> estrofas,
  ) async {
    try {
      final arregloModel = ArregloMusicalModel(
        id: arreglo.id,
        versionPaisId: arreglo.versionPaisId,
        usuarioId: arreglo.usuarioId,
        nombreArreglo: arreglo.nombreArreglo,
        tonalidadBase: arreglo.tonalidadBase,
        version: arreglo.version,
      );

      final estrofasModels = estrofas
          .map(
            (e) => EstrofaArregloModel(
              id: e.id,
              arregloMusicalId: e.arregloMusicalId,
              tipo: e.tipo.value,
              orden: e.orden,
              contenido: e.contenido,
            ),
          )
          .toList();

      final id = await _dataSource.createArreglo(arregloModel, estrofasModels);
      return arreglo.copyWith(id: id);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en createArreglo: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en createArreglo: $e');
      throw const DatabaseFailure('Error inesperado al crear arreglo');
    }
  }

  @override
  Future<List<ArregloMusical>> getArreglosByUser(int usuarioId) async {
    try {
      final models = await _dataSource.getByUser(usuarioId);
      return models.map((m) => m.toEntity()).toList();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getArreglosByUser: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getArreglosByUser: $e');
      throw const DatabaseFailure(
        'Error inesperado al obtener arreglos del usuario',
      );
    }
  }

  @override
  Future<ArregloMusical?> getArregloById(int id) async {
    try {
      final model = await _dataSource.getById(id);
      return model?.toEntity();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getArregloById: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getArregloById: $e');
      throw const DatabaseFailure(
        'Error inesperado al obtener arreglo por ID',
      );
    }
  }

  @override
  Future<List<EstrofaArreglo>> getEstrofasByArreglo(int arregloId) async {
    try {
      final models = await _dataSource.getEstrofasByArreglo(arregloId);
      return models.map((m) => m.toEntity()).toList();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getEstrofasByArreglo: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getEstrofasByArreglo: $e');
      throw const DatabaseFailure(
        'Error inesperado al obtener estrofas del arreglo',
      );
    }
  }

  @override
  Future<void> updateArreglo(
    ArregloMusical arreglo,
    List<EstrofaArreglo> estrofas,
  ) async {
    try {
      final arregloModel = ArregloMusicalModel(
        id: arreglo.id,
        versionPaisId: arreglo.versionPaisId,
        usuarioId: arreglo.usuarioId,
        nombreArreglo: arreglo.nombreArreglo,
        tonalidadBase: arreglo.tonalidadBase,
        version: arreglo.version,
      );

      final estrofasModels = estrofas
          .map((e) => EstrofaArregloModel(
                id: e.id,
                arregloMusicalId: e.arregloMusicalId,
                tipo: e.tipo.value,
                orden: e.orden,
                contenido: e.contenido,
              ),)
          .toList();

      await _dataSource.updateArreglo(arregloModel, estrofasModels);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en updateArreglo: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en updateArreglo: $e');
      throw const DatabaseFailure('Error inesperado al actualizar arreglo');
    }
  }

  @override
  Future<bool> deleteArreglo(int id) async {
    try {
      return await _dataSource.deleteArreglo(id);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en deleteArreglo: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en deleteArreglo: $e');
      throw const DatabaseFailure('Error inesperado al eliminar arreglo');
    }
  }
}
