import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/bible_database_helper.dart';
import '../../data/models/biblia_version.dart';
import '../../data/repositories/biblia_repository.dart';

/// Provider del singleton `BibleDatabaseHelper`.
///
/// Se exporta como Provider para que tests y otros providers puedan
/// hacer `overrideWithValue(...)` con una BD en memoria.
final bibleDatabaseHelperProvider = Provider<BibleDatabaseHelper>((ref) {
  return BibleDatabaseHelper.instance;
});

/// Provider del `BibliaRepository`. Usa el helper singleton por defecto.
final bibliaRepositoryProvider = Provider<BibliaRepository>((ref) {
  final db = ref.watch(bibleDatabaseHelperProvider);
  return BibliaRepository(db);
});

/// Provider asíncrono con la lista de versiones bíblicas activas.
/// Se usa en el selector de versión del app bar.
final activeBibliaVersionsProvider = FutureProvider<List<BibliaVersion>>((ref) async {
  final repo = ref.watch(bibliaRepositoryProvider);
  return repo.getActiveVersions();
});
