import 'package:sqflite_common/sqlite_api.dart';

/// Utilidad para backup y restore de datos de usuario durante
/// actualizaciones del asset de base de datos.
///
/// Orden de exportación/importación:
/// 1. Tablas padre (Usuario, Fondo_Pantalla)
/// 2. Tablas hijo (Arreglo_Musical → Estrofa_Arreglo, Pista_Audio,
///    Historial_Reproduccion, Configuracion)
class UserDataBackup {
  UserDataBackup._();

  /// Tablas de usuario que deben ser preservadas durante una actualización.
  static const _userTables = [
    'Usuario',
    'Fondo_Pantalla',
    'Arreglo_Musical',
    'Estrofa_Arreglo',
    'Pista_Audio',
    'Historial_Reproduccion',
    'Configuracion',
  ];

  /// Exporta todos los datos de usuario desde [db] a un Map.
  ///
  /// Retorna un mapa donde las claves son nombres de tabla y los valores
  /// son listas de filas (cada fila es un Map<String, dynamic>).
  static Future<Map<String, List<Map<String, dynamic>>>> exportUserData(
    Database db,
  ) async {
    final data = <String, List<Map<String, dynamic>>>{};
    for (final table in _userTables) {
      try {
        final rows = await db.query(table);
        data[table] = rows;
      } catch (_) {
        // Si la tabla no existe (BD antigua), se omite silenciosamente
        data[table] = [];
      }
    }
    return data;
  }

  /// Importa datos de usuario en [db] desde [data].
  ///
  /// Usa INSERT OR IGNORE para evitar conflictos con datos nuevos del asset.
  /// Para tablas con id AUTOINCREMENT, se omite el campo 'id' en el INSERT
  /// para permitir que SQLite re-asigne valores si hubiera conflicto.
  static Future<void> importUserData(
    Database db,
    Map<String, List<Map<String, dynamic>>> data,
  ) async {
    // Orden de importación: padres antes que hijos
    final importOrder = [
      'Usuario',
      'Fondo_Pantalla',
      'Arreglo_Musical',
      'Estrofa_Arreglo',
      'Pista_Audio',
      'Historial_Reproduccion',
      'Configuracion',
    ];

    // Tablas cuyo 'id' es AUTOINCREMENT → omitir 'id' en INSERT
    const tablesWithAutoId = {
      'Usuario',
      'Fondo_Pantalla',
      'Arreglo_Musical',
      'Estrofa_Arreglo',
      'Pista_Audio',
      'Historial_Reproduccion',
    };

    // Tablas sin AUTOINCREMENT (clave primaria no es id autoincrement)
    const tablesWithoutAutoId = {
      'Configuracion', // clave TEXT PRIMARY KEY
    };

    for (final table in importOrder) {
      final rows = data[table];
      if (rows == null || rows.isEmpty) continue;

      for (final row in rows) {
        Map<String, dynamic> values;
        if (tablesWithAutoId.contains(table)) {
          // Omitir 'id' para permitir re-asignación por SQLite
          values = Map<String, dynamic>.from(row);
          values.remove('id');
        } else if (tablesWithoutAutoId.contains(table)) {
          values = Map<String, dynamic>.from(row);
        } else {
          values = Map<String, dynamic>.from(row);
        }

        try {
          await db.insert(
            table,
            values,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } catch (_) {
          // Ignorar fallos de inserción individual (ej: FK constraints
          // que no se cumplen en la nueva BD)
        }
      }
    }
  }
}
