import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../views_personal/providers/hymn_providers.dart';

/// ID del himno actualmente seleccionado en modo Emisor.
final activeHymnIdProvider = StateProvider<int?>((ref) => null);

/// Proveedor reactivo del himno activo (derivado de activeHymnIdProvider).
final activeHymnProvider = Provider<AsyncValue<Himno?>>((ref) {
  final hymnId = ref.watch(activeHymnIdProvider);
  if (hymnId == null) return const AsyncValue.data(null);
  return ref.watch(hymnDetailProvider(hymnId));
});

/// Proveedor reactivo de las estrofas del himno activo.
final activeStanzasProvider = Provider<AsyncValue<List<Estrofa>?>>((ref) {
  final himnoAsync = ref.watch(activeHymnProvider);
  final vpId = himnoAsync.valueOrNull?.primaryVersionPaisId;
  if (vpId == null) return const AsyncValue.data(null);
  return ref.watch(stanzasProvider(vpId));
});
