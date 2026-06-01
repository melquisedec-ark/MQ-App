import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/enums/himno_tipo.dart';
import '../../../core/errors/exceptions.dart' as exc;
import '../../../core/utils/string_utils.dart';

import '../../models/categoria_model.dart';
import '../../models/estrofa_model.dart';
import '../../models/himno_model.dart';
import '../../models/version_pais_model.dart';

/// DataSource local para himnos usando SQLite.
/// Encapsula todas las consultas SQL a la base de datos de himnos.
class HymnLocalDataSource {
  static final _log = Logger('HymnLocalDataSource');

  final DatabaseHelper _dbHelper;

  HymnLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Retorna el ORDER BY por defecto: Oficiales (tipo=1) primero,
  /// luego por número oficial ascendente.
  String get _defaultOrderBy =>
      'CASE WHEN h.tipo = 1 THEN 0 ELSE 1 END, h.numero_oficial ASC';

  /// Obtiene la instancia de BD.
  Future<Database> get _db => _dbHelper.database;

  // ─── Índice de búsqueda plana ──────────────────────────────────

  bool _searchIndexInitialized = false;
  Future<void>? _searchIndexInitFuture;

  /// Asegura que la tabla Himno_Busqueda esté poblada.
  /// La inicialización ocurre una sola vez (lazy, al primer uso).
  Future<void> _ensureSearchIndex(Database db) async {
    if (_searchIndexInitialized) return;
    _searchIndexInitFuture ??= _doInitializeSearchIndex(db);
    await _searchIndexInitFuture;
  }

