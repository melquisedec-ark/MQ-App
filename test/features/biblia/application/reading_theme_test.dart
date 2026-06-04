import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/bible_appearance_provider.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_config_provider.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_config_repository.dart';

import '../helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  group('ReadingTheme enum', () {
    test('tiene exactamente 5 temas', () {
      expect(ReadingTheme.values.length, 5);
    });

    test('fromId retorna el tema correcto', () {
      expect(ReadingTheme.fromId('papel'), ReadingTheme.papel);
      expect(ReadingTheme.fromId('sepia'), ReadingTheme.sepia);
      expect(ReadingTheme.fromId('noche'), ReadingTheme.noche);
      expect(ReadingTheme.fromId('azulNoche'), ReadingTheme.azulNoche);
      expect(ReadingTheme.fromId('altoContraste'), ReadingTheme.altoContraste);
    });

    test('fromId retorna null para ID inválido', () {
      expect(ReadingTheme.fromId('invalido'), isNull);
    });

    test('fromOldColorName mapea colores antiguos correctamente', () {
      expect(
        ReadingTheme.fromOldColorName('negro'),
        ReadingTheme.altoContraste,
      );
      expect(ReadingTheme.fromOldColorName('sepia'), ReadingTheme.sepia);
      expect(
        ReadingTheme.fromOldColorName('azul'),
        ReadingTheme.azulNoche,
      );
      expect(ReadingTheme.fromOldColorName('blanco'), ReadingTheme.papel);
    });

    test('cada tema tiene backgroundColor y textColor definidos', () {
      for (final theme in ReadingTheme.values) {
        expect(theme.backgroundColor, isNotNull);
        expect(theme.textColor, isNotNull);
        expect(theme.id, isNotEmpty);
        expect(theme.label, isNotEmpty);
      }
    });
  });

  group('BibleAppearanceState', () {
    test('default state tiene themeId=papel', () {
      const state = BibleAppearanceState();
      expect(state.themeId, 'papel');
    });

    test('copyWith preserva campos no modificados', () {
      const state = BibleAppearanceState(
        fontScale: 1.2,
        fontFamily: 'serif',
        themeId: 'noche',
      );
      final copy = state.copyWith(fontScale: 1.3);
      expect(copy.fontScale, 1.3);
      expect(copy.fontFamily, 'serif');
      expect(copy.themeId, 'noche');
    });

    test('copyWith actualiza backgroundColor y textColor con tema', () {
      const state = BibleAppearanceState();
      final copy = state.copyWith(
        backgroundColor: ReadingTheme.sepia.backgroundColor,
        textColor: ReadingTheme.sepia.textColor,
        themeId: 'sepia',
      );
      expect(copy.backgroundColor, ReadingTheme.sepia.backgroundColor);
      expect(copy.textColor, ReadingTheme.sepia.textColor);
      expect(copy.themeId, 'sepia');
    });
  });

  group('BibleAppearanceNotifier theme persistence', () {
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

    test('setTheme persiste themeId en BD', () async {
      final container = ProviderContainer(
        overrides: [bibliaConfigRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container
          .read(bibleAppearanceProvider.notifier)
          .setTheme(ReadingTheme.noche);

      expect(
        container.read(bibleAppearanceProvider).themeId,
        'noche',
      );
      expect(
        container.read(bibleAppearanceProvider).backgroundColor,
        ReadingTheme.noche.backgroundColor,
      );
      expect(
        container.read(bibleAppearanceProvider).textColor,
        ReadingTheme.noche.textColor,
      );

      // Esperar persistencia async en BD.
      await Future.delayed(const Duration(milliseconds: 100));

      // Verificar persistencia en BD.
      final stored = await repo.get(BibliaConfigKeys.bibliaReadingTheme);
      expect(stored, 'noche');
    });

    test('hidrata tema desde BD al instanciar', () async {
      // Sembrar tema antes de instanciar.
      await repo.set(BibliaConfigKeys.bibliaReadingTheme, 'noche');

      final container = ProviderContainer(
        overrides: [bibliaConfigRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      // Esperar a que el load async termine usando listener.
      final completer = Completer<void>();
      container.listen<BibleAppearanceState>(
        bibleAppearanceProvider,
        (prev, next) {
          if (next.themeId == 'noche' && !completer.isCompleted) {
            completer.complete();
          }
        },
      );
      // Forzar lectura inicial.
      container.read(bibleAppearanceProvider);

      // Timeout de seguridad.
      Future.delayed(const Duration(seconds: 2), () {
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;

      expect(
        container.read(bibleAppearanceProvider).themeId,
        'noche',
      );
    });
  });

  group('BibliaConfigKeys', () {
    test('bibliaReadingTheme key existe', () {
      expect(
        BibliaConfigKeys.bibliaReadingTheme,
        'biblia.reading_theme',
      );
    });
  });
}
