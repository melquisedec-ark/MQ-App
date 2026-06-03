import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/database/bible_database_helper.dart';
import '../models/biblia_version.dart';
import '../models/capitulo.dart';
import '../models/libro.dart';
import '../models/versiculo.dart';

/// Repositorio principal de la Biblia: versiones, libros, capítulos y versículos.
///
/// Lee directamente de `biblia.db` (BD independiente del himnario, según
/// decisión arquitectónica #5 de Fase 1). Todas las queries usan prepared
/// statements (parámetros `?`) para evitar SQL injection.
///
/// Convenciones:
/// - Devuelve listas vacías (nunca null) cuando no hay resultados.
/// - Devuelve null solo en búsquedas por clave única (ej. `getLibroById`)
///   cuando la fila no existe.
class BibliaRepository {
  static final _log = Logger('BibliaRepository');

  final BibleDatabaseHelper _db;

  BibliaRepository(this._db);

  /// Acceso a la BD abierta (lazy).
  Future<Database> get _database => _db.database;

  // ───────────────────────────────────────────────────────────────
  // Versiones
  // ───────────────────────────────────────────────────────────────

  /// Lista de versiones activas. Orden alfabético por abreviatura.
  ///
  /// La UI usa esto para popular el selector de versión (actualmente
  /// RV1909; el schema es multi-versión y se reinsertarán futuras versiones
  /// en la tabla `version`). Solo se cargan las activas (`WHERE activa = 1`).
  Future<List<BibliaVersion>> getActiveVersions() async {
    final db = await _database;
    final rows = await db.query(
      'version',
      where: 'activa = ?',
      whereArgs: [1],
      orderBy: 'abreviatura ASC',
    );
    return rows.map(BibliaVersion.fromMap).toList(growable: false);
  }

