import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/datasources/remote/grpc_control_datasource.dart';
import '../../../../presentation/views_projection/providers/connection_providers.dart';
import '../../../../proto/generated/hymn_control.pbgrpc.dart';
import 'current_libro_provider.dart';
import 'current_versiculo_provider.dart';

/// Provider del cliente gRPC del módulo Biblia.
///
/// Reusa el [controlDataSourceProvider] existente (mismo cliente para
/// Biblia + Himnario; solo cambian los mensajes del proto). Se provee
/// en la carpeta Biblia para que las pantallas del módulo Biblia
/// tengan una API local sin acoplarse a `connection_providers.dart`
/// (que es del himnario/original).
final mqAppBibleGrpcClientProvider = Provider<GrpcControlDataSource>((ref) {
  return ref.watch(controlDataSourceProvider);
});

/// Número canónico del libro actualmente seleccionado (1..66).
///
/// Se setea desde el BibleReaderScreen cuando el usuario navega.
/// Cachearlo aquí (en vez de hacer un async lookup en cada comando
/// gRPC) mantiene la API de [bibleClientActionsProvider] síncrona.
final currentLibroNumeroProvider = StateProvider<int>((ref) => 1);

/// Acciones de Biblia pre-componidas para enviar al display remoto.
///
/// Cada método lee el estado actual desde los providers y arma el
/// comando gRPC correspondiente. La UI del Bible reader lo usa:
///
/// ```dart
/// await ref.read(bibleClientActionsProvider).sendCurrentVerse();
/// ```
final bibleClientActionsProvider = Provider<BibleClientActions>((ref) {
  return BibleClientActions(ref);
});

/// Acciones de Biblia pre-componidas para enviar al display remoto.
class BibleClientActions {
  final Ref _ref;

  BibleClientActions(this._ref);

  GrpcControlDataSource get _client => _ref.read(mqAppBibleGrpcClientProvider);

  int get _versionId => _ref.read(currentVersionIdProvider);
  int get _libroNumero => _ref.read(currentLibroNumeroProvider);
  int get _capitulo => _ref.read(currentCapituloProvider) ?? 1;
  int get _versiculo => _ref.read(currentVersiculoNumeroProvider) ?? 1;

  /// Envía el versículo actualmente visible al display remoto.
  Future<bool> sendCurrentVerse() => _client.sendGoToVerse(
        versionId: _versionId,
        libroNumero: _libroNumero,
        capitulo: _capitulo,
        versiculo: _versiculo,
      );

  Future<bool> sendNextVerse() => _client.sendNextVerse();
  Future<bool> sendPrevVerse() => _client.sendPrevVerse();
  Future<bool> sendNextChapter() => _client.sendNextChapter();
  Future<bool> sendPrevChapter() => _client.sendPrevChapter();

  Future<bool> sendToggleFavorite() => _client.sendToggleFavorite();

  Future<bool> switchToBible() => _client.sendSwitchToBible();
  Future<bool> switchToHymnal() => _client.sendSwitchToHymnal();

  Future<bool> setViewMode(EmitterViewMode mode) =>
      _client.sendSetEmitterViewMode(mode);
}
