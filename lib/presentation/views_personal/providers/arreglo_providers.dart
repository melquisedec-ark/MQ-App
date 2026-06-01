import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../data/datasources/local/arreglo_local_datasource.dart';
import '../../../data/repositories/arreglo_repository_impl.dart';
import '../../../domain/entities/arreglo_musical.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/estrofa_arreglo.dart';
import '../../../domain/repositories/arreglo_repository.dart';

/// Provider del repositorio de arreglos musicales (singleton).
///
/// Conecta la capa de presentación con [ArregloRepositoryImpl],
/// que a su vez usa [ArregloLocalDataSource] con transacciones SQL.
final arregloRepositoryProvider = Provider<ArregloRepository>((ref) {
  return ArregloRepositoryImpl(
    ArregloLocalDataSource(dbHelper: DatabaseHelper.instance),
  );
});

/// ID del usuario actual.
///
/// Temporalmente retorna `1` hasta que se implemente autenticación.
final currentUserIdProvider = StateProvider<int>((ref) => 1);

/// Provider que retorna la lista de arreglos del usuario actual.
final userArreglosProvider = FutureProvider<List<ArregloMusical>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final repo = ref.watch(arregloRepositoryProvider);
  return repo.getArreglosByUser(userId);
});

/// Provider que retorna los arreglos de un usuario específico.
final arreglosByUserProvider =
    FutureProvider.family<List<ArregloMusical>, int>((ref, usuarioId) async {
  final repo = ref.watch(arregloRepositoryProvider);
  return repo.getArreglosByUser(usuarioId);
});

/// Provider que retorna un arreglo específico por ID.
final arregloDetailProvider =
    FutureProvider.family<ArregloMusical?, int>((ref, id) async {
  final repo = ref.watch(arregloRepositoryProvider);
  return repo.getArregloById(id);
});

/// Provider que retorna las estrofas de un arreglo específico.
final arregloEstrofasProvider =
    FutureProvider.family<List<EstrofaArreglo>, int>(
  (ref, arregloId) async {
    final repo = ref.watch(arregloRepositoryProvider);
    return repo.getEstrofasByArreglo(arregloId);
  },
);

// ──────────────────────────────────────────────
// Providers para integrar arreglos en HymnDetailScreen
// ──────────────────────────────────────────────

/// Provider que retorna el arreglo del usuario actual para un himno
/// específico (identificado por [versionPaisId]), o `null` si no existe.
///
/// Útil en [HymnDetailScreen] para mostrar un toggle "Original / Mi arreglo".
final arregloByHymnProvider =
    FutureProvider.family<ArregloMusical?, int>((ref, versionPaisId) async {
  final arreglos = await ref.watch(userArreglosProvider.future);
  return arreglos.where((a) => a.versionPaisId == versionPaisId).firstOrNull;
});

/// Provider que retorna las estrofas de un arreglo como `List<Estrofa>`
/// (la entidad de dominio de himnos), para poder reutilizar el widget
/// de renderizado de [HymnDetailScreen] con los datos del arreglo.
///
/// Si [arregloId] es <= 0, retorna lista vacía (sin consultar BD).
final arregloEstrofasViewProvider =
    FutureProvider.family<List<Estrofa>, int>((ref, arregloId) async {
  if (arregloId <= 0) return [];
  final estrofas = await ref.watch(arregloEstrofasProvider(arregloId).future);
  return estrofas
      .map(
        (e) => Estrofa(
          id: e.id,
          // `versionPaisId` no se usa en renderizado; ponemos un valor
          // sintético negativo para distinguirlo de IDs reales de himnos.
          versionPaisId: -e.arregloMusicalId,
          tipo: e.tipo,
          orden: e.orden,
          contenido: e.contenido,
        ),
      )
      .toList();
});
