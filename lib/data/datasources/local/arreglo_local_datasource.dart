import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/errors/exceptions.dart' as exc;
import '../../models/arreglo_musical_model.dart';
import '../../models/estrofa_arreglo_model.dart';

/// DataSource local para arreglos musicales usando SQLite.
///
/// Encapsula todas las consultas SQL a las tablas [Arreglo_Musical]
/// y [Estrofa_Arreglo]. Las operaciones que afectan ambas tablas
/// se ejecutan dentro de transacciones SQLite para garantizar
/// la integridad referencial.
class ArregloLocalDataSource {
  static final _log = Logger('ArregloLocalDataSource');

  final DatabaseHelper _dbHelper;

  ArregloLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Obtiene la instancia de BD.
  Future<Database> get _db => _dbHelper.database;

  /// Crea un nuevo arreglo musical con sus estrofas en una transacción.
  ///
  /// Retorna el ID auto-generado del arreglo.
  Future<int> createArreglo(
    ArregloMusicalModel arreglo,
    List<EstrofaArregloModel> estrofas,
  ) async {
    try {
      final db = await _db;
      return await db.transaction((txn) async {
        // toJson() incluye 'estrofas' e 'id' (0 para nuevos) que no deben
        // insertarse: 'estrofas' no es columna, 'id' debe auto-incrementarse
        final json = arreglo.toJson()
          ..remove('estrofas')
          ..remove('id');
        final id = await txn.insert('Arreglo_Musical', json);

        for (final estrofa in estrofas) {
          await txn.insert('Estrofa_Arreglo', {
            // Remover 'id' para que SQLite auto-incremente, y
            // 'arreglo_musical_id' porque lo sobreescribimos abajo
            ...estrofa.toJson()
              ..remove('id')
              ..remove('arreglo_musical_id'),
            'arreglo_musical_id': id,
          });
        }

        _log.info(
          'Arreglo #$id creado con ${estrofas.length} estrofa(s).',
        );
        return id;
      });
    } catch (e) {
      _log.severe('Error en createArreglo: $e');
      throw exc.DatabaseException(
        'Error al crear arreglo: $e',
        query: 'createArreglo',
      );
    }
  }

  /// Obtiene todos los arreglos de un usuario, ordenados por
  /// fecha de modificación descendente.
  Future<List<ArregloMusicalModel>> getByUser(int usuarioId) async {
    try {
      final db = await _db;
      final result = await db.query(
        'Arreglo_Musical',
        where: 'usuario_id = ?',
        whereArgs: [usuarioId],
        orderBy: 'fecha_modificacion DESC',
      );

      _log.info(
        '${result.length} arreglo(s) encontrado(s) para usuario #$usuarioId.',
      );
      return result.map((m) => ArregloMusicalModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getByUser: $e');
      throw exc.DatabaseException(
        'Error al obtener arreglos del usuario: $e',
        query: 'getByUser',
      );
    }
  }

  /// Obtiene un arreglo por su ID.
  /// Retorna `null` si no existe.
  Future<ArregloMusicalModel?> getById(int id) async {
    try {
      final db = await _db;
      final result = await db.query(
        'Arreglo_Musical',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        _log.info('Arreglo #$id no encontrado.');
        return null;
      }

      return ArregloMusicalModel.fromMap(result.first);
    } catch (e) {
      _log.severe('Error en getById: $e');
      throw exc.DatabaseException(
        'Error al obtener arreglo por ID: $e',
        query: 'getById',
      );
    }
  }

  /// Obtiene las estrofas de un arreglo, ordenadas por posición.
  Future<List<EstrofaArregloModel>> getEstrofasByArreglo(
    int arregloId,
  ) async {
    try {
      final db = await _db;
      final result = await db.query(
        'Estrofa_Arreglo',
        where: 'arreglo_musical_id = ?',
        whereArgs: [arregloId],
        orderBy: 'orden ASC',
      );

      return result.map((m) => EstrofaArregloModel.fromMap(m)).toList();
    } catch (e) {
      _log.severe('Error en getEstrofasByArreglo: $e');
      throw exc.DatabaseException(
        'Error al obtener estrofas del arreglo: $e',
        query: 'getEstrofasByArreglo',
      );
    }
  }

  /// Actualiza un arreglo musical y reemplaza todas sus estrofas
  /// dentro de una transacción.
  ///
  /// Estrategia: elimina todas las estrofas existentes y las
  /// reinserta con los nuevos valores.
  Future<void> updateArreglo(
    ArregloMusicalModel arreglo,
    List<EstrofaArregloModel> estrofas,
  ) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        final json = arreglo.toJson()..remove('estrofas');

        // Incrementar versión y actualizar fecha de modificación
        await txn.update(
          'Arreglo_Musical',
          {
            ...json,
            'version': arreglo.version + 1,
            'fecha_modificacion':
                DateTime.now().toIso8601String().split('T').first,
          },
          where: 'id = ?',
          whereArgs: [arreglo.id],
        );

        await txn.delete(
          'Estrofa_Arreglo',
          where: 'arreglo_musical_id = ?',
          whereArgs: [arreglo.id],
        );

        for (final estrofa in estrofas) {
          await txn.insert('Estrofa_Arreglo', {
            ...estrofa.toJson()
              ..remove('id')
              ..remove('arreglo_musical_id'),
            'arreglo_musical_id': arreglo.id,
          });
        }
      });

      _log.info(
        'Arreglo #${arreglo.id} actualizado con ${estrofas.length} estrofa(s).',
      );
    } catch (e) {
      _log.severe('Error en updateArreglo: $e');
      throw exc.DatabaseException(
        'Error al actualizar arreglo: $e',
        query: 'updateArreglo',
      );
    }
  }

  /// Elimina un arreglo musical por su ID.
  /// Las estrofas asociadas se eliminan en cascada por la FK.
  ///
  /// Retorna `true` si se eliminó al menos una fila.
  Future<bool> deleteArreglo(int id) async {
    try {
      final db = await _db;
      final rows = await db.delete(
        'Arreglo_Musical',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rows > 0) {
        _log.info('Arreglo #$id eliminado.');
      } else {
        _log.warning('Arreglo #$id no encontrado para eliminar.');
      }

      return rows > 0;
    } catch (e) {
      _log.severe('Error en deleteArreglo: $e');
      throw exc.DatabaseException(
        'Error al eliminar arreglo: $e',
        query: 'deleteArreglo',
      );
    }
  }
}