  /// Devuelve la versión con `id` o null si no existe.
  Future<BibliaVersion?> getVersionById(int id) async {
    final db = await _database;
    final rows = await db.query(
      'version',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BibliaVersion.fromMap(rows.first);
  }

  /// Devuelve la versión con abreviatura exacta (case-sensitive) o null.
  /// Útil para resolver una versión desde una config (`RVR1909`).
  Future<BibliaVersion?> getVersionByAbreviatura(String abreviatura) async {
    final db = await _database;
    final rows = await db.query(
      'version',
      where: 'abreviatura = ?',
      whereArgs: [abreviatura],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BibliaVersion.fromMap(rows.first);
  }

  // ───────────────────────────────────────────────────────────────
  // Libros
  // ───────────────────────────────────────────────────────────────

  /// Lista de libros de una versión, opcionalmente filtrados por testamento.
  ///
  /// Orden canónico: por `numero` ascendente (1..66). Más rápido y estable
  /// que `ORDER BY nombre` (locale-dependiente).
  Future<List<Libro>> getLibrosByVersion(
    int versionId, {
    Testamento? testamento,
  }) async {
    final db = await _database;
    final where = StringBuffer('version_id = ?');
    final args = <Object?>[versionId];
    if (testamento != null) {
      where.write(' AND testamento = ?');
      args.add(testamento.value);
    }
    final rows = await db.query(
      'libro',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'numero ASC',
    );
    return rows.map(Libro.fromMap).toList(growable: false);
  }

  /// Devuelve el libro con `id` o null.
  Future<Libro?> getLibroById(int id) async {
    final db = await _database;
    final rows = await db.query(
      'libro',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Libro.fromMap(rows.first);
  }

  /// Devuelve el libro por (versión, número canónico) o null.
  /// Ej: `getLibroByNumero(versionId=1, numero=43)` → "Juan" en RV1909.
  Future<Libro?> getLibroByNumero(int versionId, int numero) async {
    final db = await _database;
    final rows = await db.query(
      'libro',
      where: 'version_id = ? AND numero = ?',
      whereArgs: [versionId, numero],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Libro.fromMap(rows.first);
  }

  // ───────────────────────────────────────────────────────────────
  // Capítulos
  // ───────────────────────────────────────────────────────────────

  /// Lista de capítulos de un libro. Orden por número ascendente.
  ///
  /// La UI usa esto para el grid de capítulos (1..N) en el Bible reader.
  Future<List<Capitulo>> getCapitulosByLibro(int libroId) async {
    final db = await _database;
    final rows = await db.query(
      'capitulo',
      where: 'libro_id = ?',
      whereArgs: [libroId],
      orderBy: 'numero ASC',
    );
    return rows.map(Capitulo.fromMap).toList(growable: false);
  }

  /// Devuelve el capítulo (libroId, numero) o null.
  Future<Capitulo?> getCapitulo(int libroId, int numero) async {
    final db = await _database;
    final rows = await db.query(
      'capitulo',
      where: 'libro_id = ? AND numero = ?',
      whereArgs: [libroId, numero],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Capitulo.fromMap(rows.first);
  }

  // ───────────────────────────────────────────────────────────────
  // Versículos
  // ───────────────────────────────────────────────────────────────

  /// Lista de versículos de un capítulo. Orden por número ascendente.
  ///
  /// Decisión arquitectónica implícita: la UI pide el capítulo completo
  /// en una sola query (no paginación por versículos). El bundle típico
  /// (Génesis 1) son ~31 versículos, OK en memoria.
  Future<List<Versiculo>> getVersiculosByCapitulo(int capituloId) async {
    final db = await _database;
    final rows = await db.query(
      'versiculo',
      where: 'capitulo_id = ?',
      whereArgs: [capituloId],
      orderBy: 'numero ASC',
    );
    return rows.map(Versiculo.fromMap).toList(growable: false);
  }

  /// Devuelve el versículo (capituloId, numero) o null.
  Future<Versiculo?> getVersiculo(int capituloId, int numero) async {
    final db = await _database;
    final rows = await db.query(
      'versiculo',
      where: 'capitulo_id = ? AND numero = ?',
      whereArgs: [capituloId, numero],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Versiculo.fromMap(rows.first);
  }

  /// Devuelve el versículo por referencia canónica (versión, número de
  /// libro canónico 1-66, capítulo, versículo) o null.
  ///
  /// Esta es la query principal del emisor-receptor: el dispositivo
  /// receptor recibe un `GoToVerse(versionId, libroNum, cap, num)` por
  /// gRPC y necesita resolverlo a un versículo en una sola query.
  ///
  /// Implementa 3 JOINs encadenados: libro → capítulo → versículo.
  Future<Versiculo?> getVersiculoByReference(
    int versionId,
    int libroNumero,
    int capitulo,
    int numero,
  ) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT v.id, v.capitulo_id, v.numero, v.texto
      FROM versiculo v
      JOIN capitulo c ON c.id = v.capitulo_id
      JOIN libro    l ON l.id = c.libro_id
      WHERE l.version_id = ?
        AND l.numero     = ?
        AND c.numero     = ?
        AND v.numero     = ?
      LIMIT 1;
      ''',
      [versionId, libroNumero, capitulo, numero],
    );
    if (rows.isEmpty) return null;
    return Versiculo.fromMap(rows.first);
  }

  /// Devuelve un versículo aleatorio de la versión indicada.
  ///
  /// Decisión arquitectónica #10: versículo aleatorio en cada cold start
  /// (no "verse del día"). Implementación: `ORDER BY RANDOM() LIMIT 1`.
  ///
  /// NOTA: `RANDOM()` es O(n) en SQLite, pero n=31 102 y se ejecuta solo
  /// 1 vez por cold start, así que es aceptable. Si la latencia fuera un
  /// problema, se podría cachear con `WHERE id IN (SELECT ... ORDER BY
  /// RANDOM() LIMIT 1)` — pero no es necesario para Fase 2a.
  Future<Versiculo?> getRandomVersiculo(int versionId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
      SELECT v.id, v.capitulo_id, v.numero, v.texto
      FROM versiculo v
      JOIN capitulo c ON c.id = v.capitulo_id
      JOIN libro    l ON l.id = c.libro_id
      WHERE l.version_id = ?
      ORDER BY RANDOM()
      LIMIT 1;
      ''',
      [versionId],
    );
    if (rows.isEmpty) {
      _log.warning('getRandomVersiculo: no hay versículos en version $versionId');
      return null;
    }
    return Versiculo.fromMap(rows.first);
  }
}
