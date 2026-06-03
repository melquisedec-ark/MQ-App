import 'dart:async';

import 'package:logging/logging.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/database/bible_database_helper.dart';

/// Repositorio para la tabla `config` de `biblia.db`.
///
/// Sigue el patrón key-value del schema (clave, valor, fecha_modificacion).
/// Los valores son strings — el caller parsea según su tipo.
///
/// ## Settings del módulo Biblia (Phase 2a.3)
///
/// | Clave                         | Tipo   | Default   |
/// |-------------------------------|--------|-----------|
/// | biblia.version_preferida      | String | RV1909    |
/// | emitter.view_mode_default     | String | compact   |
/// | ui.theme_mode                 | String | system    |
/// | biblia.auto_historial         | bool   | true      |
/// | biblia.nota_color_default     | String | ninguno   |
///
/// Se decidió centralizar en `biblia.db` (en vez de SharedPreferences)
/// para:
/// 1. Coherencia con `favorito_versiculo`, `nota`, `historial_versiculo`
///    (todas viven en la misma BD, mismo ciclo de backup).
/// 2. Sincronización cross-device vía backup (Fase futura).
class BibliaConfigRepository {
  static final _log = Logger('BibliaConfigRepository');

  final BibleDatabaseHelper _db;
  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  BibliaConfigRepository(this._db);

  Future<Database> get _database => _db.database;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Cierra el stream interno.
  Future<void> dispose() async {
    await _changes.close();
  }

  /// Devuelve el valor (string) de la clave, o [defaultValue] si no existe.
  ///
  /// Idempotente: no falla si la clave no existe.
  Future<String> get(String clave, {String defaultValue = ''}) async {
    final db = await _database;
    final rows = await db.query(
      'config',
      columns: ['valor'],
      where: 'clave = ?',
      whereArgs: [clave],
      limit: 1,
    );
    if (rows.isEmpty) return defaultValue;
    return rows.first['valor'] as String;
  }

  /// Devuelve el valor como bool. Acepta 'true' / '1' / 'yes' como true.
  /// Si no existe, devuelve [defaultValue].
  Future<bool> getBool(String clave, {required bool defaultValue}) async {
    final raw = await get(clave, defaultValue: defaultValue.toString());
    return _parseBool(raw, fallback: defaultValue);
  }

  /// Guarda un valor string. Sobrescribe si ya existe.
  Future<void> set(String clave, String valor) async {
    final db = await _database;
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    await db.insert(
      'config',
      {
        'clave': clave,
        'valor': valor,
        'fecha_modificacion': ts,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _log.fine('config[$clave] = $valor');
    _notify();
  }

  /// Guarda un bool como 'true' / 'false'.
  Future<void> setBool(String clave, bool value) async {
    await set(clave, value.toString());
  }

  /// Stream que se emite cada vez que alguna clave cambia.
  /// Los listeners deben re-leer la clave que les interesa.
  Stream<void> watch() => _changes.stream;

  /// Parsea un string como bool con fallback.
  /// Acepta: 'true', '1', 'yes', 'on' → true. Resto → false.
  static bool _parseBool(String raw, {required bool fallback}) {
    final lower = raw.toLowerCase().trim();
    if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on') {
      return true;
    }
    if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'off') {
      return false;
    }
    return fallback;
  }
}

/// Claves de configuración del módulo Biblia.
///
/// Centralizadas aquí para evitar typos y para que un IDE las autocomplete.
/// Mantener sincronizado con la tabla arriba.
abstract class BibliaConfigKeys {
  /// Versión bíblica preferida al abrir la app. Valores: "RV1909" | "RV1569".
  static const String versionPreferida = 'biblia.version_preferida';

  /// Modo de vista del emisor. Valores: "compact" | "preview".
  static const String emitterViewModeDefault = 'emitter.view_mode_default';

  /// Modo de tema. Valores: "light" | "dark" | "system".
  /// NOTA: también existe en `mqapp.db` (Configuracion tabla del himnario).
  /// Ambas se mantienen sincronizadas; `biblia.db` es la fuente de verdad
  /// para el módulo Biblia.
  static const String themeMode = 'ui.theme_mode';

  /// Si está activo, registrar historial al leer versículos.
  static const String autoHistorial = 'biblia.auto_historial';

  /// Color por defecto al crear una nota. Valores: "amarillo" | "verde"
  /// | "azul" | "ninguno".
  static const String notaColorDefault = 'biblia.nota_color_default';
}
