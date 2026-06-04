import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/database/bible_database_helper.dart';
import '../models/versiculo_contexto.dart';

/// Repositorio de búsqueda full-text (FTS5) sobre la Biblia.
///
/// Usa la tabla virtual `versiculo_fts` con tokenizador
/// `unicode61 remove_diacritics 2` (decisión #3 de Fase 1):
/// - "José"  == "jose"  (sin tildes)
/// - "María" == "maria"
/// - "Niño"  == "nino"
///
/// Esto es crítico en móvil porque el teclado en pantalla omite tildes.
///
/// ## Sintaxis de query (FTS5 MATCH)
///
/// - Término único: `amor` → matchea todos los versículos con "amor".
/// - Multi-término: `Dios amor` → AND implícito (ambos términos).
/// - Frase exacta: `"camino verdad vida"` → matchea la frase literal.
/// - Negación: `Dios NOT juicio` → matchea "Dios" sin "juicio".
///
/// Estas reglas se validan en `biblia_search_repository_test.dart`.
class BibliaSearchRepository {
  static final _log = Logger('BibliaSearchRepository');

  final BibleDatabaseHelper _db;

  BibliaSearchRepository(this._db);

  /// Acceso a la BD.
  Future<Database> get _database => _db.database;

  /// Búsqueda FTS5 con ranking por relevancia.
  ///
  /// Devuelve hasta [maxResults] versículos (default 5000) que matchean [query],
  /// opcionalmente filtrados por [versionId]. Cada hit incluye el texto
  /// del versículo + metadata del libro/capítulo para que la UI no tenga
  /// que hacer JOINs adicionales.
  ///
  /// Si [query] está vacío o solo contiene espacios, devuelve lista vacía
  /// (no es búsqueda: es la carga inicial de la pantalla).
  Future<List<VersiculoContexto>> search(
    String query, {
    int? versionId,
    int maxResults = 5000,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const <VersiculoContexto>[];

    final db = await _database;

    // Para sintaxis FTS5, el usuario puede tipear `palabra1 palabra2` (AND
    // implícito) o `"frase exacta"`. Si la query no es una frase
    // explícita, envolvemos cada token en comillas para evitar que
    // caracteres especiales (paréntesis, asteriscos, etc.) se interpreten
    // como operadores FTS5. Esto también es más seguro contra injection.
    final ftsQuery = _sanitizeQuery(cleanQuery);

    // Query con JOINs a libro y capítulo para devolver contexto completo.
    // Filtro por versión opcional. Orden por libro/capítulo/versículo (Génesis→Apocalipsis).
    final sql = '''
      SELECT
        v.id, v.capitulo_id, v.numero, v.texto,
        l.version_id, l.nombre AS libro_nombre,
        l.abreviatura AS libro_abreviatura, l.numero AS libro_numero,
        c.numero AS capitulo_numero
      FROM versiculo_fts fts
      JOIN versiculo v ON v.id = fts.rowid
      JOIN capitulo  c ON c.id = v.capitulo_id
      JOIN libro     l ON l.id = c.libro_id
      WHERE versiculo_fts MATCH ?
        ${versionId != null ? 'AND l.version_id = ?' : ''}
      ORDER BY l.numero ASC, c.numero ASC, v.numero ASC
      LIMIT ?;
    ''';

    final args = <Object?>[ftsQuery];
    if (versionId != null) args.add(versionId);
    args.add(maxResults);

    try {
      final rows = await db.rawQuery(sql, args);
      _log.fine('search("$cleanQuery", v=$versionId) → ${rows.length} hits');
      return rows.map(VersiculoContexto.fromJoinedMap).toList(growable: false);
    } catch (e) {
      // FTS5 puede lanzar "fts5: syntax error" con queries malformadas
      // (ej. comillas desbalanceadas). Devolvemos lista vacía en vez de
      // propagar la excepción para no romper la UI.
      _log.warning(
        'search: query malformada "$cleanQuery" → FTS5 error: $e',
      );
      return const <VersiculoContexto>[];
    }
  }

  /// Sanitiza la query del usuario para FTS5.
  ///
  /// Si la query ya viene con `"..."` al inicio y al final (frase exacta
  /// del usuario), se respeta tal cual. En caso contrario, se envuelve
  /// cada token en comillas dobles para neutralizar operadores FTS5
  /// (paréntesis, asteriscos, comillas, etc.) y prevenir errores de
  /// sintaxis que romperían la búsqueda.
  ///
  /// Ejemplos:
  ///   - `amor`               → `"amor"`
  ///   - `Dios amor`          → `"Dios" "amor"`
  ///   - `"camino verdad"`    → `"camino verdad"` (frase, se respeta)
  ///   - `jose*`              → `"jose"` (se quita el asterisco)
  String _sanitizeQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return '""';

    // Si empieza y termina con comillas dobles, es una frase exacta:
    // la respetamos tal cual.
    if (trimmed.startsWith('"') && trimmed.endsWith('"') && trimmed.length >= 2) {
      return trimmed;
    }

    // Caso contrario: separar por espacios y envolver cada token en
    // comillas dobles. FTS5 interpreta `"a" "b"` como AND implícito.
    final tokens = trimmed
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map(_escapeToken)
        .toList();
    if (tokens.isEmpty) return '""';
    return tokens.join(' ');
  }

  /// Escapa un token individual: lo envuelve en comillas y duplica
  /// comillas internas (estándar FTS5).
  String _escapeToken(String token) {
    final escaped = token.replaceAll('"', '""');
    return '"$escaped"';
  }
}
