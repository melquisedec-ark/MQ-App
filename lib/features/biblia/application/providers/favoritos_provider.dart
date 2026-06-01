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
