import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/capitulo.dart';
import '../../data/models/historial_item.dart';
import '../../data/models/libro.dart';
import '../../data/models/nota.dart';
import '../../data/models/versiculo.dart';
import '../../data/repositories/biblia_search_repository.dart';
import 'biblia_version_provider.dart';
import 'historial_provider.dart';
import 'notas_provider.dart';

/// Provider del `BibliaSearchRepository`. Wrapper para inyección en tests.
final bibliaSearchRepositoryProvider = Provider<BibliaSearchRepository>((ref) {
  final db = ref.watch(bibleDatabaseHelperProvider);
  return BibliaSearchRepository(db);
});

/// Provider de libros por versión y testamento.
///
/// Devuelve `Future<List<Libro>>` ordenado por número canónico (1..66).
final librosProvider = FutureProvider.family
    .autoDispose<List<Libro>, LibrosQuery>((ref, query) async {
  final repo = ref.watch(bibliaRepositoryProvider);
  return repo.getLibrosByVersion(
    query.versionId,
    testamento: query.testamento,
  );
});

/// Query tipada para [librosProvider].
class LibrosQuery {
  final int versionId;
  final Testamento? testamento;

  const LibrosQuery({required this.versionId, this.testamento});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibrosQuery &&
          versionId == other.versionId &&
          testamento == other.testamento;

  @override
  int get hashCode => Object.hash(versionId, testamento);
}

/// Provider de capítulos por libro.
///
/// Devuelve `Future<List<Capitulo>>` ordenado por número (1..N).
final capitulosProvider = FutureProvider.family
    .autoDispose<List<Capitulo>, int>((ref, libroId) async {
  final repo = ref.watch(bibliaRepositoryProvider);
  return repo.getCapitulosByLibro(libroId);
});

/// Provider del último capítulo leído de un libro.
///
/// Busca en el historial el item más reciente para `(versionId, libroId)`
/// y devuelve su `capitulo`. Devuelve `null` si nunca se leyó.
final lastReadCapituloProvider = FutureProvider.family
    .autoDispose<int?, LastReadQuery>((ref, query) async {
  final repo = ref.watch(historialRepositoryProvider);
  final all = await repo.getAll(versionId: query.versionId, limit: 200);
  final matches = all.where((h) => h.libroId == query.libroId);
  if (matches.isEmpty) return null;
  return matches.first.capitulo;
});

/// Query para [lastReadCapituloProvider].
class LastReadQuery {
  final int versionId;
  final int libroId;

