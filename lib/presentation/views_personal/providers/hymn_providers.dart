import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/enums/himno_tipo.dart';
import '../../../data/datasources/local/hymn_local_datasource.dart';
import '../../../data/repositories/hymn_repository_impl.dart';
import '../../../domain/entities/categoria.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/repositories/hymn_repository.dart';

/// Provider que actúa como versión para invalidar caché de himnos
/// cuando se modifican categorías, países u otros catálogos.
/// Incrementar este contador fuerza a hymnListProvider y hymnDetailProvider
/// a refetchear los datos.
final catalogVersionProvider = StateProvider<int>((ref) => 0);

/// Provider del repositorio de himnos (singleton).
final hymnRepositoryProvider = Provider<HymnRepository>((ref) {
  return HymnRepositoryImpl(
    localDataSource: HymnLocalDataSource(
      dbHelper: DatabaseHelper.instance,
    ),
  );
});

/// Parámetros de búsqueda para [hymnListProvider].
class HymnQueryParam {
  final String text;
  final HimnoTipo? tipo;
  final String? orderBy;
  final int? categoriaId;

  const HymnQueryParam({
    this.text = '',
    this.tipo,
    this.orderBy,
    this.categoriaId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HymnQueryParam &&
          text == other.text &&
          tipo == other.tipo &&
          orderBy == other.orderBy &&
          categoriaId == other.categoriaId;

  @override
  int get hashCode =>
      text.hashCode ^
      (tipo?.hashCode ?? 0) ^
      (orderBy?.hashCode ?? 0) ^
      (categoriaId?.hashCode ?? 0);
}

/// Provider que retorna la lista filtrada de himnos.
final hymnListProvider =
    FutureProvider.family<List<Himno>, HymnQueryParam>((ref, query) async {
  ref.watch(catalogVersionProvider); // Re-fetch when catalogs change
  final repo = ref.read(hymnRepositoryProvider);
  return repo.searchHymns(
    query.text,
    tipo: query.tipo,
    orderBy: query.orderBy,
    categoriaId: query.categoriaId,
  );
});

/// Provider que retorna el detalle de un himno por ID.
final hymnDetailProvider = FutureProvider.family<Himno, int>((ref, id) async {
  ref.watch(catalogVersionProvider); // Re-fetch when catalogs change
  final repo = ref.read(hymnRepositoryProvider);
  return repo.getHymnById(id);
});

/// Provider que retorna las estrofas de una versión de país.
final stanzasProvider =
    FutureProvider.family<List<Estrofa>, int>((ref, versionPaisId) async {
  final repo = ref.read(hymnRepositoryProvider);
  return repo.getStanzas(versionPaisId);
});

/// Provider que carga la lista completa de categorías desde la BD.
final categoriasProvider = FutureProvider<List<Categoria>>((ref) async {
  final repo = ref.read(hymnRepositoryProvider);
  return repo.getCategories();
});
