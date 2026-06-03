import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_config_provider.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_config_repository.dart';
import 'package:mqapp/presentation/shared_widgets/theme_mode_toggle_button.dart';

import 'helpers/bible_db_test_helper.dart';

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  group('ThemeModeToggleButton (D3)', () {
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

    /// Harness mínimo: muestra el FAB en una pantalla y permite
    /// interceptar el `ConsumerWidget` vía `ProviderScope` overrides.
    Widget _harness({ThemeMode initial = ThemeMode.system}) {
      return ProviderScope(
        overrides: [
          bibliaConfigRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                // Sembrar initial en BD para que el notifier arranque con ese modo.
                if (initial != ThemeMode.system) {
                  // Ignorar — el default es system y los tests verifican
                  // transiciones, no la carga inicial.
                }
                return const Center(child: ThemeModeToggleButton());
              },
            ),
          ),
        ),
      );
    }

    testWidgets('tap cicla al siguiente modo (system → light)',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // El icono inicial es brightness_auto (system).
      expect(find.byIcon(Icons.brightness_auto), findsOneWidget);

      await tester.tap(find.byType(ThemeModeToggleButton));
      await tester.pumpAndSettle();

      // Ahora debe ser light_mode.
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('tap cicla: light → dark → system', (tester) async {
      // Sembrar BD con 'light' para que el notifier arranque ahí.
      await repo.set(BibliaConfigKeys.themeMode, 'light');
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.light_mode), findsOneWidget);

      // 1er tap: light → dark.
      await tester.tap(find.byType(ThemeModeToggleButton));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);

      // 2do tap: dark → system.
      await tester.tap(find.byType(ThemeModeToggleButton));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
    });

    testWidgets('long press abre BottomSheet con 3 RadioListTile',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // Hacer long press manual: pointer down + esperar + pointer up.
      final center = tester.getCenter(find.byType(ThemeModeToggleButton));
      final gesture = await tester.startGesture(center);
      // Esperar más que el kLongPressTimeout (500ms en tests).
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await tester.pumpAndSettle();

      // El BottomSheet debe estar visible.
      expect(find.text('Tema de la aplicación'), findsOneWidget);
      expect(find.text('Seguir dispositivo'), findsOneWidget);
      expect(find.text('Modo claro'), findsOneWidget);
      expect(find.text('Modo oscuro'), findsOneWidget);
    });

    testWidgets('long press → tap en RadioListTile cambia el modo',
        (tester) async {
      // Sembrar 'light' como inicio.
      await repo.set(BibliaConfigKeys.themeMode, 'light');
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // Long press manual para abrir el BottomSheet.
      final center = tester.getCenter(find.byType(ThemeModeToggleButton));
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await tester.pumpAndSettle();

      // El BottomSheet está abierto.
      expect(find.text('Tema de la aplicación'), findsOneWidget);

      // Tap en "Modo oscuro".
      await tester.tap(find.text('Modo oscuro'));
      await tester.pumpAndSettle();

      // El BottomSheet se cerró.
      expect(find.text('Tema de la aplicación'), findsNothing);

      // El icono del FAB ahora es dark_mode.
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });
  });
}
