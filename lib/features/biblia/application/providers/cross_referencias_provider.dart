import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cross_referencia.dart';
import '../../data/repositories/cross_referencias_repository.dart';
import 'biblia_version_provider.dart';
import 'current_libro_provider.dart';

/// Clave estable de cache para Riverpod family: identifica un versículo
/// por su cuádrupla canónica (libro, capítulo, versículo).
///
/// Es un value object inmutable + Equatable, así que Riverpod puede
/// compararlo por valor y dedupe keys idénticas.
class CrossRefQuery extends Equatable {
  const CrossRefQuery({
    required this.libroId,
    required this.capitulo,
    required this.versiculo,
  });

  final int libroId;
  final int capitulo;
  final int versiculo;

  @override
  List<Object?> get props => [libroId, capitulo, versiculo];

  @override
  bool operator ==(Object other) =>
      other is CrossRefQuery &&
      other.libroId == libroId &&
      other.capitulo == capitulo &&
      other.versiculo == versiculo;

  @override
  int get hashCode => Object.hash(libroId, capitulo, versiculo);
}

/// Provider del `CrossReferenciasRepository`.
///
/// Reusa el `bibleDatabaseHelperProvider` para que los tests puedan
/// overridear la BD completa con un `inMemoryDatabasePath`.
final crossReferenciasRepositoryProvider =
    Provider<CrossReferenciasRepository>((ref) {
  final db = ref.watch(bibleDatabaseHelperProvider);
  return CrossReferenciasRepository(db);
});

/// Lista de cross-references que SALEN de un versículo.
///
/// Se re-emite automáticamente cuando:
///   1. Cambia `currentVersionIdProvider` (cambio de versión en UI).
///   2. Cambia la query `CrossRefQuery` (usuario navega a otro versículo).
///
/// `autoDispose`: cuando ningún widget escucha, el estado se libera.
///   Es importante porque las refs se piden al mostrar un versículo y
///   no necesitamos cachear 31k versículos en memoria.
final crossReferenciasProvider = FutureProvider.family
    .autoDispose<List<CrossReferencia>, CrossRefQuery>((ref, query) async {
  final versionId = ref.watch(currentVersionIdProvider);
  final repo = ref.read(crossReferenciasRepositoryProvider);
  return repo.getByFromVerse(
    versionId: versionId,
    libroId: query.libroId,
    capitulo: query.capitulo,
    versiculo: query.versiculo,
  );
});

/// Conteo de cross-references que SALEN de un versículo.
///
/// Más liviano que [crossReferenciasProvider]: solo devuelve un int.
/// Útil para badges "tiene 12 referencias" sin descargar la lista.
final crossReferenciasCountProvider = FutureProvider.family
    .autoDispose<int, CrossRefQuery>((ref, query) async {
  final versionId = ref.watch(currentVersionIdProvider);
  final repo = ref.read(crossReferenciasRepositoryProvider);
  return repo.countByFromVerse(
    versionId: versionId,
    libroId: query.libroId,
    capitulo: query.capitulo,
    versiculo: query.versiculo,
  );
});

/// Query tipada para [crossRefCountsProvider].
/// Identifica un capítulo por su par (libro, capítulo).
class ChapterQuery {
  const ChapterQuery({required this.libroId, required this.capitulo});

  final int libroId;
  final int capitulo;

  @override
  bool operator ==(Object other) =>
      other is ChapterQuery &&
      other.libroId == libroId &&
      other.capitulo == capitulo;

  @override
  int get hashCode => Object.hash(libroId, capitulo);
}

/// C6: batch de conteos de refs por versículo para un capítulo.
///
/// Una sola query retorna `Map<versiculo, count>` para todos los
/// versículos del capítulo que tengan refs. Versículos sin refs
/// NO aparecen en el mapa (el caller debe tratar ausencia como 0).
///
/// Reemplaza 176 queries individuales (Salmo 119) por 1 sola query
/// batch al renderizar la vista de capítulo.
final crossRefCountsProvider = FutureProvider.family
    .autoDispose<Map<int, int>, ChapterQuery>((ref, query) async {
  final versionId = ref.watch(currentVersionIdProvider);
  final repo = ref.read(crossReferenciasRepositoryProvider);
  return repo.getCountsByFromVerseBatch(
    versionId: versionId,
    libroId: query.libroId,
    capitulo: query.capitulo,
  );
});
