import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mqapp/core/window_manager/window_service.dart';
import 'package:mqapp/core/window_manager/window_providers.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_libro_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_versiculo_provider.dart';
import 'package:mqapp/features/biblia/data/models/capitulo.dart';
import 'package:mqapp/features/biblia/data/models/libro.dart';
import 'package:mqapp/features/biblia/data/models/versiculo.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/presentation/screens/bible_reader_screen.dart';
import 'package:mqapp/presentation/views_projection/providers/presentation_providers.dart';

/// Mock de WindowService.
class _MockWindowService extends Mock implements WindowService {}

/// Mock de BibliaRepository.
class _MockBibliaRepository extends Mock implements BibliaRepository {}

void main() {
  late _MockWindowService mockWindowService;
  late _MockBibliaRepository mockBibleRepo;

  setUp(() {
    mockWindowService = _MockWindowService();
    mockBibleRepo = _MockBibliaRepository();
    registerFallbackValue(<String, dynamic>{});
    when(() => mockWindowService.openProjectionWindow(any()))
        .thenAnswer((_) async => true);
    when(() => mockWindowService.closeProjectionWindow())
        .thenAnswer((_) async {});
    when(() => mockWindowService.sendMessage(any()))
        .thenAnswer((_) async {});
  });

  Widget _buildTestApp({
    bool isPresenting = false,
    int libroId = 1,
    int capitulo = 1,
    List<Override> overrides = const [],
  }) {
    final libro = Libro(
      id: libroId,
      versionId: 1,
      nombre: 'Génesis',
      abreviatura: 'Gn',
      testamento: Testamento.at,
      numero: 1,
      totalCapitulos: 50,
    );
    final cap = Capitulo(id: 100, libroId: libroId, numero: capitulo, totalVersiculos: 5);
    final versiculos = List.generate(
      5,
      (i) => Versiculo(id: i + 1, capituloId: 100, numero: i + 1, texto: 'Versículo ${i + 1}'),
    );

    when(() => mockBibleRepo.getLibroById(libroId)).thenAnswer((_) async => libro);
    when(() => mockBibleRepo.getCapitulo(libroId, capitulo)).thenAnswer((_) async => cap);
    when(() => mockBibleRepo.getVersiculosByCapitulo(100)).thenAnswer((_) async => versiculos);

    return ProviderScope(
      overrides: [
        windowServiceProvider.overrideWithValue(mockWindowService),
        bibliaRepositoryProvider.overrideWithValue(mockBibleRepo),
        isPresentingProvider.overrideWith((ref) => isPresenting),
        currentLibroIdProvider.overrideWith((ref) => libroId),
        currentCapituloProvider.overrideWith((ref) => capitulo),
        currentVersiculoNumeroProvider.overrideWith((ref) => 1),
        ...overrides,
      ],
      child: MaterialApp(
        home: BibleReaderScreen(libroId: libroId, capitulo: capitulo),
      ),
    );
  }

  group('BibleReaderScreen - Presentación', () {
    testWidgets(
      'Muestra botón Presentar (screen_share_outlined) en AppBar',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(isPresenting: false));
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.screen_share_outlined),
          findsOneWidget,
          reason: 'Botón Presentar debe estar en el AppBar',
        );
      },
    );

    testWidgets(
      'Muestra botón Detener (stop_screen_share) cuando está presentando',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(isPresenting: true));
        await tester.pumpAndSettle();

        expect(
          find.byIcon(Icons.stop_screen_share),
          findsOneWidget,
          reason: 'Botón Detener debe estar visible cuando se está presentando',
        );
      },
    );

    testWidgets(
      'Al tocar Presentar abre ventana de proyección',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(isPresenting: false));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.screen_share_outlined));
        await tester.pumpAndSettle();

        verify(
          () => mockWindowService.openProjectionWindow(any()),
        ).called(1);
      },
    );

    testWidgets(
      'Al tocar Detener cierra ventana de proyección',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(isPresenting: true));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.stop_screen_share));
        await tester.pumpAndSettle();

        verify(
          () => mockWindowService.closeProjectionWindow(),
        ).called(1);
      },
    );

    testWidgets(
      'Al iniciar presentación envía LOAD_VERSE al subproceso',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(isPresenting: false));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.screen_share_outlined));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));

        // Verificar que se envió LOAD_VERSE
        verify(
          () => mockWindowService.sendMessage(
            any(that: isA<Map<String, dynamic>>().having(
              (m) => m['type'],
              'type',
              'LOAD_VERSE',
            )),
          ),
        ).called(1);
      },
    );
  });
}
