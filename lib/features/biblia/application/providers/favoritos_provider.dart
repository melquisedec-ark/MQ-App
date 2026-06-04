import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/favorito_versiculo.dart';
import '../../data/repositories/favoritos_repository.dart';
import 'biblia_version_provider.dart';
import 'current_libro_provider.dart';

/// Provider del `FavoritosRepository`. Reusa el `bibleDatabaseHelperProvider`
/// para que tests puedan overridear la BD.
final favoritosRepositoryProvider = Provider<FavoritosRepository>((ref) {
  final db = ref.watch(bibleDatabaseHelperProvider);
  return FavoritosRepository(db);
});

/// Stream reactivo de todos los favoritos, filtrados por la versión actual.
/// Se re-emite automáticamente cuando la tabla `favorito_versiculo` cambia.
final favoritosStreamProvider = StreamProvider<List<FavoritoVersiculo>>((ref) {
  final versionId = ref.watch(currentVersionIdProvider);
  final repo = ref.watch(favoritosRepositoryProvider);
  return repo.watchAll(versionId: versionId);
});

/// Map: libroId → Set de capítulos con favoritos.
final _favoritosPorLibroYCapituloProvider =
    Provider<AsyncValue<Map<int, Set<int>>>>((ref) {
  final favoritosAsync = ref.watch(favoritosStreamProvider);
  return favoritosAsync.when(
    data: (favoritos) {
      final map = <int, Set<int>>{};
      for (final f in favoritos) {
        map.putIfAbsent(f.libroId, () => <int>{}).add(f.capitulo);
      }
      return AsyncValue.data(map);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Set de libroIds que tienen al menos un versículo favorito.
final favoritosPorLibroProvider = Provider<AsyncValue<Set<int>>>((ref) {
  final mapAsync = ref.watch(_favoritosPorLibroYCapituloProvider);
  return mapAsync.when(
    data: (map) => AsyncValue.data(map.keys.toSet()),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Set de capítulos con favoritos para un libroId dado.
final favoritosPorCapituloProvider =
    Provider.family<AsyncValue<Set<int>>, int>((ref, libroId) {
  final mapAsync = ref.watch(_favoritosPorLibroYCapituloProvider);
  return mapAsync.when(
    data: (map) => AsyncValue.data(map[libroId] ?? const {}),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
