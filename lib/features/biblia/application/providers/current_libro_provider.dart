import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ID de la versión bíblica actualmente seleccionada.
///
/// Default: 1 (RV1909 — primera versión insertada en
/// `002_biblia_seed_rv1909_stub.sql`).
///
/// En Fase 2a.2+ se persistirá en la tabla `config` con clave
/// `version_default` y se hidratará desde allí en el bootstrap de la app.
final currentVersionIdProvider = StateProvider<int>((ref) => 1);

/// ID del libro actualmente seleccionado. `null` = ninguno (home).
final currentLibroIdProvider = StateProvider<int?>((ref) => null);

/// Número del capítulo actualmente seleccionado. `null` = ninguno.
final currentCapituloProvider = StateProvider<int?>((ref) => null);
