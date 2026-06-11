import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/hymn_repository_impl.dart';
import '../../../domain/usecases/himno/create_hymn_usecase.dart';
import '../../../domain/usecases/himno/delete_hymn_usecase.dart';
import '../../../domain/usecases/himno/search_hymns_usecase.dart';
import '../../../domain/usecases/himno/update_hymn_usecase.dart';
import '../../views_personal/providers/hymn_providers.dart';

// ─────────────────────────────────────────────────────────────
// Providers de casos de uso — Himno (CRUD + Búsqueda)
// ─────────────────────────────────────────────────────────────
// Estos providers viven en presentation/ para desacoplar
// flutter_riverpod de la capa de dominio.

/// Provider de [CreateHymnUseCase].
final createHymnUseCaseProvider = Provider<CreateHymnUseCase>((ref) {
  final repo = ref.read(hymnRepositoryProvider);
  return CreateHymnUseCase(repo);
});

/// Provider de [UpdateHymnUseCase].
final updateHymnUseCaseProvider = Provider<UpdateHymnUseCase>((ref) {
  final repo = ref.read(hymnRepositoryProvider);
  return UpdateHymnUseCase(repo);
});

/// Provider de [DeleteHymnUseCase].
final deleteHymnUseCaseProvider = Provider<DeleteHymnUseCase>((ref) {
  final repo = ref.read(hymnRepositoryProvider);
  return DeleteHymnUseCase(repo);
});

/// Provider de [SearchHymnsUseCase].
final searchHymnsUseCaseProvider = Provider<SearchHymnsUseCase>((ref) {
  final repository = HymnRepositoryImpl();
  return SearchHymnsUseCase(repository);
});
