import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/himno_tipo.dart';
import '../../../core/errors/failures.dart';
import '../../entities/himno.dart';
import '../../repositories/hymn_repository.dart';
import '../../../data/repositories/hymn_repository_impl.dart';

/// Caso de uso para buscar himnos.
///
/// Encapsula la lógica de búsqueda de himnos por texto y filtro.
/// Es agnóstico a la implementación y recibe el repositorio por inyección.
class SearchHymnsUseCase {
  final HymnRepository _repository;

  SearchHymnsUseCase(this._repository);

  /// Ejecuta la búsqueda de himnos.
  ///
  /// [query] - texto a buscar (título o número)
  /// [tipo] - filtro opcional por tipo de himno
  ///
  /// Retorna [List<Himno>] en caso de éxito.
  /// Lanza [Failure] en caso de error.
  Future<List<Himno>> execute(String query, {HimnoTipo? tipo}) async {
    if (query.trim().isEmpty && tipo == null) {
      throw const InvalidArgumentFailure(
        'Debe proporcionar un término de búsqueda o un filtro',
      );
    }

    return await _repository.searchHymns(query.trim(), tipo: tipo);
  }
}

final searchHymnsUseCaseProvider = Provider<SearchHymnsUseCase>((ref) {
  final repository = HymnRepositoryImpl();
  return SearchHymnsUseCase(repository);
});