  /// Pobla Himno_Busqueda normalizando todo en Dart (una sola vez).
  Future<void> _doInitializeSearchIndex(Database db) async {
    final count = await db
        .rawQuery('SELECT COUNT(*) AS cnt FROM Himno_Busqueda');
    final activeCount = await db
        .rawQuery('SELECT COUNT(*) AS cnt FROM Himno WHERE activo = 1');
    if ((count.first['cnt'] as int) >= (activeCount.first['cnt'] as int)) {
      _searchIndexInitialized = true;
      return;
    }

    _log.info('Inicializando índice de búsqueda...');

    // Limpiar índice existente para empezar desde cero
    await db.execute('DELETE FROM Himno_Busqueda');

    // Obtener todos los himnos activos
    final hymns = await db.rawQuery(
      'SELECT id, titulo_principal FROM Himno WHERE activo = 1',
    );
    final hymnIds = hymns.map((h) => h['id'] as int).toList();
    if (hymnIds.isEmpty) {
      _searchIndexInitialized = true;
      return;
    }

    // Obtener todas las estrofas en una sola consulta
    final placeholders = hymnIds.map((_) => '?').join(',');
    final allContent = await db.rawQuery(
      'SELECT vp.himno_id, e.contenido '
      'FROM Estrofa e '
      'JOIN Version_Pais vp ON vp.id = e.version_pais_id '
      'WHERE vp.himno_id IN ($placeholders) AND vp.activo = 1 '
      'ORDER BY vp.himno_id, vp.id, e.orden',
      hymnIds,
    );

    // Agrupar contenido por himno_id en Dart
    final contentByHymn = <int, List<String>>{};
    for (final row in allContent) {
      final hid = row['himno_id'] as int;
      contentByHymn.putIfAbsent(hid, () => []);
      contentByHymn[hid]!.add(row['contenido'] as String);
    }

      await db.transaction((txn) async {
        for (final h in hymns) {
          final id = h['id'] as int;
          final titulo = h['titulo_principal'] as String;
          final stanzas = contentByHymn[id] ?? <String>[];
          final allText = stanzas.join(' ');

          await txn.insert(
            'Himno_Busqueda',
            {
              'himno_id': id,
              'titulo_normalizado': StringUtils.normalizeForSearch(titulo),
              'contenido_normalizado': StringUtils.normalizeForSearch(allText),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

    _searchIndexInitialized = true;
    _log
        .info('Índice de búsqueda inicializado con ${hymns.length} himnos.');
  }

  /// Busca himnos por texto (título, número o contenido de estrofas)
  /// usando el índice plano Himno_Busqueda (pre-normalizado en Dart).
  ///
  /// [query] texto de búsqueda. Si está vacío, aplica solo filtros.
  /// [orderBy] permite ordenar: 'titulo_principal ASC' (A-Z),
  ///   'titulo_principal DESC' (Z-A), o 'h.numero_oficial ASC' (default).
  /// [categoriaId] filtra himnos que pertenecen a la categoría indicada.
  Future<List<HimnoModel>> searchHymns(String query, {
    HimnoTipo? tipo,
    String? orderBy,
    int? categoriaId,
  }) async {
    try {
      final db = await _db;

      // Asegurar índice de búsqueda poblado (lazy, una sola vez)
      await _ensureSearchIndex(db);

      // Sin query → solo filtros
      if (query.isEmpty) {
        return _searchWithFilters(
          db, tipo: tipo, orderBy: orderBy, categoriaId: categoriaId,
        );
      }

      final normalizedQuery = StringUtils.normalizeForSearch(query);
      if (normalizedQuery.isEmpty) {
        return _searchWithFilters(
          db, tipo: tipo, orderBy: orderBy, categoriaId: categoriaId,
        );
      }

      // ─── Una sola consulta SQL sobre la tabla plana ───
      final conditions = <String>['h.activo = 1'];
      final params = <dynamic>[];

      conditions.add(
        '(hb.titulo_normalizado LIKE ? OR hb.contenido_normalizado LIKE ? '
        'OR CAST(h.numero_oficial AS TEXT) LIKE ?)',
      );
      final likeParam = '%$normalizedQuery%';
      params.addAll([likeParam, likeParam, likeParam]);

      if (tipo != null) {
        conditions.add('h.tipo = ?');
        params.add(tipo.value);
      }

      final effectiveOrderBy =
          (orderBy != null && orderBy.contains('titulo_principal'))
              ? null
              : (orderBy ?? _defaultOrderBy);
      final orderClause = effectiveOrderBy ?? _defaultOrderBy;

      // Params extra para ORDER BY CASE
      params.addAll([normalizedQuery, '$normalizedQuery%']);

      String sql;
      if (categoriaId != null) {
        conditions.add('hc.categoria_id = ?');
        params.add(categoriaId);
        sql = '''
          SELECT DISTINCT h.id, h.titulo_principal, h.numero_oficial, h.tipo, h.activo
          FROM Himno_Busqueda hb
          INNER JOIN Himno h ON h.id = hb.himno_id
          INNER JOIN Himno_Categoria hc ON hc.himno_id = h.id
          WHERE ${conditions.join(' AND ')}
          ORDER BY
            CASE
              WHEN hb.titulo_normalizado = ? THEN 0
              WHEN hb.titulo_normalizado LIKE ? THEN 1
              ELSE 2
            END,
            $orderClause
        ''';
      } else {
        sql = '''
          SELECT h.id, h.titulo_principal, h.numero_oficial, h.tipo, h.activo
          FROM Himno_Busqueda hb
          INNER JOIN Himno h ON h.id = hb.himno_id
          WHERE ${conditions.join(' AND ')}
          ORDER BY
            CASE
              WHEN hb.titulo_normalizado = ? THEN 0
              WHEN hb.titulo_normalizado LIKE ? THEN 1
              ELSE 2
            END,
            $orderClause
        ''';
      }

      final rawMaps = await db.rawQuery(sql, params);
      var allHimnos = rawMaps.map((m) => HimnoModel.fromMap(m)).toList();

      // Cargar versiones y categorías en lote (2 queries totales)
      await _loadVersionsAndCategories(db, allHimnos);

      // Orden alfabético en Dart (si aplica)
      if (orderBy != null && orderBy.contains('titulo_principal')) {
        allHimnos.sort((a, b) => StringUtils.compareForSort(
          a.tituloPrincipal,
          b.tituloPrincipal,
        ),);
        if (orderBy.contains('DESC')) {
          allHimnos = allHimnos.reversed.toList();
        }
      }

      _log.info('Búsqueda "$query" encontró ${allHimnos.length} resultados.');
      return allHimnos;
    } catch (e) {
      _log.severe('Error en searchHymns: $e');
      throw exc.DatabaseException(
        'Error al buscar himnos: $e',
        query: 'searchHymns',
      );
    }
  }

  /// Helper para búsqueda con filtros sin texto (flujo existente optimizado).
  Future<List<HimnoModel>> _searchWithFilters(Database db, {
    HimnoTipo? tipo,
    String? orderBy,
    int? categoriaId,
  }) async {
    final conditions = <String>[];
    final params = <dynamic>[];

    if (tipo != null) {
      conditions.add('h.tipo = ?');
      params.add(tipo.value);
    }
    conditions.add('h.activo = 1');

    List<Map<String, dynamic>> maps;
    final effectiveOrderBy = (orderBy != null && orderBy.contains('titulo_principal'))
        ? null
        : (orderBy ?? _defaultOrderBy);

    if (categoriaId != null) {
      conditions.add('hc.categoria_id = ?');
      params.add(categoriaId);
      maps = await db.rawQuery('''
        SELECT DISTINCT h.id, h.titulo_principal, h.numero_oficial, h.tipo, h.activo
        FROM Himno h
        INNER JOIN Himno_Categoria hc ON hc.himno_id = h.id
        WHERE ${conditions.join(' AND ')}
        ORDER BY ${effectiveOrderBy ?? _defaultOrderBy}
      ''', params,);
    } else {
      maps = await db.rawQuery('''
        SELECT h.id, h.titulo_principal, h.numero_oficial, h.tipo, h.activo
        FROM Himno h
        WHERE ${conditions.join(' AND ')}
        ORDER BY ${effectiveOrderBy ?? _defaultOrderBy}
      ''', params,);
    }

    var himnos = maps.map((m) => HimnoModel.fromMap(m)).toList();

    // Cargar versiones y categorías en lote (2 queries totales)
    await _loadVersionsAndCategories(db, himnos);

    // Orden alfabético en Dart (si aplica)
    if (effectiveOrderBy == null && orderBy != null && orderBy.contains('titulo_principal')) {
      himnos.sort((a, b) => StringUtils.compareForSort(a.tituloPrincipal, b.tituloPrincipal));
      if (orderBy.contains('DESC')) {
        himnos = himnos.reversed.toList();
      }
    }

    return himnos;
  }

  /// Obtiene un himno completo por su ID incluyendo versiones, estrofas y categorías.
  Future<HimnoModel> getHymnById(int id) async {
    try {
      final db = await _db;

      final maps = await db.query(
        'Himno',
        where: 'id = ? AND activo = 1',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw const exc.NotFoundException(
          'Himno no encontrado',
          entityType: 'Himno',
        );
      }

      final himno = HimnoModel.fromMap(maps.first);

      // Cargar versiones de país (con JOIN a Pais)
      final versionMaps = await db.rawQuery(
        'SELECT vp.*, p.nombre AS pais_nombre, p.codigo AS pais_codigo '
        'FROM Version_Pais vp '
        'LEFT JOIN Pais p ON p.id = vp.pais_id '
        'WHERE vp.himno_id = ? AND vp.activo = 1',
        [id],
      );
      final versiones =
          versionMaps.map((vm) => VersionPaisModel.fromMap(vm)).toList();

      // Cargar estrofas para cada versión
      for (final version in versiones) {
        final estrofaMaps = await db.query(
          'Estrofa',
          where: 'version_pais_id = ?',
          whereArgs: [version.id],
          orderBy: 'orden ASC',
        );
        version.estrofas =
            estrofaMaps.map((em) => EstrofaModel.fromMap(em)).toList();
      }

      // Cargar categorías
      final catMaps = await db.rawQuery(
        '''
        SELECT c.id, c.nombre
        FROM Categoria c
        INNER JOIN Himno_Categoria hc ON hc.categoria_id = c.id
        WHERE hc.himno_id = ?
      ''',
        [id],
      );
      himno.categorias =
          catMaps.map((cm) => CategoriaModel.fromMap(cm)).toList();

      himno.versiones = versiones;

      _log.info('Himno #$id cargado con ${versiones.length} versión(es).');
      return himno;
    } on exc.NotFoundException {
      rethrow;
    } catch (e) {
      _log.severe('Error en getHymnById: $e');
      throw exc.DatabaseException(
        'Error al obtener himno: $e',
        query: 'getHymnById',
      );
    }
  }

  /// Obtiene las estrofas de una versión de país específica.
  Future<List<EstrofaModel>> getStanzas(int versionPaisId) async {
    try {
      final db = await _db;

      final maps = await db.query(
        'Estrofa',
        where: 'version_pais_id = ?',
        whereArgs: [versionPaisId],
        orderBy: 'orden ASC',
      );

      return maps.map((m) => EstrofaModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getStanzas: $e');
      throw exc.DatabaseException(
        'Error al obtener estrofas: $e',
        query: 'getStanzas',
      );
    }
  }

  /// Obtiene todas las categorías disponibles.
  Future<List<CategoriaModel>> getCategories() async {
    try {
      final db = await _db;

      final maps = await db.query(
        'Categoria',
        orderBy: 'nombre ASC',
      );

      return maps.map((m) => CategoriaModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getCategories: $e');
      throw exc.DatabaseException(
        'Error al obtener categorías: $e',
        query: 'getCategories',
      );
    }
  }

  /// Obtiene los himnos pertenecientes a una categoría.
  Future<List<HimnoModel>> getHymnsByCategory(int categoriaId) async {
    try {
      final db = await _db;

      final maps = await db.rawQuery(
        '''
        SELECT h.id, h.titulo_principal, h.numero_oficial, h.tipo, h.activo
        FROM Himno h
        INNER JOIN Himno_Categoria hc ON hc.himno_id = h.id
        WHERE hc.categoria_id = ? AND h.activo = 1
        ORDER BY $_defaultOrderBy
      ''',
        [categoriaId],
      );

      final himnos = maps.map((m) => HimnoModel.fromMap(m)).toList();

      // Cargar versiones en lote
      await _loadVersionsAndCategories(db, himnos);
      return himnos;
    } catch (e) {
      _log.severe('Error en getHymnsByCategory: $e');
      throw exc.DatabaseException(
        'Error al obtener himnos por categoría: $e',
        query: 'getHymnsByCategory',
      );
    }
  }

  /// Inserta un himno completo con sus versiones, estrofas y categorías
  /// en una sola transacción SQLite.
  ///
  /// [himnoData] mapa con columnas de la tabla Himno (sin id).
  /// [versiones] lista de mapas con datos de Version_Pais (sin himno_id).
  /// [estrofas] lista de mapas con datos de Estrofa. Cada estrofa debe incluir
  ///   una clave `version_idx` (int) que indica el índice (0-based) dentro de
  ///   [versiones] a la que pertenece.
  /// [categoriaIds] IDs de categorías a asociar.
  ///
  /// Retorna el ID del himno recién creado.
  Future<int> insertHymnCompleto(
    Map<String, dynamic> himnoData,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds,
  ) async {
    try {
      final db = await _db;

      return await db.transaction((txn) async {
        // 1. Insertar el himno
        final himnoId = await txn.insert('Himno', himnoData);

        // 2. Insertar versiones de país y mantener el mapeo índice → id
        final versionIdByIndex = <int, int>{};
        for (int i = 0; i < versiones.length; i++) {
          final v = Map<String, dynamic>.from(versiones[i])
            ..['himno_id'] = himnoId;
          v.putIfAbsent('activo', () => 1);
          final versionId = await txn.insert('Version_Pais', v);
          versionIdByIndex[i] = versionId;
        }

        // 3. Insertar estrofas (cada estrofa tiene `version_idx`)
        for (final e in estrofas) {
          final estrofa = Map<String, dynamic>.from(e);
          final versionIdx = estrofa.remove('version_idx') as int;
          estrofa['version_pais_id'] = versionIdByIndex[versionIdx]!;
          await txn.insert('Estrofa', estrofa);
        }

        // 4. Asociar categorías
        for (final catId in categoriaIds) {
          await txn.insert('Himno_Categoria', {
            'himno_id': himnoId,
            'categoria_id': catId,
          });
        }

        // 5. Insertar en índice de búsqueda
        final allContent = estrofas
            .map((e) => e['contenido'] as String)
            .join(' ');
        await txn.insert('Himno_Busqueda', {
          'himno_id': himnoId,
          'titulo_normalizado':
              StringUtils.normalizeForSearch(himnoData['titulo_principal'] as String),
          'contenido_normalizado': StringUtils.normalizeForSearch(allContent),
        });

        _log.info(
          'Himno #$himnoId creado con ${versiones.length} versión(es), '
          '${estrofas.length} estrofa(s) y ${categoriaIds.length} categoría(s).',
        );

        return himnoId;
      });
    } catch (e) {
      _log.severe('Error en insertHymnCompleto: $e');
      throw exc.DatabaseException(
        'Error al insertar himno completo: $e',
        query: 'insertHymnCompleto',
      );
    }
  }

  /// Actualiza un himno completo con sus versiones, estrofas y categorías
  /// en una sola transacción SQLite.
  ///
  /// Elimina todos los registros hijos existentes (versiones, estrofas,
  /// categorías) y los reinserta con los nuevos datos.
  ///
  /// [himnoId] ID del himno a actualizar.
  /// [himnoData] mapa con las columnas a modificar de la tabla Himno (sin id).
  /// [versiones], [estrofas], [categoriaIds] ídem que en [insertHymnCompleto].
  Future<void> updateHymnCompleto(
    int himnoId,
    Map<String, dynamic> himnoData,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds,
  ) async {
    try {
      final db = await _db;

      await db.transaction((txn) async {
        // 1. Actualizar el himno
        await txn.update(
          'Himno',
          himnoData,
          where: 'id = ?',
          whereArgs: [himnoId],
        );

        // 2. Eliminar versiones existentes (cascadea estrofas automáticamente)
        await txn.delete(
          'Version_Pais',
          where: 'himno_id = ?',
          whereArgs: [himnoId],
        );

        // 3. Eliminar asociaciones de categorías existentes
        await txn.delete(
          'Himno_Categoria',
          where: 'himno_id = ?',
          whereArgs: [himnoId],
        );

        // 4. Re-insertar versiones de país
        final versionIdByIndex = <int, int>{};
        for (int i = 0; i < versiones.length; i++) {
          final v = Map<String, dynamic>.from(versiones[i])
            ..['himno_id'] = himnoId;
          v.putIfAbsent('activo', () => 1);
          final versionId = await txn.insert('Version_Pais', v);
          versionIdByIndex[i] = versionId;
        }

        // 5. Re-insertar estrofas
        for (final e in estrofas) {
          final estrofa = Map<String, dynamic>.from(e);
          final versionIdx = estrofa.remove('version_idx') as int;
          estrofa['version_pais_id'] = versionIdByIndex[versionIdx]!;
          await txn.insert('Estrofa', estrofa);
        }

        // 6. Re-insertar categorías
        for (final catId in categoriaIds) {
          await txn.insert('Himno_Categoria', {
            'himno_id': himnoId,
            'categoria_id': catId,
          });
        }

        // 7. Actualizar índice de búsqueda
        final allContent = estrofas
            .map((e) => e['contenido'] as String)
            .join(' ');
        await txn.insert(
          'Himno_Busqueda',
          {
            'himno_id': himnoId,
            'titulo_normalizado':
                StringUtils.normalizeForSearch(himnoData['titulo_principal'] as String),
            'contenido_normalizado': StringUtils.normalizeForSearch(allContent),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        _log.info(
          'Himno #$himnoId actualizado con ${versiones.length} versión(es), '
          '${estrofas.length} estrofa(s) y ${categoriaIds.length} categoría(s).',
        );
      });
    } catch (e) {
      _log.severe('Error en updateHymnCompleto: $e');
      throw exc.DatabaseException(
        'Error al actualizar himno completo: $e',
        query: 'updateHymnCompleto',
      );
    }
  }

  /// Verifica si un himno tiene referencias en otras tablas
  /// (arreglos musicales, pistas de audio, historial de reproducción).
  Future<bool> hymnHasReferences(int himnoId) async {
    try {
      final db = await _db;

      final result = await db.rawQuery('''
        SELECT
          (SELECT COUNT(*) FROM Arreglo_Musical am
           INNER JOIN Version_Pais vp ON vp.id = am.version_pais_id
           WHERE vp.himno_id = ?) +
          (SELECT COUNT(*) FROM Pista_Audio WHERE himno_id = ?) +
          (SELECT COUNT(*) FROM Historial_Reproduccion WHERE himno_id = ?)
        AS total
      ''', [himnoId, himnoId, himnoId],);

      final total = result.first['total'] as int;
      return total > 0;
    } catch (e) {
      _log.severe('Error en hymnHasReferences: $e');
      throw exc.DatabaseException(
        'Error al verificar referencias del himno: $e',
        query: 'hymnHasReferences',
      );
    }
  }

  /// Marca un himno como inactivo (soft-delete).
  Future<void> deleteHymn(int id) async {
    try {
      final db = await _db;
      await db.update(
        'Himno',
        {'activo': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      _log.info('Himno #$id marcado como inactivo (soft-delete).');
    } catch (e) {
      _log.severe('Error en deleteHymn: $e');
      throw exc.DatabaseException(
        'Error al eliminar himno: $e',
        query: 'deleteHymn',
      );
    }
  }

  /// Crea una nueva categoría y retorna el modelo con el ID asignado.
  Future<CategoriaModel> createCategoria(String nombre) async {
    try {
      final db = await _db;
      final id = await db.insert('Categoria', {'nombre': nombre});
      _log.info('Categoría "$nombre" creada con ID $id.');
      return CategoriaModel(id: id, nombre: nombre);
    } catch (e) {
      _log.severe('Error en createCategoria: $e');
      throw exc.DatabaseException(
        'Error al crear categoría: $e',
        query: 'createCategoria',
      );
    }
  }

  /// Elimina una categoría por su ID.
  Future<void> deleteCategoriaById(int id) async {
    try {
      final db = await _db;
      await db.delete('Categoria', where: 'id = ?', whereArgs: [id]);
      _log.info('Categoría #$id eliminada.');
    } catch (e) {
      _log.severe('Error en deleteCategoria: $e');
      throw exc.DatabaseException(
        'Error al eliminar categoría: $e',
        query: 'deleteCategoria',
      );
    }
  }

  @Deprecated('Usar ArregloLocalDataSource.createArreglo en su lugar')
  Future<int> createArrangement({
    required int versionPaisId,
    required int usuarioId,
    required String nombreArreglo,
    required String tonalidadBase,
    required List<({String tipo, int orden, String contenido})> estrofas,
  }) async {
    try {
      final db = await _db;

      final arrangementId = await db.insert('Arreglo_Musical', {
        'version_pais_id': versionPaisId,
        'usuario_id': usuarioId,
        'nombre_arreglo': nombreArreglo,
        'tonalidad_base': tonalidadBase,
        'version': 1,
      });

      for (final estrofa in estrofas) {
        await db.insert('Estrofa_Arreglo', {
          'arreglo_musical_id': arrangementId,
          'tipo': estrofa.tipo,
          'orden': estrofa.orden,
          'contenido': estrofa.contenido,
        });
      }

      _log.info(
        'Arreglo "$nombreArreglo" creado con ID $arrangementId '
        '(${estrofas.length} estrofas).',
      );
      return arrangementId;
    } catch (e) {
      _log.severe('Error en createArrangement: $e');
      throw exc.DatabaseException(
        'Error al crear arreglo: $e',
        query: 'createArrangement',
      );
    }
  }

  /// Carga versiones y categorías para una lista de himnos usando solo
  /// **2 consultas SQL** en lugar de 2 por himno (elimina el N+1).
  ///
  /// Esto es crítico en Android donde cada consulta cruza el MethodChannel
  /// con ~0.5–2ms de overhead. Para 40 himnos: 2 queries vs 80 queries.
  Future<void> _loadVersionsAndCategories(
    Database db,
    List<HimnoModel> himnos,
  ) async {
    if (himnos.isEmpty) return;

    final ids = himnos.map((h) => h.id).toList();
    final placeholders = ids.map((_) => '?').join(',');

    // 1. Cargar todas las versiones en una sola consulta
    final versionMaps = await db.rawQuery('''
      SELECT vp.*, p.nombre AS pais_nombre, p.codigo AS pais_codigo
      FROM Version_Pais vp
      LEFT JOIN Pais p ON p.id = vp.pais_id
      WHERE vp.himno_id IN ($placeholders) AND vp.activo = 1
    ''', ids,);

    final versionesByHymnId = <int, List<VersionPaisModel>>{};
    for (final vm in versionMaps) {
      final himnoId = vm['himno_id'] as int;
      versionesByHymnId.putIfAbsent(himnoId, () => []);
      versionesByHymnId[himnoId]!.add(VersionPaisModel.fromMap(vm));
    }

    // 2. Cargar todas las categorías en una sola consulta
    final catMaps = await db.rawQuery('''
      SELECT hc.himno_id, c.id, c.nombre
      FROM Himno_Categoria hc
      JOIN Categoria c ON c.id = hc.categoria_id
      WHERE hc.himno_id IN ($placeholders)
    ''', ids,);

    final catsByHymnId = <int, List<CategoriaModel>>{};
    for (final cm in catMaps) {
      final himnoId = cm['himno_id'] as int;
      catsByHymnId.putIfAbsent(himnoId, () => []);
      catsByHymnId[himnoId]!.add(
        CategoriaModel(id: cm['id'] as int, nombre: cm['nombre'] as String),
      );
    }

    // 3. Asignar a cada himno
    for (final himno in himnos) {
      himno.versiones = versionesByHymnId[himno.id] ?? [];
      himno.categorias = catsByHymnId[himno.id] ?? [];
    }
  }
}

