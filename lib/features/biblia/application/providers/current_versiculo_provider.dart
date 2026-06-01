import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/versiculo.dart';
import 'biblia_version_provider.dart';
import 'current_libro_provider.dart';

/// Número del versículo actualmente seleccionado. `null` = ninguno.
final currentVersiculoNumeroProvider = StateProvider<int?>((ref) => null);

/// Versículo actualmente "focalizado" en la UI.
///
/// Se resuelve cuando están seteados los 4 valores
/// (versionId, libroId, capitulo, numero). Si alguno es null, devuelve
/// `null` (cargando o sin selección).
final currentVersiculoProvider = FutureProvider<Versiculo?>((ref) async {
  final versionId = ref.watch(currentVersionIdProvider);
  final libroId = ref.watch(currentLibroIdProvider);
  final capitulo = ref.watch(currentCapituloProvider);
  final numero = ref.watch(currentVersiculoNumeroProvider);
  if (libroId == null || capitulo == null || numero == null) return null;
  final repo = ref.watch(bibliaRepositoryProvider);
  // Para esta query, primero necesitamos el número canónico del libro.
  // Lo resolvemos con getLibroById y luego getVersiculoByReference.
  final libro = await repo.getLibroById(libroId);
  if (libro == null) return null;
  return repo.getVersiculoByReference(versionId, libro.numero, capitulo, numero);
});
