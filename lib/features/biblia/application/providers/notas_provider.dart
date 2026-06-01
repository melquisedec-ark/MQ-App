import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/nota.dart';
import '../../data/repositories/notas_repository.dart';
import 'biblia_version_provider.dart';
import 'current_libro_provider.dart';

/// Provider del `NotasRepository`.
final notasRepositoryProvider = Provider<NotasRepository>((ref) {
  final db = ref.watch(bibleDatabaseHelperProvider);
  return NotasRepository(db);
});

/// Stream reactivo de todas las notas, filtradas por la versión actual.
/// Se re-emite automáticamente cuando la tabla `nota` cambia.
final notasStreamProvider = StreamProvider<List<Nota>>((ref) {
  final versionId = ref.watch(currentVersionIdProvider);
  final repo = ref.watch(notasRepositoryProvider);
  return repo.watchAll(versionId: versionId);
});
