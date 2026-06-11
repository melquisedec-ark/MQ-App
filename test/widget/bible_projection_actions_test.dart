import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mqapp/core/window_manager/window_service.dart';
import 'package:mqapp/features/biblia/data/models/capitulo.dart';
import 'package:mqapp/features/biblia/data/models/libro.dart';
import 'package:mqapp/features/biblia/data/models/versiculo.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/presentation/views_projection/providers/projection_actions.dart';
import 'package:mqapp/core/window_manager/window_providers.dart';

// ═══════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════

class MockBibliaRepository extends Mock implements BibliaRepository {}

class MockWindowService extends Mock implements WindowService {}

// ═══════════════════════════════════════════════════════════════
// Widget que ejecuta projectBibleChapter al montarse (para tests)
// ═══════════════════════════════════════════════════════════════

class _ProjectBibleLauncher extends ConsumerStatefulWidget {
  final int versionId;
  final int libroId;
  final int capitulo;
  final void Function(String?) onResult;

  const _ProjectBibleLauncher({
    required this.versionId,
    required this.libroId,
    required this.capitulo,
    required this.onResult,
  });

  @override
  ConsumerState<_ProjectBibleLauncher> createState() =>
      _ProjectBibleLauncherState();
}

class _ProjectBibleLauncherState extends ConsumerState<_ProjectBibleLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await projectBibleChapter(
        ref,
        versionId: widget.versionId,
        libroId: widget.libroId,
        capitulo: widget.capitulo,
      );
      widget.onResult(result);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ═══════════════════════════════════════════════════════════════
// Test suite
// ═══════════════════════════════════════════════════════════════

