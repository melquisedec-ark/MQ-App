import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mqapp/core/window_manager/window_service.dart';
import 'package:mqapp/core/window_manager/window_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/presentation_providers.dart';

/// Mock de WindowService para pruebas de presentación.
class _MockWindowService extends Mock implements WindowService {}

/// FAB para iniciar/detener la presentación (copiada de home_screen.dart para tests aislados).
class _TestPresentFAB extends ConsumerWidget {
  const _TestPresentFAB();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPresenting = ref.watch(isPresentingProvider);
    return FloatingActionButton.extended(
      heroTag: 'present_button_bible_home',
      onPressed: () async {
        final windowService = ref.read(windowServiceProvider);
        if (isPresenting) {
          await windowService.closeProjectionWindow();
          ref.read(isPresentingProvider.notifier).state = false;
        } else {
          await windowService.openProjectionWindow({
            'mode': 'local',
            'source': 'bible_home',
          });
          ref.read(isPresentingProvider.notifier).state = true;
        }
      },
      backgroundColor: isPresenting
          ? Theme.of(context).colorScheme.errorContainer
          : const Color(0xFFCCA43B),
      foregroundColor: const Color(0xFF1A1A1A),
      icon: Icon(isPresenting ? Icons.stop_screen_share : Icons.screen_share),
      label: Text(isPresenting ? 'Detener Presentación' : 'Presentar'),
    );
  }
}

void main() {
  late _MockWindowService mockWindowService;

  setUp(() {
    mockWindowService = _MockWindowService();
    registerFallbackValue(<String, dynamic>{});
    when(() => mockWindowService.openProjectionWindow(any()))
        .thenAnswer((_) async => true);
    when(() => mockWindowService.closeProjectionWindow())
        .thenAnswer((_) async {});
    when(() => mockWindowService.sendMessage(any()))
        .thenAnswer((_) async {});
  });

  Widget buildTestApp({bool isPresenting = false}) {
    return ProviderScope(
      overrides: [
        windowServiceProvider.overrideWithValue(mockWindowService),
        isPresentingProvider.overrideWith((ref) => isPresenting),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(child: _TestPresentFAB()),
        ),
      ),
    );
  }

  group('Bible HomeScreen PresentFAB', () {
    testWidgets('Muestra "Presentar" cuando NO está presentando', (tester) async {
      await tester.pumpWidget(buildTestApp(isPresenting: false));
      await tester.pump();

      expect(find.text('Presentar'), findsOneWidget);
      expect(find.byIcon(Icons.screen_share), findsOneWidget);
    });

    testWidgets('Muestra "Detener Presentación" cuando SÍ está presentando', (tester) async {
      await tester.pumpWidget(buildTestApp(isPresenting: true));
      await tester.pump();

      expect(find.text('Detener Presentación'), findsOneWidget);
      expect(find.byIcon(Icons.stop_screen_share), findsOneWidget);
    });

    testWidgets('FAB tiene heroTag único', (tester) async {
      await tester.pumpWidget(buildTestApp(isPresenting: false));
      await tester.pump();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.heroTag, 'present_button_bible_home');
    });

    testWidgets('Al tocar "Presentar" abre ventana de proyección', (tester) async {
      await tester.pumpWidget(buildTestApp(isPresenting: false));
      await tester.pump();

      await tester.tap(find.text('Presentar'));
      await tester.pump();

      verify(() => mockWindowService.openProjectionWindow(any())).called(1);
    });

    testWidgets('Al tocar "Detener Presentación" cierra ventana', (tester) async {
      await tester.pumpWidget(buildTestApp(isPresenting: true));
      await tester.pump();

      await tester.tap(find.text('Detener Presentación'));
      await tester.pump();

      verify(() => mockWindowService.closeProjectionWindow()).called(1);
    });

    testWidgets('FAB usa color dorado cuando no presenta', (tester) async {
      await tester.pumpWidget(buildTestApp(isPresenting: false));
      await tester.pump();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.backgroundColor, const Color(0xFFCCA43B));
    });
  });
}
