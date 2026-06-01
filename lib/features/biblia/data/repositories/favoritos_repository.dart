import 'dart:async';

import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/database/bible_database_helper.dart';
import '../models/favorito_versiculo.dart';

/// Repositorio de versículos favoritos.
///
/// La unicidad está garantizada por el constraint
/// `UNIQUE(version_id, libro_id, capitulo, numero)` en la BD:
/// - `add` usa `INSERT OR IGNORE` para no fallar si el versículo ya estaba.
/// - `remove` usa `DELETE` por la cuádrupla (v, l, c, n) — no por `id`,
///   para que la UI no necesite conocer el ID interno.
///
/// Los triggers `favorito_versiculo_bi/bu` validan que `libro_id`
/// pertenezca a `version_id` (consistencia referencial lógica). Si se
/// viola, el INSERT/UPDATE lanza `DatabaseException` con mensaje en español
/// ("favorito_versiculo: libro_id no pertenece a version_id").
///
/// ## Watch / Streams
///
/// Como `sqflite_common_ffi` no expone `createStreamQuery` (eso vive en
/// el plugin nativo `sqflite`), implementamos un stream de cambios
/// basado en un `StreamController.broadcast` interno. Cada `add` o
/// `remove` notifica al controller; los `watchAll()` activos re-consultan
/// la BD y emiten el resultado actualizado.
class FavoritosRepository {
  static final _log = Logger('FavoritosRepository');

  final BibleDatabaseHelper _db;
  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  FavoritosRepository(this._db);

  /// Acceso a la BD.
  Future<Database> get _database => _db.database;

  /// Notifica a los watchers que hubo un cambio.
  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Cierra el stream interno. Llamar cuando la app se apaga o en tests.
  Future<void> dispose() async {
    await _changes.close();
  }

  /// Lista todos los favoritos, opcionalmente filtrados por versión.
  /// Orden cronológico inverso (más recientes primero) — el usuario espera
  /// ver lo que recién marcó en la parte superior.
  Future<List<FavoritoVersiculo>> getAll({int? versionId}) async {
    final db = await _database;
    final where = StringBuffer('1=1');
    final args = <Object?>[];
    if (versionId != null) {
      where.write(' AND version_id = ?');
      args.add(versionId);
    }
    final rows = await db.query(
      'favorito_versiculo',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'fecha_agregado DESC',
    );
    return rows.map(FavoritoVersiculo.fromMap).toList(growable: false);
  }

  /// `true` si la cuádrupla (versión, libro, capítulo, versículo) está
  /// marcada como favorita. Usado por la UI para pintar el corazón lleno.
  Future<bool> isFavorito(
    int versionId,
    int libroId,
    int capitulo,
    int numero,
  ) async {
    final db = await _database;
    final rows = await db.query(
      'favorito_versiculo',
      columns: ['id'],
      where: 'version_id = ? AND libro_id = ? AND capitulo = ? AND numero = ?',
      whereArgs: [versionId, libroId, capitulo, numero],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Agrega un favorito. `INSERT OR IGNORE` para no fallar si ya existe
  /// (idempotente: llamar dos veces con la misma cuádrupla no rompe).
  ///
  /// Devuelve `true` si se insertó, `false` si ya existía.
  Future<bool> add(
    int versionId,
    int libroId,
    int capitulo,
    int numero,
  ) async {
    final db = await _database;
    final timestamp =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final result = await db.rawInsert(
      '''
      INSERT OR IGNORE INTO favorito_versiculo
        (version_id, libro_id, capitulo, numero, fecha_agregado)
      VALUES (?, ?, ?, ?, ?);
      ''',
      [versionId, libroId, capitulo, numero, timestamp],
    );
    _log.fine('add favorito v=$versionId l=$libroId c=$capitulo n=$numero → $result');
    _notify();
    return result > 0;
  }

  /// Quita un favorito por la cuádrupla (v, l, c, n). Idempotente: si
  /// no existe, devuelve 0 filas afectadas sin error.
  ///
  /// Devuelve la cantidad de filas eliminadas (0 o 1).
  Future<int> remove(
    int versionId,
    int libroId,
    int capitulo,
    int numero,
  ) async {
    final db = await _database;
    final result = await db.delete(
      'favorito_versiculo',
      where: 'version_id = ? AND libro_id = ? AND capitulo = ? AND numero = ?',
      whereArgs: [versionId, libroId, capitulo, numero],
    );
    _log.fine('remove favorito v=$versionId l=$libroId c=$capitulo n=$numero → $result');
    if (result > 0) _notify();
    return result;
  }

  /// Stream reactivo de la lista de favoritos. Se emite cada vez que la
  /// tabla `favorito_versiculo` cambia (insert / delete / update) mediante
  /// el `_changes` controller interno.
  ///
  /// Es un **broadcast stream**: múltiples listeners pueden suscribirse
  /// simultáneamente (útil para Riverpod + test patterns). El primer
  /// valor se emite inmediatamente con el estado actual.
  ///
  /// Útil para que la UI de favoritos se actualice automáticamente cuando
  /// el usuario marca/desmarca desde el Bible reader.
  Stream<List<FavoritoVersiculo>> watchAll({int? versionId}) {
    late StreamController<List<FavoritoVersiculo>> controller;
    StreamSubscription<void>? sub;

    Future<void> emit() async {
      try {
        final list = await getAll(versionId: versionId);
        if (!controller.isClosed) controller.add(list);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<List<FavoritoVersiculo>>.broadcast(
      onListen: () {
        // Emite el estado actual cuando el primer listener se suscribe.
        // ignore: discarded_futures
        emit();
        // Suscribe al controller de cambios para re-emitir en cada update.
        sub = _changes.stream.listen((_) => emit());
      },
      onCancel: () async {
        // Limpia la suscripción de cambios cuando no quedan listeners.
        await sub?.cancel();
        sub = null;
      },
    );

    return controller.stream;
  }
}
