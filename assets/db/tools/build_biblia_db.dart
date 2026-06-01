// =============================================================================
// build_biblia_db.dart
// =============================================================================
// STUB para FASE 2.
//
// Este script Dart generará el archivo `biblia.db` (~10-15 MB) combinando:
//   * El esquema de 001_biblia_schema.sql
//   * Los versículos de RV1909 (repo: iglesia-nazaret)
//   * Los versículos de RV1569 (Wikisource: Biblia del Oso)
//
// Uso planificado (Fase 2):
//   $ dart run assets/db/tools/build_biblia_db.dart \
//         --rv1909  ./tmp/rv1909.sql \
//         --rv1569  ./tmp/rv1569.txt \
//         --out     assets/db/biblia.db
//
// El archivo `biblia.db` resultante se marcará como asset de Flutter en
// `pubspec.yaml` (responsabilidad de @dev) y se copiará al almacenamiento
// del usuario en el primer arranque usando el patrón `copyIfNeededAndOpen`
// de @curie (ver lib/core/database/database_helper.dart).
// =============================================================================

import 'dart:io';

Future<void> main(List<String> args) async {
  // TODO(Fase 2): Implementar pipeline completo. Por ahora solo valida args
  // y deja un mensaje claro al desarrollador.

  stdout.writeln('╔════════════════════════════════════════════════════════╗');
  stdout.writeln('║  build_biblia_db.dart  —  STUB (Fase 2)               ║');
  stdout.writeln('╚════════════════════════════════════════════════════════╝');
  stdout.writeln('');
  stdout.writeln('Este script aún NO está implementado. Plan de Fase 2:');
  stdout.writeln('  1. Parsear args: --rv1909 <sql>  --rv1569 <txt>  --out <db>');
  stdout.writeln('  2. Crear DB vacía y aplicar 001_biblia_schema.sql');
  stdout.writeln('  3. Aplicar 002_biblia_seed_rv1909_stub.sql');
  stdout.writeln('  4. Aplicar 003_biblia_seed_rv1569_stub.sql');
  stdout.writeln('  5. INSERTAR versículos desde fuentes upstream');
  stdout.writeln('     (transacciones de 5 000 filas para evitar memory bloat)');
  stdout.writeln('  6. VACUUM + ANALYZE para compactar índices FTS5');
  stdout.writeln('  7. Reportar tamaño final y CRC32 para integrity check.');
  stdout.writeln('');
  stdout.writeln('Args recibidos: ${args.length} → $args');
  exit(0);
}
