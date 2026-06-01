import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/versiculo_contexto.dart';
import 'biblia_version_provider.dart';
import 'current_libro_provider.dart';

/// Versículo aleatorio de la versión actualmente seleccionada.
///
/// Decisión arquitectónica #10: versículo aleatorio en cada cold start
/// (no "verse del día"). Este provider se invalida al cambiar de versión
/// (Riverpod lo hace automáticamente porque `currentVersionIdProvider`
/// es una de sus dependencias).
final randomVersiculoProvider = FutureProvider<VersiculoContexto?>((ref) async {
  final versionId = ref.watch(currentVersionIdProvider);
  final repo = ref.watch(bibliaRepositoryProvider);
  final versiculo = await repo.getRandomVersiculo(versionId);
  if (versiculo == null) return null;
  // Resolvemos libro + capítulo + (opcional) versión para la UI.
  // Hacemos un JOIN manual con queries separadas; el costo es 3 SELECT
  // adicionales pero solo se ejecuta 1 vez por cold start.
  final rows = await (await _db(ref)).rawQuery(
    '''
    SELECT
      v.id, v.capitulo_id, v.numero, v.texto,
      l.version_id, l.nombre AS libro_nombre,
      l.abreviatura AS libro_abreviatura, l.numero AS libro_numero,
      c.numero AS capitulo_numero
    FROM versiculo v
    JOIN capitulo c ON c.id = v.capitulo_id
    JOIN libro    l ON l.id = c.libro_id
    WHERE v.id = ?;
    ''',
    [versiculo.id],
  );
  if (rows.isEmpty) return null;
  return VersiculoContexto.fromJoinedMap(rows.first);
});

/// Helper privado para acceder a la BD sin exponer el helper al exterior.
Future _db(Ref ref) async {
  final helper = ref.watch(bibleDatabaseHelperProvider);
  return helper.database;
}
