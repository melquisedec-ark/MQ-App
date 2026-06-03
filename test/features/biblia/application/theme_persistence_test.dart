import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_config_provider.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_config_repository.dart';

import '../helpers/bible_db_test_helper.dart';

/// Espera hasta que [themeModeProvider] emita el [expected] valor.
///
/// Devuelve un [Completer] que completa cuando se observa el valor. Útil
/// para tests donde el notifier se hidrata asíncronamente desde BD.
Future<Completer<void>> _waitForHydration(
  ProviderContainer container,
  ThemeMode expected,
) async {
  final completer = Completer<void>();
  // Forzar lectura inicial.
  container.read(themeModeProvider);
  final sub = container.listen<ThemeMode>(
    themeModeProvider,
    (prev, next) {
      if (next == expected && !completer.isCompleted) {
        completer.complete();
      }
    },
  );
  // Timeout de seguridad para que el test no se cuelgue.
  Future.delayed(const Duration(seconds: 2), () {
    if (!completer.isCompleted) completer.complete();
  }).then((_) => sub.close());
  return completer;
}

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  group('ThemeModeNotifier persistence (B3/D2/D13)', () {
    late Database db;
    late BibliaConfigRepository repo;

    setUp(() async {
      final bundle = await createBibleReposWithSeed();
      db = bundle.db;
      repo = BibliaConfigRepository(BibleDatabaseHelper.forTesting(db));
    });

    tearDown(() async {
      await repo.dispose();
      await db.close();
    });

    test('default state es ThemeMode.system', () {
      final container = ProviderContainer(
        overrides: [bibliaConfigRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('setThemeMode(light) persiste en BD y refleja state', () async {
      final container = ProviderContainer(
        overrides: [bibliaConfigRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).setThemeMode(
            ThemeMode.light,
          );
      expect(container.read(themeModeProvider), ThemeMode.light);

      // Verificar persistencia leyendo directamente de la BD.
      final stored = await repo.get(BibliaConfigKeys.themeMode);
      expect(stored, 'light');
    });

    test('setThemeMode(dark) persiste en BD y refleja state', () async {
      final container = ProviderContainer(
        overrides: [bibliaConfigRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(themeModeProvider.notifier).setThemeMode(
            ThemeMode.dark,
          );
      expect(container.read(themeModeProvider), ThemeMode.dark);

      final stored = await repo.get(BibliaConfigKeys.themeMode);
      expect(stored, 'dark');
    });

    test('ThemeMode.cycle cicla light → dark → system → light', () {
      expect(ThemeMode.light.cycle, ThemeMode.dark);
      expect(ThemeMode.dark.cycle, ThemeMode.system);
      expect(ThemeMode.system.cycle, ThemeMode.light);
    });

    test('hidrata desde BD al instanciar el notifier', () async {
      // Sembrar valor antes de instanciar el provider.
      await repo.set(BibliaConfigKeys.themeMode, 'dark');

      final container = ProviderContainer(
        overrides: [bibliaConfigRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      // Esperar a que el load async termine. Usamos un listener que
      // resuelve cuando el state cambia del default.
      final completer = await _waitForHydration(container, ThemeMode.dark);
      await completer.future;
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
