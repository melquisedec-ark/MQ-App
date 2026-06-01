import 'dart:async';

import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/database/bible_database_helper.dart';
import '../models/nota.dart';

/// Repositorio de notas personales sobre versículos.
///
/// Decisión arquitectónica #9: 1 nota por versículo con color
/// semaforizado. La unicidad está garantizada por el constraint
/// `UNIQUE(version_id, libro_id, capitulo, numero)`. El trigger `nota_bi`
/// valida que `libro_id` pertenezca a `version_id`.
///
/// Operaciones:
/// - `getAll` y `getNota`: lectura con/sin JOIN.
/// - `upsert`: crea o reemplaza (idempotente — llamar 2 veces no rompe).
/// - `delete`: por id.
/// - `watchAll`: stream reactivo para UI.
class NotasRepository {
  static final _log = Logger('NotasRepository');

  final BibleDatabaseHelper _db;
  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  NotasRepository(this._db);

  Future<Database> get _database => _db.database;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> dispose() async {
    await _changes.close();
  }

  /// Lista de notas con filtros opcionales por versión y color.
  ///
  /// Orden cronológico inverso por `fecha_modificacion` (más recientes
  /// primero — la UI de notas prioriza lo último editado).
  Future<List<Nota>> getAll({int? versionId, NotaColor? color}) async {
    final db = await _database;
    final wheres = <String>[];
    final args = <Object?>[];
    if (versionId != null) {
      wheres.add('version_id = ?');
      args.add(versionId);
    }
    if (color != null) {
      wheres.add('color = ?');
      args.add(color.value);
    }
    final where = wheres.isEmpty ? null : wheres.join(' AND ');
    final rows = await db.query(
      'nota',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'fecha_modificacion DESC',
    );
    return rows.map(Nota.fromMap).toList(growable: false);
  }

  /// Devuelve la nota asociada a la cuádrupla (v, l, c, n) o null si no
  /// existe. La UI usa esto para abrir el editor pre-rellenado.
  Future<Nota?> getNota(
    int versionId,
    int libroId,
    int capitulo,
    int numero,
  ) async {
    final db = await _database;
    final rows = await db.query(
      'nota',
      where: 'version_id = ? AND libro_id = ? AND capitulo = ? AND numero = ?',
      whereArgs: [versionId, libroId, capitulo, numero],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Nota.fromMap(rows.first);
  }

  /// Crea o actualiza la nota de la cuádrupla (v, l, c, n).
  ///
  /// Estrategia: dos queries separadas (no `INSERT OR REPLACE`):
  /// 1. Intentar UPDATE; si afecta 0 filas, hacer INSERT.
  ///   Esto preserva `id` estable cuando solo cambia el contenido/color,
  ///   y crea uno nuevo en la primera escritura.
  ///
  ///   `INSERT OR REPLACE` cambiaría el `id` (AUTOINCREMENT), invalidando
  ///   referencias externas (futuro `nota_revisiones` cuando se migre a
  ///   multi-nota por versículo).
  ///
  /// Devuelve el `id` de la nota (existente o recién creada).
  Future<int> upsert(
    int versionId,
    int libroId,
    int capitulo,
    int numero,
    String contenido,
    NotaColor color,
  ) async {
    final db = await _database;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final updated = await db.update(
      'nota',
      {
        'contenido': contenido,
        'color': color.value,
        'fecha_modificacion': now,
      },
      where: 'version_id = ? AND libro_id = ? AND capitulo = ? AND numero = ?',
      whereArgs: [versionId, libroId, capitulo, numero],
    );
    if (updated > 0) {
      _log.fine('upsert nota v=$versionId l=$libroId c=$capitulo n=$numero → updated');
      // Devolvemos el id de la fila actualizada.
      final rows = await db.query(
        'nota',
        columns: ['id'],
        where: 'version_id = ? AND libro_id = ? AND capitulo = ? AND numero = ?',
        whereArgs: [versionId, libroId, capitulo, numero],
        limit: 1,
      );
      _notify();
      return rows.first['id'] as int;
    }
    // No existe: INSERT.
    final id = await db.insert('nota', {
      'version_id': versionId,
      'libro_id': libroId,
      'capitulo': capitulo,
      'numero': numero,
      'contenido': contenido,
      'color': color.value,
      'fecha_creacion': now,
      'fecha_modificacion': now,
    });
    _log.fine('upsert nota v=$versionId l=$libroId c=$capitulo n=$numero → inserted id=$id');
    _notify();
    return id;
  }

  /// Elimina la nota por `id`. Devuelve la cantidad de filas eliminadas.
  Future<int> delete(int id) async {
    final db = await _database;
    final result = await db.delete(
      'nota',
      where: 'id = ?',
      whereArgs: [id],
    );
    _log.fine('delete nota id=$id → $result');
    if (result > 0) _notify();
    return result;
  }

  /// Stream reactivo de notas. Se emite en cada cambio de la tabla
  /// (insert / update / delete) mediante el `_changes` controller interno.
  ///
  /// Es un **broadcast stream**: múltiples listeners pueden suscribirse
  /// simultáneamente (útil para Riverpod + test patterns). El primer
  /// valor se emite con el estado actual.
  Stream<List<Nota>> watchAll({int? versionId}) {
    late StreamController<List<Nota>> controller;
    StreamSubscription<void>? sub;

    Future<void> emit() async {
      try {
        final list = await getAll(versionId: versionId);
        if (!controller.isClosed) controller.add(list);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<List<Nota>>.broadcast(
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
