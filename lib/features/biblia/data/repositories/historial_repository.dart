import 'dart:async';

import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/database/bible_database_helper.dart';
import '../models/historial_item.dart';

/// Repositorio del historial de lectura de versículos.
///
/// Append-only: cada `record` inserta una fila. El sistema usa esto para:
/// - "Última posición leída" (`ORDER BY fecha_lectura DESC LIMIT 1`).
/// - Streaks de lectura (`GROUP BY date(fecha_lectura)`).
/// - Versículos más leídos (`GROUP BY (v, l, c, n)`).
/// - Podar entradas más viejas que 12 meses (no implementado en Fase 2a;
///   se documenta en `TODO_PHASE_2.md` como follow-up).
///
/// Los items se devuelven con datos pre-joined (libro + versículo) para
/// que la UI no haga N+1 al mostrar la lista cronológica.
///
/// ## Watch / Streams
///
/// Como `sqflite_common_ffi` no expone `createStreamQuery`, usamos un
/// `StreamController.broadcast` interno que se notifica en cada `record`,
/// `remove` o `clear`. Los `watchAll` activos re-consultan la BD y emiten
/// el resultado actualizado.
class HistorialRepository {
  static final _log = Logger('HistorialRepository');

  final BibleDatabaseHelper _db;
  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  HistorialRepository(this._db);

  Future<Database> get _database => _db.database;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() async {
    await _changes.close();
  }

  /// Lista los items del historial con datos de libro/versículo joined.
  ///
  /// Orden cronológico inverso (más reciente primero). El [limit] protege
  /// contra listas enormes (default 100 — la UI virtualiza la lista de
  /// todos modos).
  Future<List<HistorialItem>> getAll({
    int? versionId,
    int limit = 100,
  }) async {
    final db = await _database;
    final sql = '''
      SELECT
        h.id, h.version_id, h.libro_id, h.capitulo, h.numero, h.fecha_lectura,
        l.nombre        AS libro_nombre,
        l.abreviatura   AS libro_abreviatura,
        v.texto         AS texto
      FROM historial_versiculo h
      JOIN libro     l ON l.id = h.libro_id
      LEFT JOIN versiculo v ON v.capitulo_id = (
        SELECT id FROM capitulo
        WHERE libro_id = h.libro_id AND numero = h.capitulo
        LIMIT 1
      ) AND v.numero = h.numero
      ${versionId != null ? 'WHERE h.version_id = ?' : ''}
      ORDER BY h.fecha_lectura DESC
      LIMIT ?;
    ''';
    final args = <Object?>[];
    if (versionId != null) args.add(versionId);
    args.add(limit);

    final rows = await db.rawQuery(sql, args);
    return rows.map(HistorialItem.fromJoinedMap).toList(growable: false);
  }

  /// Registra una lectura (append). Idempotente en el sentido de que
  /// múltiples llamadas con la misma cuádrupla crean múltiples filas
  /// (eso es lo deseado: queremos contar cada lectura individual para
  /// los stats de "más leídos").
  ///
  /// Devuelve el `id` de la fila insertada.
  Future<int> record(
    int versionId,
    int libroId,
    int capitulo,
    int numero,
  ) async {
    final db = await _database;
    final timestamp =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final id = await db.insert('historial_versiculo', {
      'version_id': versionId,
      'libro_id': libroId,
      'capitulo': capitulo,
      'numero': numero,
      'fecha_lectura': timestamp,
    });
    _log.fine(
      'record v=$versionId l=$libroId c=$capitulo n=$numero → id=$id',
    );
    _notify();
    return id;
  }

  /// Elimina un item por `id`.
  Future<int> remove(int id) async {
    final db = await _database;
    final result = await db.delete(
      'historial_versiculo',
      where: 'id = ?',
      whereArgs: [id],
    );
    _log.fine('remove historial id=$id → $result');
    if (result > 0) _notify();
    return result;
  }

  /// Limpia todo el historial. Útil para "Reset" en settings.
  /// Devuelve la cantidad de filas eliminadas.
  Future<int> clear() async {
    final db = await _database;
    final result = await db.delete('historial_versiculo');
    _log.info('clear historial → $result filas eliminadas');
    _notify();
    return result;
  }

  /// Stream reactivo del historial. Se emite el estado actual y luego
  /// cada vez que hay un cambio (record / remove / clear).
  ///
  /// Es un **broadcast stream**: múltiples listeners pueden suscribirse
  /// simultáneamente (útil para Riverpod + test patterns). El primer
  /// valor se emite con el estado actual.
  Stream<List<HistorialItem>> watchAll({
    int? versionId,
    int limit = 100,
  }) {
    late StreamController<List<HistorialItem>> controller;
    StreamSubscription<void>? sub;

    Future<void> emit() async {
      try {
        final list = await getAll(versionId: versionId, limit: limit);
        if (!controller.isClosed) controller.add(list);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<List<HistorialItem>>.broadcast(
      onListen: () {
        // ignore: discarded_futures
        emit();
        sub = _changes.stream.listen((_) => emit());
      },
      onCancel: () async {
        await sub?.cancel();
        sub = null;
      },
    );

    return controller.stream;
  }
}
