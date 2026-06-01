import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/errors/exceptions.dart' as exc;
import '../../models/categoria_model.dart';
import '../../models/pais_model.dart';
import '../../models/pista_audio_model.dart';
import '../../models/fondo_pantalla_model.dart';
import '../../models/usuario_model.dart';

/// DataSource local para operaciones CRUD sobre tablas de catálogo
/// (Categoria, Pais, Pista_Audio, Fondo_Pantalla).
class CatalogLocalDataSource {
  static final _log = Logger('CatalogLocalDataSource');

  final DatabaseHelper _dbHelper;

  CatalogLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Obtiene la instancia de BD.
  Future<Database> get _db => _dbHelper.database;

  // ─── CATEGORÍAS ─────────────────────────────────────────────

  /// Obtiene todas las categorías ordenadas alfabéticamente.
  Future<List<CategoriaModel>> getAllCategorias() async {
    try {
      final db = await _db;
      final result = await db.query('Categoria', orderBy: 'nombre ASC');
      return result.map((m) => CategoriaModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getAllCategorias: $e');
      throw exc.DatabaseException(
        'Error al obtener categorías: $e',
        query: 'getAllCategorias',
      );
    }
  }

  /// Inserta una nueva categoría con el [nombre] dado.
  /// Retorna el ID autogenerado.
  Future<int> insertCategoria(String nombre) async {
    try {
      final db = await _db;
      final id = await db.insert('Categoria', {'nombre': nombre});
      _log.info('Categoría "$nombre" creada con ID: $id');
      return id;
    } catch (e) {
      _log.severe('Error en insertCategoria: $e');
      throw exc.DatabaseException(
        'Error al insertar categoría: $e',
        query: 'insertCategoria',
      );
    }
  }

  /// Actualiza el nombre de una categoría existente.
  Future<void> updateCategoria(int id, String nombre) async {
    try {
      final db = await _db;
      final rows = await db.update(
        'Categoria',
        {'nombre': nombre},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows > 0) {
        _log.info('Categoría #$id renombrada a "$nombre".');
      } else {
        _log.warning('Categoría #$id no encontrada para actualizar.');
      }
    } catch (e) {
      _log.severe('Error en updateCategoria: $e');
      throw exc.DatabaseException(
        'Error al actualizar categoría: $e',
        query: 'updateCategoria',
      );
    }
  }

  /// Elimina una categoría por su [id].
  /// Las relaciones en Himno_Categoria se eliminan en cascada por la FK.
  Future<void> deleteCategoria(int id) async {
    try {
      final db = await _db;
      final rows = await db.delete(
        'Categoria',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows > 0) {
        _log.info('Categoría #$id eliminada.');
      } else {
        _log.warning('Categoría #$id no encontrada para eliminar.');
      }
    } catch (e) {
      _log.severe('Error en deleteCategoria: $e');
      throw exc.DatabaseException(
        'Error al eliminar categoría: $e',
        query: 'deleteCategoria',
      );
    }
  }

  // ─── PAÍSES ─────────────────────────────────────────────────

  /// Obtiene todos los países ordenados alfabéticamente por nombre.
  Future<List<PaisModel>> getAllPaises() async {
    try {
      final db = await _db;
      final result = await db.query('Pais', orderBy: 'nombre ASC');
      return result.map((m) => PaisModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getAllPaises: $e');
      throw exc.DatabaseException(
        'Error al obtener países: $e',
        query: 'getAllPaises',
      );
    }
  }

  /// Inserta un nuevo país con [nombre] y opcional [codigo].
  /// Retorna el ID autogenerado.
  Future<int> insertPais(String nombre, {String? codigo}) async {
    try {
      final db = await _db;
      final id = await db.insert('Pais', {
        'nombre': nombre,
        'codigo': codigo,
      });
      _log.info('País "$nombre" creado con ID: $id');
      return id;
    } catch (e) {
      _log.severe('Error en insertPais: $e');
      throw exc.DatabaseException(
        'Error al insertar país: $e',
        query: 'insertPais',
      );
    }
  }

  /// Actualiza los datos de un país existente.
  Future<void> updatePais(PaisModel pais) async {
    try {
      final db = await _db;
      final rows = await db.update(
        'Pais',
        {
          'nombre': pais.nombre,
          'codigo': pais.codigo,
        },
        where: 'id = ?',
        whereArgs: [pais.id],
      );
      if (rows > 0) {
        _log.info('País #${pais.id} actualizado.');
      } else {
        _log.warning('País #${pais.id} no encontrado para actualizar.');
      }
    } catch (e) {
      _log.severe('Error en updatePais: $e');
      throw exc.DatabaseException(
        'Error al actualizar país: $e',
        query: 'updatePais',
      );
    }
  }

  /// Elimina un país por su [id].
  Future<void> deletePais(int id) async {
    try {
      final db = await _db;
      final rows = await db.delete(
        'Pais',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows > 0) {
        _log.info('País #$id eliminado.');
      } else {
        _log.warning('País #$id no encontrado para eliminar.');
      }
    } catch (e) {
      _log.severe('Error en deletePais: $e');
      throw exc.DatabaseException(
        'Error al eliminar país: $e',
        query: 'deletePais',
      );
    }
  }

  // ─── PISTAS DE AUDIO ──────────────────────────────────────

  /// Obtiene todas las pistas de audio asociadas a un himno.
  Future<List<PistaAudioModel>> getPistasByHimno(int himnoId) async {
    try {
      final db = await _db;
      final result = await db.query(
        'Pista_Audio',
        where: 'himno_id = ?',
        whereArgs: [himnoId],
        orderBy: 'id ASC',
      );
      return result.map((m) => PistaAudioModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getPistasByHimno: $e');
      throw exc.DatabaseException(
        'Error al obtener pistas del himno: $e',
        query: 'getPistasByHimno',
      );
    }
  }

  /// Inserta una nueva pista de audio.
  /// Retorna el ID autogenerado.
  Future<int> insertPista(PistaAudioModel pista) async {
    try {
      final db = await _db;
      final id = await db.insert('Pista_Audio', {
        'himno_id': pista.himnoId,
        'ruta_archivo': pista.rutaArchivo,
        'descripcion': pista.descripcion,
        'duracion_segundos': pista.duracionSegundos,
        'formato': pista.formato,
        'origen': pista.origen,
      });
      _log.info('Pista #$id insertada para himno #${pista.himnoId}.');
      return id;
    } catch (e) {
      _log.severe('Error en insertPista: $e');
      throw exc.DatabaseException(
        'Error al insertar pista: $e',
        query: 'insertPista',
      );
    }
  }

  /// Elimina una pista de audio por su [id].
  Future<void> deletePista(int id) async {
    try {
      final db = await _db;
      final rows = await db.delete(
        'Pista_Audio',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows > 0) {
        _log.info('Pista #$id eliminada.');
      } else {
        _log.warning('Pista #$id no encontrada para eliminar.');
      }
    } catch (e) {
      _log.severe('Error en deletePista: $e');
      throw exc.DatabaseException(
        'Error al eliminar pista: $e',
        query: 'deletePista',
      );
    }
  }

  // ─── FONDOS DE PANTALLA ─────────────────────────────────────

  /// Obtiene todos los fondos de pantalla ordenados por nombre.
  Future<List<FondoPantallaModel>> getAllFondos() async {
    try {
      final db = await _db;
      final result = await db.query('Fondo_Pantalla', orderBy: 'nombre ASC');
      return result.map((m) => FondoPantallaModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getAllFondos: $e');
      throw exc.DatabaseException(
        'Error al obtener fondos de pantalla: $e',
        query: 'getAllFondos',
      );
    }
  }

  /// Obtiene un fondo de pantalla por su [id].
  /// Retorna `null` si no existe.
  Future<FondoPantallaModel?> getFondoById(int id) async {
    try {
      final db = await _db;
      final result = await db.query(
        'Fondo_Pantalla',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) return null;
      return FondoPantallaModel.fromMap(result.first);
    } catch (e) {
      _log.severe('Error en getFondoById: $e');
      throw exc.DatabaseException(
        'Error al obtener fondo por ID: $e',
        query: 'getFondoById',
      );
    }
  }

  /// Obtiene el fondo de pantalla predeterminado (activo).
  /// Retorna `null` si no hay ninguno configurado.
  Future<FondoPantallaModel?> getDefaultFondo() async {
    try {
      final db = await _db;
      final result = await db.query(
        'Fondo_Pantalla',
        where: 'es_predeterminado = 1 AND activo = 1',
        limit: 1,
      );
      if (result.isEmpty) return null;
      return FondoPantallaModel.fromMap(result.first);
    } catch (e) {
      _log.severe('Error en getDefaultFondo: $e');
      throw exc.DatabaseException(
        'Error al obtener fondo predeterminado: $e',
        query: 'getDefaultFondo',
      );
    }
  }

  /// Inserta un nuevo fondo de pantalla.
  /// Retorna el ID autogenerado.
  Future<int> insertFondo(FondoPantallaModel fondo) async {
    try {
      final db = await _db;
      final id = await db.insert('Fondo_Pantalla', {
        'nombre': fondo.nombre,
        'tipo': fondo.tipo,
        'ruta_archivo': fondo.ruta_archivo,
        'color_hex': fondo.color_hex,
        'es_predeterminado': fondo.es_predeterminado,
        'activo': fondo.activo,
      });
      _log.info('Fondo #$id creado: "${fondo.nombre}".');
      return id;
    } catch (e) {
      _log.severe('Error en insertFondo: $e');
      throw exc.DatabaseException(
        'Error al insertar fondo: $e',
        query: 'insertFondo',
      );
    }
  }

  /// Actualiza los datos de un fondo de pantalla existente.
  Future<void> updateFondo(FondoPantallaModel fondo) async {
    try {
      final db = await _db;
      final rows = await db.update(
        'Fondo_Pantalla',
        {
          'nombre': fondo.nombre,
          'tipo': fondo.tipo,
          'ruta_archivo': fondo.ruta_archivo,
          'color_hex': fondo.color_hex,
          'es_predeterminado': fondo.es_predeterminado,
          'activo': fondo.activo,
        },
        where: 'id = ?',
        whereArgs: [fondo.id],
      );
      if (rows > 0) {
        _log.info('Fondo #${fondo.id} actualizado.');
      } else {
        _log.warning('Fondo #${fondo.id} no encontrado para actualizar.');
      }
    } catch (e) {
      _log.severe('Error en updateFondo: $e');
      throw exc.DatabaseException(
        'Error al actualizar fondo: $e',
        query: 'updateFondo',
      );
    }
  }

  /// Elimina un fondo de pantalla por su [id].
  Future<void> deleteFondo(int id) async {
    try {
      final db = await _db;
      final rows = await db.delete(
        'Fondo_Pantalla',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows > 0) {
        _log.info('Fondo #$id eliminado.');
      } else {
        _log.warning('Fondo #$id no encontrado para eliminar.');
      }
    } catch (e) {
      _log.severe('Error en deleteFondo: $e');
      throw exc.DatabaseException(
        'Error al eliminar fondo: $e',
        query: 'deleteFondo',
      );
    }
  }

  // ─── USUARIOS ────────────────────────────────────────────

  /// Obtiene todos los usuarios ordenados por nombre.
  Future<List<UsuarioModel>> getAllUsuarios() async {
    try {
      final db = await _db;
      final result = await db.query('Usuario', orderBy: 'nombre ASC');
      return result.map((m) => UsuarioModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error al obtener usuarios: $e');
      throw exc.DatabaseException('Error al obtener usuarios: $e');
    }
  }

  /// Crea un nuevo usuario.
  Future<int> insertUsuario(UsuarioModel usuario) async {
    try {
      final db = await _db;
      final map = usuario.toMap(includeId: false);
      map.remove('fecha_registro');
      final id = await db.insert('Usuario', map);
      return id;
    } catch (e) {
      _log.severe('Error al crear usuario: $e');
      throw exc.DatabaseException('Error al crear usuario: $e');
    }
  }

  /// Actualiza un usuario existente.
  Future<void> updateUsuario(UsuarioModel usuario) async {
    try {
      final db = await _db;
      await db.update(
        'Usuario',
        usuario.toMap(),
        where: 'id = ?',
        whereArgs: [usuario.id],
      );
    } catch (e) {
      _log.severe('Error al actualizar usuario: $e');
      throw exc.DatabaseException('Error al actualizar usuario: $e');
    }
  }

  /// Elimina un usuario por ID.
  Future<void> deleteUsuario(int id) async {
    try {
      final db = await _db;
      await db.delete('Usuario', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      _log.severe('Error al eliminar usuario: $e');
      throw exc.DatabaseException('Error al eliminar usuario: $e');
    }
  }
}
