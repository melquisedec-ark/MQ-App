import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../data/datasources/local/audio_local_datasource.dart';
import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../../data/repositories/audio_repository_impl.dart';
import '../../../domain/repositories/audio_repository.dart';

/// Provider del datasource local de audio (singleton).
final audioLocalDataSourceProvider = Provider<AudioLocalDataSource>((ref) {
  final dataSource = AudioLocalDataSource();
  ref.onDispose(() => dataSource.dispose());
  return dataSource;
});

/// Provider del repositorio de audio.
final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final audioDS = ref.read(audioLocalDataSourceProvider);
  final catalogDS = CatalogLocalDataSource(dbHelper: DatabaseHelper.instance);
  return AudioRepositoryImpl(
    audioDataSource: audioDS,
    catalogDataSource: catalogDS,
  );
});

/// Provider que indica si hay audio reproduciéndose actualmente.
final isAudioPlayingProvider = StateProvider<bool>((ref) => false);
