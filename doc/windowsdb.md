# 🤖 Prompt de Refactorización: Forzar Actualización de SQLite desde Assets

## 🎯 Objetivo
Modificar la función de inicialización de la base de datos SQLite para que sea capaz de detectar cuándo el archivo `.db` alojado en los `assets/` es más reciente que el archivo local del usuario, forzando una copia y sobrescritura de manera controlada.

## 🛠️ Contexto del Problema
Actualmente, la lógica de `databaseExists(path)` bloquea la copia del nuevo archivo de la base de datos empaquetada si ya existe un archivo anterior en el disco, lo que impide ver los cambios estructurales o de datos (Himnos/Biblia) inyectados en la nueva build portable de Windows.

## 📋 Instrucciones de Implementación

**Paso 1: Implementar un Sistema de Versionado de Assets**
Necesitamos usar `shared_preferences` para guardar qué versión de la base de datos base tiene instalada el usuario.

**Paso 2: Reescribir el inicializador de la BD**
Localiza tu archivo donde inicializas SQLite (usualmente `database_helper.dart` o similar) y reemplaza la lógica de copiado por este patrón estructural:

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  // 🔴 IMPORTANTE: Incrementa este número a 2, 3, 4... 
  // cada vez que modifiques el archivo .db en tu carpeta de assets.
  static const int _currentAssetDbVersion = 1; 

  static Future<Database> initDb() async {
    // Para Windows Portable, usamos el directorio del ejecutable
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final dbPath = join(exeDir, 'data', 'himnario_biblia.db'); // Ajusta tu nombre de db

    final prefs = await SharedPreferences.getInstance();
    final savedDbVersion = prefs.getInt('db_version') ?? 0;

    final dbFile = File(dbPath);
    final exists = await dbFile.exists();

    // 💡 LÓGICA CLAVE: Si no existe, O si cambiamos el _currentAssetDbVersion
    if (!exists || savedDbVersion < _currentAssetDbVersion) {
      print('Sincronizando nueva base de datos desde assets...');
      
      // Asegurarse de que el directorio /data/ exista
      await Directory(dirname(dbPath)).create(recursive: true);
      
      // Extraer de los assets y sobrescribir
      ByteData data = await rootBundle.load('assets/db/tu_base_de_datos.db'); // Ajusta tu ruta
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await dbFile.writeAsBytes(bytes, flush: true);
      
      // Guardar la nueva versión en caché
      await prefs.setInt('db_version', _currentAssetDbVersion);
    } else {
      print('La base de datos local ya está en la última versión.');
    }

    // Retornar la conexión a la base de datos
    return await databaseFactoryFfi.openDatabase(dbPath);
  }
}