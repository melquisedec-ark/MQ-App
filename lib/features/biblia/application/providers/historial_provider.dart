import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/historial_item.dart';
import '../../data/repositories/historial_repository.dart';
import 'biblia_version_provider.dart';
import 'current_libro_provider.dart';

/// Provider del `HistorialRepository`.
final historialRepositoryProvider = Provider<HistorialRepository>((ref) {
  final db = ref.watch(bibleDatabaseHelperProvider);
  return HistorialRepository(db);
});

/// Stream reactivo del historial, filtrado por la versión actual.
/// Limitado a 50 items por defecto (la UI virtualiza la lista de todos modos).
final historialStreamProvider = StreamProvider<List<HistorialItem>>((ref) {
  final versionId = ref.watch(currentVersionIdProvider);
  final repo = ref.watch(historialRepositoryProvider);
  return repo.watchAll(versionId: versionId, limit: 50);
});