  const LastReadQuery({required this.versionId, required this.libroId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastReadQuery &&
          versionId == other.versionId &&
          libroId == other.libroId;

  @override
  int get hashCode => Object.hash(versionId, libroId);
}

/// Provider de versículos por capítulo.
final versiculosByCapituloProvider = FutureProvider.family
    .autoDispose<List<Versiculo>, int>((ref, capituloId) async {
  final repo = ref.watch(bibliaRepositoryProvider);
  return repo.getVersiculosByCapitulo(capituloId);
});

/// Provider del versículo siguiente al actual (libroId, cap, num).
///
/// Devuelve `null` si no hay siguiente (último versículo del último
/// capítulo de la Biblia — caso borde raro en UI).
final nextVersiculoProvider = FutureProvider.family
    .autoDispose<Versiculo?, NextVersiculoQuery>((ref, query) async {
  final repo = ref.watch(bibliaRepositoryProvider);
  // Busca versículos del mismo capítulo con número > actual
  final capituloId = await _getCapituloId(
    ref,
    query.versionId,
    query.libroNumero,
    query.capitulo,
  );
  if (capituloId == null) return null;
  final versiculos = await repo.getVersiculosByCapitulo(capituloId);
  final nextInChapter =
      versiculos.where((v) => v.numero > query.numero).toList();
  if (nextInChapter.isNotEmpty) {
    return nextInChapter.first;
  }
  // Si no, primer versículo del siguiente capítulo
  final nextCap = await _getNextCapitulo(
    ref,
    query.versionId,
    query.libroNumero,
    query.capitulo,
  );
  if (nextCap == null) return null;
  final nextCapVersiculos = await repo.getVersiculosByCapitulo(nextCap.id);
  if (nextCapVersiculos.isEmpty) return null;
  return nextCapVersiculos.first;
});

/// Provider del versículo anterior al actual.
final prevVersiculoProvider = FutureProvider.family
    .autoDispose<Versiculo?, PrevVersiculoQuery>((ref, query) async {
  final repo = ref.watch(bibliaRepositoryProvider);
  // Busca versículos del mismo capítulo con número < actual
  final capituloId = await _getCapituloId(
    ref,
    query.versionId,
    query.libroNumero,
    query.capitulo,
  );
  if (capituloId == null) return null;
  final versiculos = await repo.getVersiculosByCapitulo(capituloId);
  final prevInChapter =
      versiculos.where((v) => v.numero < query.numero).toList();
  if (prevInChapter.isNotEmpty) {
    return prevInChapter.last; // El más cercano
  }
  // Si no, último versículo del capítulo anterior
  final prevCap = await _getPrevCapitulo(
    ref,
    query.versionId,
    query.libroNumero,
    query.capitulo,
  );
  if (prevCap == null) return null;
  final prevCapVersiculos = await repo.getVersiculosByCapitulo(prevCap.id);
  if (prevCapVersiculos.isEmpty) return null;
  return prevCapVersiculos.last;
});

/// Queries para next/prev versículo.
class NextVersiculoQuery {
  final int versionId;
  final int libroNumero;
  final int capitulo;
  final int numero;

  const NextVersiculoQuery({
    required this.versionId,
    required this.libroNumero,
    required this.capitulo,
    required this.numero,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NextVersiculoQuery &&
          versionId == other.versionId &&
          libroNumero == other.libroNumero &&
          capitulo == other.capitulo &&
          numero == other.numero;

  @override
  int get hashCode => Object.hash(versionId, libroNumero, capitulo, numero);
}

class PrevVersiculoQuery {
  final int versionId;
  final int libroNumero;
  final int capitulo;
  final int numero;

  const PrevVersiculoQuery({
    required this.versionId,
    required this.libroNumero,
    required this.capitulo,
    required this.numero,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrevVersiculoQuery &&
          versionId == other.versionId &&
          libroNumero == other.libroNumero &&
          capitulo == other.capitulo &&
          numero == other.numero;

  @override
  int get hashCode => Object.hash(versionId, libroNumero, capitulo, numero);
}

/// Provider de la nota de un versículo (o `null` si no existe).
///
/// **REACTIVO**: Derivado de [notasStreamProvider] para que la UI se
/// actualice al instante al crear/editar/eliminar una nota.
///
/// Usa [Provider] (no [StreamProvider]) para derivar síncronamente del
/// `AsyncValue` cacheado de [notasStreamProvider]. Así siempre hay datos
/// disponibles inmediatamente — sin esperar a que un broadcast stream
/// emita (el problema con StreamProvider.family era que el segundo
/// suscriptor no recibía la emisión inicial).
final currentNotaProvider = Provider.autoDispose.family<AsyncValue<Nota?>, NotaQuery>(
  (ref, query) {
    final notasAsync = ref.watch(notasStreamProvider);

    // Si el stream está cargando, propagar loading
    if (notasAsync.isLoading) {
      return const AsyncLoading();
    }

    // Si hay error, propagar error
    if (notasAsync.hasError) {
      return AsyncError(notasAsync.error!, notasAsync.stackTrace!);
    }

    // Filtrar la nota que coincide con la query
    final notas = notasAsync.value ?? [];
    Nota? found;
    for (final n in notas) {
      if (n.versionId == query.versionId &&
          n.libroId == query.libroId &&
          n.capitulo == query.capitulo &&
          n.numero == query.numero) {
        found = n;
        break;
      }
    }
    return AsyncData(found);
  },
);

class NotaQuery {
  final int versionId;
  final int libroId;
  final int capitulo;
  final int numero;

  const NotaQuery({
    required this.versionId,
    required this.libroId,
    required this.capitulo,
    required this.numero,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotaQuery &&
          versionId == other.versionId &&
          libroId == other.libroId &&
          capitulo == other.capitulo &&
          numero == other.numero;

  @override
  int get hashCode => Object.hash(versionId, libroId, capitulo, numero);
}

/// Provider del último item del historial (para el indicator "última lectura"
/// en book list).
final lastReadItemProvider = FutureProvider.family
    .autoDispose<HistorialItem?, int>((ref, libroId) async {
  final repo = ref.watch(historialRepositoryProvider);
  final all = await repo.getAll(limit: 200);
  final matches = all.where((h) => h.libroId == libroId);
  if (matches.isEmpty) return null;
  return matches.first;
});

// ─────────────────────────────────────────────────────────────────────
// Helpers internos (queries compuestas)
// ─────────────────────────────────────────────────────────────────────

/// Resuelve `capitulo.id` desde `(versionId, libroNumero, capitulo)`.
Future<int?> _getCapituloId(
  Ref ref,
  int versionId,
  int libroNumero,
  int numero,
) async {
  final repo = ref.read(bibliaRepositoryProvider);
  final libro = await repo.getLibroByNumero(versionId, libroNumero);
  if (libro == null) return null;
  final cap = await repo.getCapitulo(libro.id, numero);
  return cap?.id;
}

/// Devuelve el siguiente capítulo (siguiente libro si es el último cap).
Future<Capitulo?> _getNextCapitulo(
  Ref ref,
  int versionId,
  int libroNumero,
  int capituloNumero,
) async {
  final repo = ref.read(bibliaRepositoryProvider);
  final libro = await repo.getLibroByNumero(versionId, libroNumero);
  if (libro == null) return null;
  final caps = await repo.getCapitulosByLibro(libro.id);
  final idx = caps.indexWhere((c) => c.numero == capituloNumero);
  if (idx == -1) return null;
  if (idx + 1 < caps.length) return caps[idx + 1];
  // Último capítulo del libro → primer capítulo del siguiente libro
  final allLibros = await repo.getLibrosByVersion(versionId);
  final libroIdx = allLibros.indexWhere((l) => l.id == libro.id);
  if (libroIdx == -1 || libroIdx + 1 >= allLibros.length) return null;
  final nextLibro = allLibros[libroIdx + 1];
  final nextCaps = await repo.getCapitulosByLibro(nextLibro.id);
  return nextCaps.isNotEmpty ? nextCaps.first : null;
}

/// Devuelve el capítulo anterior (anterior libro si es cap 1).
Future<Capitulo?> _getPrevCapitulo(
  Ref ref,
  int versionId,
  int libroNumero,
  int capituloNumero,
) async {
  final repo = ref.read(bibliaRepositoryProvider);
  final libro = await repo.getLibroByNumero(versionId, libroNumero);
  if (libro == null) return null;
  final caps = await repo.getCapitulosByLibro(libro.id);
  final idx = caps.indexWhere((c) => c.numero == capituloNumero);
  if (idx == -1) return null;
  if (idx - 1 >= 0) return caps[idx - 1];
  // Primer capítulo del libro → último capítulo del libro anterior
  final allLibros = await repo.getLibrosByVersion(versionId);
  final libroIdx = allLibros.indexWhere((l) => l.id == libro.id);
  if (libroIdx <= 0) return null;
  final prevLibro = allLibros[libroIdx - 1];
  final prevCaps = await repo.getCapitulosByLibro(prevLibro.id);
  return prevCaps.isNotEmpty ? prevCaps.last : null;
}
