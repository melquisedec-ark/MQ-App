import 'package:logging/logging.dart';

import '../../core/enums/himno_tipo.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/categoria.dart';
import '../../domain/entities/estrofa.dart';
import '../../domain/entities/himno.dart';
import '../../domain/repositories/hymn_repository.dart';
import '../datasources/local/hymn_local_datasource.dart';

/// Implementación del repositorio de himnos.
///
/// Traduce las excepciones del datasource en Failure del dominio
/// y convierte modelos a entidades.
class HymnRepositoryImpl implements HymnRepository {
  static final _log = Logger('HymnRepositoryImpl');

  final HymnLocalDataSource _localDataSource;

  HymnRepositoryImpl({HymnLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? HymnLocalDataSource();

  @override
  Future<List<Himno>> searchHymns(
    String query, {
    HimnoTipo? tipo,
    String? orderBy,
    int? categoriaId,
  }) async {
    try {
      final models = await _localDataSource.searchHymns(
        query,
        tipo: tipo,
        orderBy: orderBy,
        categoriaId: categoriaId,
      );
      return models.map((m) => m.toEntity()).toList();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en searchHymns: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en searchHymns: $e');
      throw const DatabaseFailure('Error inesperado al buscar himnos');
    }
  }

  @override
  Future<Himno> getHymnById(int id) async {
    try {
      final model = await _localDataSource.getHymnById(id);
      return model.toEntity();
    } on NotFoundException catch (e) {
      throw NotFoundFailure(e.message);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getHymnById: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getHymnById: $e');
      throw const DatabaseFailure('Error inesperado al obtener himno');
    }
  }

  @override
  Future<List<Estrofa>> getStanzas(int versionPaisId) async {
    try {
      final models = await _localDataSource.getStanzas(versionPaisId);
      return models.map((m) => m.toEntity()).toList();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getStanzas: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getStanzas: $e');
      throw const DatabaseFailure('Error inesperado al obtener estrofas');
    }
  }

  @override
  Future<List<Categoria>> getCategories() async {
    try {
      final models = await _localDataSource.getCategories();
      return models.map((m) => m.toEntity()).toList();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getCategories: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getCategories: $e');
      throw const DatabaseFailure('Error inesperado al obtener categorías');
    }
  }

  @override
  Future<List<Himno>> getHymnsByCategory(int categoriaId) async {
    try {
      final models = await _localDataSource.getHymnsByCategory(categoriaId);
      return models.map((m) => m.toEntity()).toList();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getHymnsByCategory: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getHymnsByCategory: $e');
      throw const DatabaseFailure(
        'Error inesperado al obtener himnos por categoría',
      );
    }
  }

  @override
  Future<int> createHymn(
    Himno himno,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds,
  ) async {
    try {
      final himnoData = <String, dynamic>{
        'titulo_principal': himno.titulo,
        'numero_oficial': himno.numero,
        'tipo': himno.tipo.value,
        'activo': himno.activo ? 1 : 0,
      };

      return await _localDataSource.insertHymnCompleto(
        himnoData,
        versiones,
        estrofas,
        categoriaIds,
      );
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en createHymn: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en createHymn: $e');
      throw const DatabaseFailure('Error inesperado al crear himno');
    }
  }

  @override
  Future<void> updateHymn(
    Himno himno,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds,
  ) async {
    try {
      final himnoData = <String, dynamic>{
        'titulo_principal': himno.titulo,
        'numero_oficial': himno.numero,
        'tipo': himno.tipo.value,
        'activo': himno.activo ? 1 : 0,
      };

      await _localDataSource.updateHymnCompleto(
        himno.id,
        himnoData,
        versiones,
        estrofas,
        categoriaIds,
      );
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en updateHymn: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en updateHymn: $e');
      throw const DatabaseFailure('Error inesperado al actualizar himno');
    }
  }

  @override
  Future<void> deleteHymn(int id) async {
    try {
      await _localDataSource.deleteHymn(id);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en deleteHymn: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en deleteHymn: $e');
      throw const DatabaseFailure('Error inesperado al eliminar himno');
    }
  }

  @override
  Future<bool> hymnHasReferences(int himnoId) async {
    try {
      return await _localDataSource.hymnHasReferences(himnoId);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en hymnHasReferences: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en hymnHasReferences: $e');
      throw const DatabaseFailure(
        'Error inesperado al verificar referencias del himno',
      );
    }
  }

  @override
  Future<List<Categoria>> getAllCategorias() async {
    try {
      final models = await _localDataSource.getCategories();
      return models.map((m) => m.toEntity()).toList();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en getAllCategorias: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getAllCategorias: $e');
      throw const DatabaseFailure('Error inesperado al obtener categorías');
    }
  }

  @override
  Future<Categoria> createCategoria(String nombre) async {
    try {
      final model = await _localDataSource.createCategoria(nombre);
      return model.toEntity();
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en createCategoria: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en createCategoria: $e');
      throw const DatabaseFailure('Error inesperado al crear categoría');
    }
  }

  @override
  Future<void> deleteCategoria(int id) async {
    try {
      await _localDataSource.deleteCategoriaById(id);
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en deleteCategoria: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en deleteCategoria: $e');
      throw const DatabaseFailure('Error inesperado al eliminar categoría');
    }
  }

  @override
  @Deprecated('Usar ArregloRepositoryImpl.createArreglo en su lugar')
  Future<int> createArrangement({
    required int versionPaisId,
    required int usuarioId,
    required String nombreArreglo,
    required String tonalidadBase,
    required List<({String tipo, int orden, String contenido})> estrofas,
  }) async {
    try {
      return await _localDataSource.createArrangement(
        versionPaisId: versionPaisId,
        usuarioId: usuarioId,
        nombreArreglo: nombreArreglo,
        tonalidadBase: tonalidadBase,
        estrofas: estrofas,
      );
    } on DatabaseException catch (e) {
      _log.severe('DatabaseFailure en createArrangement: $e');
      throw DatabaseFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en createArrangement: $e');
      throw const DatabaseFailure('Error inesperado al crear arreglo');
    }
  }
}
