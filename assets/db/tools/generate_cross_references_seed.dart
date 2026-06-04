// =============================================================================
// generate_cross_references_seed.dart
// =============================================================================
// Generador de SQL de seed para la tabla `cross_referencia` de biblia.db.
//
// FUENTE DE DATOS
// ===============
// Dataset: openbible.info/labs/cross-references/ (~340 000 referencias)
// Vía:     scrollmapper/bible_databases (https://github.com/scrollmapper/bible_databases)
// Archivo: sources/extras/cross_references.txt  (8.3 MB, formato TSV)
//
// Formato por línea (separador = TAB):
//   From Verse \t To Verse \t Votes
// Ej:
//   Gen.1.1          Gen.1.2              1
//   John.3.16        Gen.22.12            1
//   1John.4.9        1John.4.9-10         3
//
// En "From" siempre es un versículo único.
// En "To" puede ser versículo único ("Gen.1.2") o rango ("1John.4.9-10").
//
// LICENCIAS
//   * Datos:  CC-BY 4.0  (requiere atribución al usar el dataset)
//   * Código: MIT
//
// USO
// ===
//   # Una vez: descargar cross_references.txt y guardarlo en
//   #   assets/db/tools/source/scrollmapper/cross_references.txt
//   # (no trackeado en git por tamaño: ~8.3 MB).
//
//   cd /home/melquisedec/Escritorio/Projects/Personales/MQ-App
//   dart run assets/db/tools/generate_cross_references_seed.dart
//
//   # Flags:
//   #   --input  <ruta>   ruta al .txt de openbible (default: source/scrollmapper/cross_references.txt)
//   #   --output <ruta>   ruta del .sql de salida (default: assets/db/seed_cross_referencias_rv1909.sql)
//   #   --version-id <n>  version_id a insertar (default: 1 = RV1909)
//   #   --batch-size <n>  filas por BEGIN/COMMIT (default: 1000)
//
// SALIDA
// ======
// Genera un archivo SQL con INSERTs en transacciones de --batch-size filas.
// Aplica `DELETE FROM cross_referencia WHERE version_id = ?` antes de insertar
// (idempotente: re-ejecutable sin duplicar refs).
//
// DECISIONES
// ==========
//   * Líneas con bookAbbr desconocido (libro apócrifo/typo) → SKIP silencioso.
//     openbible incluye refs a deuterocanónicos que MQ-App no soporta.
//   * Líneas con to_versiculo_fin < to_versiculo_inicio (error de parseo)
//     → SKIP silencioso (defensa contra datos corruptos).
//   * Líneas vacías o con menos de 3 campos → SKIP silencioso.
//   * Reporta al final: líneas leídas, refs insertadas, refs saltadas,
//     top 10 libros con más refs omitidas (debug).
// =============================================================================

import 'dart:io';

import 'package:mqapp/dev/cross_refs_parser.dart';

// Re-exports para no romper código que importaba el parser desde el script.
export 'package:mqapp/dev/cross_refs_parser.dart';

// =============================================================================
// CLI
// =============================================================================

class CliOptions {
  String inputPath;
  String outputPath;
  int versionId;
  int batchSize;
  CliOptions({
    required this.inputPath,
    required this.outputPath,
    required this.versionId,
    required this.batchSize,
  });
}