void main() {
  late MockBibliaRepository mockRepo;
  late MockWindowService mockWindowService;

  setUp(() {
    mockRepo = MockBibliaRepository();
    mockWindowService = MockWindowService();

    registerFallbackValue(<String, dynamic>{});
  });

  group('projectBibleChapter', () {
    testWidgets('envía LOAD_VERSE con datos correctos en éxito',
        (tester) async {
      const libro = Libro(
        id: 1,
        versionId: 1,
        nombre: 'Génesis',
        abreviatura: 'Gn',
        testamento: Testamento.at,
        numero: 1,
        totalCapitulos: 50,
      );
      const cap = Capitulo(id: 100, libroId: 1, numero: 1, totalVersiculos: 31);
      final versiculos = [
        const Versiculo(id: 1, capituloId: 100, numero: 1, texto: 'En el principio...'),
        const Versiculo(id: 2, capituloId: 100, numero: 2, texto: 'Y la tierra...'),
      ];

      when(() => mockRepo.getLibroById(1)).thenAnswer((_) async => libro);
      when(() => mockRepo.getCapitulo(1, 1)).thenAnswer((_) async => cap);
      when(() => mockRepo.getVersiculosByCapitulo(100))
          .thenAnswer((_) async => versiculos);
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((_) async {});

      final sentMessages = <Map<String, dynamic>>[];
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((invocation) async {
        final msg = invocation.positionalArguments[0] as Map<String, dynamic>;
        sentMessages.add(msg);
      });

      String? capturedResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibliaRepositoryProvider.overrideWithValue(mockRepo),
            windowServiceProvider.overrideWithValue(mockWindowService),
          ],
          child: MaterialApp(
            home: _ProjectBibleLauncher(
              versionId: 1,
              libroId: 1,
              capitulo: 1,
              onResult: (r) => capturedResult = r,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedResult, isNull);
      expect(sentMessages.isNotEmpty, isTrue);

      // LOAD_VERSE debe ser el primer mensaje
      final loadVerse = sentMessages.firstWhere(
        (m) => m['type'] == 'LOAD_VERSE',
        orElse: () => <String, dynamic>{},
      );
      expect(loadVerse['type'], 'LOAD_VERSE');
      expect(loadVerse['libroNombre'], 'Génesis');
      expect(loadVerse['capitulo'], 1);
      expect(loadVerse['versiculos'], isA<List>());
      expect(loadVerse['versiculos'].length, 2);
      expect(loadVerse['versiculos'][0], 'En el principio...');
    });

    testWidgets('envía SET_BIBLE_THEME y SET_BIBLE_FONT_SIZE',
        (tester) async {
      const libro = Libro(
        id: 1, versionId: 1, nombre: 'Juan',
        abreviatura: 'Jn', testamento: Testamento.nt,
        numero: 43, totalCapitulos: 21,
      );
      const cap = Capitulo(id: 200, libroId: 1, numero: 3, totalVersiculos: 21);
      final versiculos = [
        const Versiculo(id: 10, capituloId: 200, numero: 16, texto: 'Porque de tal manera...'),
      ];

      when(() => mockRepo.getLibroById(1)).thenAnswer((_) async => libro);
      when(() => mockRepo.getCapitulo(1, 3)).thenAnswer((_) async => cap);
      when(() => mockRepo.getVersiculosByCapitulo(200))
          .thenAnswer((_) async => versiculos);
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((_) async {});

      final sentMessages = <Map<String, dynamic>>[];
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((invocation) async {
        final msg = invocation.positionalArguments[0] as Map<String, dynamic>;
        sentMessages.add(msg);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibliaRepositoryProvider.overrideWithValue(mockRepo),
            windowServiceProvider.overrideWithValue(mockWindowService),
          ],
          child: MaterialApp(
            home: _ProjectBibleLauncher(
              versionId: 1, libroId: 1, capitulo: 3,
              onResult: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que se envían los mensajes de apariencia bíblica
      final themeMsg = sentMessages.firstWhere(
        (m) => m['type'] == 'SET_BIBLE_THEME',
        orElse: () => <String, dynamic>{},
      );
      expect(themeMsg['type'], 'SET_BIBLE_THEME');
      expect(themeMsg['theme'], 'papel'); // valor por defecto

      final fontSizeMsg = sentMessages.firstWhere(
        (m) => m['type'] == 'SET_BIBLE_FONT_SIZE',
        orElse: () => <String, dynamic>{},
      );
      expect(fontSizeMsg['type'], 'SET_BIBLE_FONT_SIZE');
      expect(fontSizeMsg['scale'], 1.0); // valor por defecto
    });

    testWidgets('retorna error cuando libro no existe', (tester) async {
      when(() => mockRepo.getLibroById(999)).thenAnswer((_) async => null);
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((_) async {});

      String? capturedResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibliaRepositoryProvider.overrideWithValue(mockRepo),
            windowServiceProvider.overrideWithValue(mockWindowService),
          ],
          child: MaterialApp(
            home: _ProjectBibleLauncher(
              versionId: 1, libroId: 999, capitulo: 1,
              onResult: (r) => capturedResult = r,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedResult, 'Libro no encontrado');
    });

    testWidgets('retorna error cuando capítulo no existe', (tester) async {
      const libro = Libro(
        id: 1, versionId: 1, nombre: 'Génesis',
        abreviatura: 'Gn', testamento: Testamento.at,
        numero: 1, totalCapitulos: 50,
      );

      when(() => mockRepo.getLibroById(1)).thenAnswer((_) async => libro);
      when(() => mockRepo.getCapitulo(1, 99)).thenAnswer((_) async => null);
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((_) async {});

      String? capturedResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibliaRepositoryProvider.overrideWithValue(mockRepo),
            windowServiceProvider.overrideWithValue(mockWindowService),
          ],
          child: MaterialApp(
            home: _ProjectBibleLauncher(
              versionId: 1, libroId: 1, capitulo: 99,
              onResult: (r) => capturedResult = r,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedResult, 'Capítulo no encontrado');
    });

    testWidgets('retorna error cuando no hay versículos', (tester) async {
      const libro = Libro(
        id: 1, versionId: 1, nombre: 'Génesis',
        abreviatura: 'Gn', testamento: Testamento.at,
        numero: 1, totalCapitulos: 50,
      );
      const cap = Capitulo(id: 300, libroId: 1, numero: 1, totalVersiculos: 0);

      when(() => mockRepo.getLibroById(1)).thenAnswer((_) async => libro);
      when(() => mockRepo.getCapitulo(1, 1)).thenAnswer((_) async => cap);
      when(() => mockRepo.getVersiculosByCapitulo(300))
          .thenAnswer((_) async => []);
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((_) async {});

      String? capturedResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibliaRepositoryProvider.overrideWithValue(mockRepo),
            windowServiceProvider.overrideWithValue(mockWindowService),
          ],
          child: MaterialApp(
            home: _ProjectBibleLauncher(
              versionId: 1, libroId: 1, capitulo: 1,
              onResult: (r) => capturedResult = r,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedResult, 'Sin versículos');
    });

    testWidgets('retorna error cuando repo lanza excepción', (tester) async {
      when(() => mockRepo.getLibroById(1))
          .thenThrow(Exception('DB connection failed'));
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((_) async {});

      String? capturedResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bibliaRepositoryProvider.overrideWithValue(mockRepo),
            windowServiceProvider.overrideWithValue(mockWindowService),
          ],
          child: MaterialApp(
            home: _ProjectBibleLauncher(
              versionId: 1, libroId: 1, capitulo: 1,
              onResult: (r) => capturedResult = r,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedResult, isNotNull);
      expect(capturedResult, contains('DB connection failed'));
    });
  });
}
