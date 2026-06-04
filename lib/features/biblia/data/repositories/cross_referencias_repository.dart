import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/database/bible_database_helper.dart';
import '../models/cross_referencia.dart'
    show CrossReferencia, CrossReferenciaConPreview;

/// Repositorio de cross-references bíblicas (versículo X → versículo Y).
///
/// Tabla: `cross_referencia` (migración 004 del schema de Biblia).
/// 4 triggers de validación (`cross_referencia_bi/bu` para `from_libro_id`
/// y `cross_referencia_bi_to/bu_to` para `to_libro_id`) rechazan
/// INSERTs/UPDATEs donde (libro_id, version_id) no es coherente.
///
/// ## Queries principales
///
/// 1. **FROM lookup** — refs que SALEN de un versículo (uso principal en UI):
///    `WHERE version_id=? AND from_libro_id=? AND from_capitulo=? AND from_versiculo=?`
///    Usa el índice `idx_cross_ref_from`.
///
/// 2. **TO lookup** — refs que LLEGAN a un versículo (futuro "¿quién me cita?"):
///    `WHERE to_libro_id=? AND to_capitulo=? AND to_versiculo_inicio<=? AND to_versiculo_fin>=?`
///    El rango de versículos requiere un BETWEEN. Usa el índice
///    `idx_cross_ref_to` por la columna `to_versiculo_inicio` (el
///    `BETWEEN` es aproximado pero suficientemente bueno para refs
///    con rangos cortos como 22:12-14).
///
/// 3. **COUNT** — cuántas refs SALEN de un versículo (badge en UI).
///
/// ## Orden
///
/// El método `getByFromVerse` y `getByToVerse` ordenan por
/// `libro.numero ASC, capitulo ASC, versiculo ASC` (orden canónico
/// Génesis→Apocalipsis). Esto es más intuitivo para el usuario que
/// busca referencias en orden bíblico.
///
/// ## Multi-versión
///
/// Cada ref está asociada a una `version_id` (FK a `version.id`).
/// Mismo patrón que `Nota`/`FavoritoVersiculo` — sin FK a `versiculo.id`
/// para permitir refs cross-versión.
class CrossReferenciasRepository {
  static final _log = Logger('CrossReferenciasRepository');

  final BibleDatabaseHelper _db;

  CrossReferenciasRepository(this._db);

  /// Acceso a la BD abierta (lazy).
  Future<Database> get _database => _db.database;