String pJoin(String a, String b) {
  if (a.endsWith('/') || a.endsWith(r'\')) return '$a$b';
  return '$a${Platform.pathSeparator}$b';
}

String pAbs(String p, String root) {
  if (p.startsWith('/') || p.contains(':')) return p;
  return pJoin(root, p);
}

String findProjectRoot() {
  var dir = Directory.current;
  while (!File(pJoin(dir.path, 'pubspec.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw Exception('No se encontró pubspec.yaml; ejecuta desde el root del proyecto.');
    }
    dir = parent;
  }
  return dir.path;
}

CliOptions parseArgs(List<String> args, String projectRoot) {
  String inputPath = pJoin(
    projectRoot,
    'assets/db/tools/source/scrollmapper/cross_references.txt',
  );
  String outputPath = pJoin(
    projectRoot,
    'assets/db/seed_cross_referencias_rv1909.sql',
  );
  int versionId = 1;
  int batchSize = 1000;

  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    String? next() {
      if (i + 1 >= args.length) {
        stderr.writeln('ERROR: falta valor para $a');
        exit(2);
      }
      return args[++i];
    }

    switch (a) {
      case '--input':
        inputPath = pAbs(next()!, projectRoot);
        break;
      case '--output':
        outputPath = pAbs(next()!, projectRoot);
        break;
      case '--version-id':
        versionId = int.parse(next()!);
        break;
      case '--batch-size':
        batchSize = int.parse(next()!);
        if (batchSize < 1) {
          stderr.writeln('ERROR: --batch-size debe ser >= 1');
          exit(2);
        }
        break;
      case '-h':
      case '--help':
        printUsage();
        exit(0);
      default:
        stderr.writeln('ERROR: argumento desconocido: $a');
        printUsage();
        exit(2);
    }
  }
  return CliOptions(
    inputPath: inputPath,
    outputPath: outputPath,
    versionId: versionId,
    batchSize: batchSize,
  );
}

void printUsage() {
  stdout.writeln('Uso: dart run assets/db/tools/generate_cross_references_seed.dart [opciones]');
  stdout.writeln('Opciones:');
  stdout.writeln('  --input <ruta>       ruta al cross_references.txt de openbible');
  stdout.writeln('  --output <ruta>      ruta del .sql de salida');
  stdout.writeln('  --version-id <n>     version_id a usar (default: 1)');
  stdout.writeln('  --batch-size <n>     filas por BEGIN/COMMIT (default: 1000)');
}

// =============================================================================
// Main pipeline
// =============================================================================

Future<int> main(List<String> args) async {
  final projectRoot = findProjectRoot();
  final opts = parseArgs(args, projectRoot);

  stdout.writeln('╔════════════════════════════════════════════════════════════════╗');
  stdout.writeln('║  generate_cross_references_seed.dart — openbible → SQL        ║');
  stdout.writeln('╚════════════════════════════════════════════════════════════════╝');
  stdout.writeln('');
  stdout.writeln('📂 Rutas:');
  stdout.writeln('   Input  : ${opts.inputPath}');
  stdout.writeln('   Output : ${opts.outputPath}');
  stdout.writeln('   version_id: ${opts.versionId}');
  stdout.writeln('   batch_size: ${opts.batchSize}');

  if (!File(opts.inputPath).existsSync()) {
    stderr.writeln('');
    stderr.writeln('❌ No existe el archivo de entrada: ${opts.inputPath}');
    stderr.writeln('');
    stderr.writeln('Para obtenerlo:');
    stderr.writeln('  curl -L -o ${opts.inputPath} \\');
    stderr.writeln('    https://raw.githubusercontent.com/scrollmapper/bible_databases/master/sources/extras/cross_references.txt');
    return 1;
  }

  final inputSize = File(opts.inputPath).lengthSync();
  stdout.writeln('   Input  size: ${(inputSize / 1024 / 1024).toStringAsFixed(2)} MB');
  stdout.writeln('');

  // ── Parsear ──
  final swParse = Stopwatch()..start();
  final lines = File(opts.inputPath).readAsLinesSync();
  int totalLines = 0;
  int totalInserted = 0;
  int totalSkipped = 0;
  final skippedAbbrs = <String, int>{};
  final batch = <ParsedRef>[];

  for (final line in lines) {
    if (line.isEmpty) continue;
    totalLines++;
    final fields = line.split('\t');
    if (fields.length < 3) {
      totalSkipped++;
      continue;
    }
    final ref = parseRefLine(fields[0], fields[1], fields[2]);
    if (ref == null) {
      totalSkipped++;
      // Track por qué se skipeó (heurística: si el primer campo tiene
      // un bookAbbr desconocido, lo apuntamos).
      final firstDot = fields[0].indexOf('.');
      if (firstDot > 0) {
        final abbr = fields[0].substring(0, firstDot);
        if (lookupScrollmapperBookId(abbr) == null) {
          skippedAbbrs[abbr] = (skippedAbbrs[abbr] ?? 0) + 1;
        }
      }
      continue;
    }
    batch.add(ref);
  }
  swParse.stop();
  totalInserted = batch.length;
  stdout.writeln('   ✓ Líneas leídas: $totalLines');
  stdout.writeln('   ✓ Refs válidas : $totalInserted');
  stdout.writeln('   ⚠ Skipped       : $totalSkipped');
  if (skippedAbbrs.isNotEmpty) {
    final sorted = skippedAbbrs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    stdout.writeln('   Top abreviaturas skipeadas (probable apócrifo):');
    for (final e in sorted.take(10)) {
      stdout.writeln('     • ${e.key.padRight(8)} × ${e.value}');
    }
  }
  stdout.writeln('   ⏱ Parse: ${swParse.elapsedMilliseconds}ms');
  stdout.writeln('');

  // ── Escribir SQL ──
  final swWrite = Stopwatch()..start();
  final outFile = File(opts.outputPath);
  if (outFile.existsSync()) outFile.deleteSync();
  final outDir = Directory(outFile.parent.path);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final sink = outFile.openWrite();

  void writeHeader() {
    sink.writeln('-- =============================================================================');
    sink.writeln('-- Seed de cross_referencia (generado por generate_cross_references_seed.dart)');
    sink.writeln('-- =============================================================================');
    sink.writeln('-- Fuente  : openbible.info/labs/cross-references/ (CC-BY 4.0)');
    sink.writeln('-- Vía      : scrollmapper/bible_databases (MIT)');
    sink.writeln('-- Refs     : $totalInserted (de $totalLines líneas, $totalSkipped skipped)');
    sink.writeln('-- version_id: ${opts.versionId}');
    sink.writeln('--');
    sink.writeln('-- Atribución: Cross-references from openbible.info (CC-BY 4.0).');
    sink.writeln('-- =============================================================================');
    sink.writeln('');
    sink.writeln('PRAGMA foreign_keys = ON;');
    sink.writeln('PRAGMA synchronous = NORMAL;');
    sink.writeln('');
    sink.writeln('-- Limpiar refs existentes de esta versión (idempotente)');
    sink.writeln('DELETE FROM cross_referencia WHERE version_id = ${opts.versionId};');
    sink.writeln('');
  }

  void writeBatch(List<ParsedRef> rows) {
    if (rows.isEmpty) return;
    sink.writeln('BEGIN TRANSACTION;');
    sink.writeln('INSERT INTO cross_referencia');
    sink.writeln('  (version_id, from_libro_id, from_capitulo, from_versiculo,');
    sink.writeln('   to_libro_id, to_capitulo, to_versiculo_inicio, to_versiculo_fin, votos)');
    sink.writeln('VALUES');
    final buf = StringBuffer();
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      buf.write('  (${opts.versionId}, '
          '${r.fromLibroId}, ${r.fromCapitulo}, ${r.fromVersiculo}, '
          '${r.toLibroId}, ${r.toCapitulo}, '
          '${r.toVersiculoInicio}, ${r.toVersiculoFin}, '
          '${r.votos})');
      if (i < rows.length - 1) {
        buf.writeln(',');
      } else {
        buf.writeln(';');
      }
    }
    sink.write(buf.toString());
    sink.writeln('COMMIT;');
    sink.writeln('');
  }

  writeHeader();
  for (int i = 0; i < batch.length; i += opts.batchSize) {
    final end = (i + opts.batchSize < batch.length)
        ? i + opts.batchSize
        : batch.length;
    writeBatch(batch.sublist(i, end));
  }

  await sink.flush();
  await sink.close();
  swWrite.stop();

  final outSize = outFile.lengthSync();
  stdout.writeln('✅ Seed SQL escrito: ${opts.outputPath}');
  stdout.writeln('   Tamaño: ${(outSize / 1024 / 1024).toStringAsFixed(2)} MB');
  stdout.writeln('   ⏱ Write: ${swWrite.elapsedMilliseconds}ms');
  stdout.writeln('');
  stdout.writeln('🎉 Generador terminado. Para aplicarlo:');
  stdout.writeln('   dart run assets/db/tools/build_biblia_db.dart --cross-refs ${opts.outputPath}');

  return 0;
}