  /// Refs que SALEN de un versículo, ordenadas por libro/capítulo/versículo destino.
  ///
  /// Esta es la query principal del Bible reader: cuando el usuario
  /// abre Juan 3:16, la UI pide las refs que apuntan a otros versículos
  /// y las muestra en una sección "Cross-references".
  ///
  /// Devuelve lista vacía si no hay refs (nunca null).
  Future<List<CrossReferencia>> getByFromVerse({
    required int versionId,
    required int libroId,
    required int capitulo,
    required int versiculo,
  }) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT cr.* FROM cross_referencia cr
      JOIN libro tl ON tl.id = cr.to_libro_id
      WHERE cr.version_id    = ?
        AND cr.from_libro_id = ?
        AND cr.from_capitulo = ?
        AND cr.from_versiculo = ?
      ORDER BY tl.numero ASC, cr.to_capitulo ASC, cr.to_versiculo_inicio ASC;
      ''',
      [versionId, libroId, capitulo, versiculo],
    );
    _log.fine(
      'getByFromVerse v=$versionId l=$libroId c=$capitulo v$versiculo → ${rows.length} refs',
    );
    return rows.map(CrossReferencia.fromMap).toList(growable: false);
  }

  /// Refs que LLEGAN a un versículo (incluyendo refs cuyo rango destino
  /// contiene ese versículo), ordenadas por libro/capítulo/versículo origen.
  ///
  /// Útil para "¿quién me cita?". Ejemplo: si el usuario quiere ver
  /// qué versículos de Génesis 22:12 son citados por el NT.
  ///
  /// La condición `to_versiculo_inicio <= ? AND to_versiculo_fin >= ?`
  /// matchea tanto refs a versículo único (inicio == fin) como refs
  /// a rangos que contienen al versículo.
  Future<List<CrossReferencia>> getByToVerse({
    required int versionId,
    required int libroId,
    required int capitulo,
    required int versiculo,
  }) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT cr.* FROM cross_referencia cr
      JOIN libro l ON l.id = cr.to_libro_id
      WHERE cr.version_id      = ?
        AND cr.to_libro_id     = ?
        AND cr.to_capitulo     = ?
        AND cr.to_versiculo_inicio <= ?
        AND cr.to_versiculo_fin    >= ?
      ORDER BY l.numero ASC, cr.from_capitulo ASC, cr.from_versiculo ASC;
      ''',
      [versionId, libroId, capitulo, versiculo, versiculo],
    );
    return rows.map(CrossReferencia.fromMap).toList(growable: false);
  }

  /// Cuenta cuántas refs SALEN de un versículo.
  ///
  /// Optimización para UI: muestra un badge "tiene 12 referencias" sin
  /// tener que cargar la lista completa. Hace una sola query con
  /// `COUNT(*)` (no escanea la lista en memoria).
  Future<int> countByFromVerse({
    required int versionId,
    required int libroId,
    required int capitulo,
    required int versiculo,
  }) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS c FROM cross_referencia
      WHERE version_id    = ?
        AND from_libro_id = ?
        AND from_capitulo = ?
        AND from_versiculo = ?
      ''',
      [versionId, libroId, capitulo, versiculo],
    );
    final raw = rows.first['c'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  /// Batch: cuenta refs que SALEN de cada versículo de un capítulo entero,
  /// agrupadas por `from_versiculo`.
  ///
  /// C6: optimización para chapter view. Sin esta query, renderizar
  /// 176 versículos (Salmo 119) dispararía 176 `countByFromVerse`
  /// consecutivos. Con esta batch, una sola query retorna el Map
  /// completo `{versiculo → count}` para todo el capítulo.
  ///
  /// El índice `idx_cross_ref_from` (version_id, from_libro_id, from_capitulo,
  /// from_versiculo) hace esta query eficiente: usa solo el prefijo
  /// (libro_id, capitulo) y agrega en memoria.
  Future<Map<int, int>> getCountsByFromVerseBatch({
    required int versionId,
    required int libroId,
    required int capitulo,
  }) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT from_versiculo, COUNT(*) AS c FROM cross_referencia
      WHERE version_id    = ?
        AND from_libro_id = ?
        AND from_capitulo  = ?
      GROUP BY from_versiculo
      ''',
      [versionId, libroId, capitulo],
    );
    final result = <int, int>{};
    for (final row in rows) {
      final versiculo = row['from_versiculo'] as int;
      final raw = row['c'];
      final count = raw is int ? raw : (raw as num).toInt();
      result[versiculo] = count;
    }
    return result;
  }

  /// Cuenta cuántas refs LLEGAN a un versículo.
  ///
  /// Complemento de [countByFromVerse] para badges "citado por N refs".
  Future<int> countByToVerse({
    required int versionId,
    required int libroId,
    required int capitulo,
    required int versiculo,
  }) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS c FROM cross_referencia
      WHERE version_id      = ?
        AND to_libro_id     = ?
        AND to_capitulo     = ?
        AND to_versiculo_inicio <= ?
        AND to_versiculo_fin    >= ?
      ''',
      [versionId, libroId, capitulo, versiculo, versiculo],
    );
    final raw = rows.first['c'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  /// Feature #2: refs que SALEN de un versículo con preview del texto destino.
  ///
  /// Usa LEFT JOIN a `libro`, `capitulo` y `versiculo` para no filtrar
  /// refs cuyo destino no existe materialmente en la BD. Si el versículo
  /// no existe, `preview_texto` será null. Ordenadas por libro destino.
  Future<List<CrossReferenciaConPreview>> getByFromVerseWithPreview({
    required int versionId,
    required int libroId,
    required int capitulo,
    required int versiculo,
  }) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT cr.*, v.texto AS preview_texto
      FROM cross_referencia cr
      LEFT JOIN libro tl ON tl.id = cr.to_libro_id
      LEFT JOIN capitulo tc ON tc.libro_id = tl.id AND tc.numero = cr.to_capitulo
      LEFT JOIN versiculo v ON v.capitulo_id = tc.id AND v.numero = cr.to_versiculo_inicio
      WHERE cr.version_id = ? AND cr.from_libro_id = ?
        AND cr.from_capitulo = ? AND cr.from_versiculo = ?
      ORDER BY tl.numero ASC, cr.to_capitulo ASC, cr.to_versiculo_inicio ASC
      ''',
      [versionId, libroId, capitulo, versiculo],
    );
    _log.fine(
      'getByFromVerseWithPreview v=$versionId l=$libroId c=$capitulo v$versiculo → ${rows.length} refs',
    );
    return rows.map(CrossReferenciaConPreview.fromMap).toList(growable: false);
  }
}
