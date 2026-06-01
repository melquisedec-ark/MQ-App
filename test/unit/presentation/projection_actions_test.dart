import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/core/window_manager/window_service.dart';
import 'package:himnario_id_2/domain/entities/estrofa.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/domain/repositories/hymn_repository.dart';
import 'package:himnario_id_2/presentation/shared_widgets/providers/appearance_provider.dart';
import 'package:himnario_id_2/presentation/views_personal/providers/hymn_providers.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/projection_actions.dart';
import 'package:himnario_id_2/core/window_manager/window_providers.dart';

// ═══════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════

class MockHymnRepository extends Mock implements HymnRepository {}

class MockWindowService extends Mock implements WindowService {}

// ═══════════════════════════════════════════════════════════════
// Widget que ejecuta projectHymn al montarse (para tests)
// ═══════════════════════════════════════════════════════════════

class _ProjectHymnLauncher extends ConsumerStatefulWidget {
  final Himno himno;
  final void Function(String?) onResult;

  const _ProjectHymnLauncher({
    required this.himno,
    required this.onResult,
  });

  @override
  ConsumerState<_ProjectHymnLauncher> createState() =>
      _ProjectHymnLauncherState();
}

class _ProjectHymnLauncherState extends ConsumerState<_ProjectHymnLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await projectHymn(ref, widget.himno);
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
  late MockHymnRepository mockRepo;
  late MockWindowService mockWindowService;

  setUp(() {
    mockRepo = MockHymnRepository();
    mockWindowService = MockWindowService();

    registerFallbackValue(Himno(id: 1, titulo: '', tipo: HimnoTipo.oficial));
    registerFallbackValue(<Estrofa>[]);
    registerFallbackValue(<String, dynamic>{});
  });

  group('projectHymn', () {
    testWidgets('envía SET_CONFIG después de LOAD_HYMN', (tester) async {
      final himno = Himno(
        id: 1,
        titulo: 'Santo, Santo, Santo',
        numero: 1,
        tipo: HimnoTipo.oficial,
      );

      when(() => mockRepo.getHymnById(1)).thenAnswer((_) async => himno);
      when(() => mockRepo.getStanzas(any())).thenAnswer((_) async => []);
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((_) async {});

      final sentMessages = <Map<String, dynamic>>[];
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((invocation) async {
        final msg =
            invocation.positionalArguments[0] as Map<String, dynamic>;
        sentMessages.add(msg);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hymnRepositoryProvider.overrideWithValue(mockRepo),
            windowServiceProvider.overrideWithValue(mockWindowService),
          ],
          child: MaterialApp(
            home: _ProjectHymnLauncher(
              himno: himno,
              onResult: (_) {},
            ),
          ),
        ),
      );

      // Esperar a que el postFrameCallback se ejecute
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(sentMessages.length, 2);
      expect(sentMessages[0]['type'], 'LOAD_HYMN');
      expect(sentMessages[1]['type'], 'SET_CONFIG');
    });

    testWidgets('SET_CONFIG contiene todos los campos de apariencia',
        (tester) async {
      final himno = Himno(
        id: 2,
        titulo: 'Test',
        tipo: HimnoTipo.oficial,
      );

      when(() => mockRepo.getHymnById(2)).thenAnswer((_) async => himno);
      when(() => mockRepo.getStanzas(any())).thenAnswer((_) async => []);

      // Creamos una referencia al container para leer el appearance provider
      // antes de que se monte el widget (usamos el default, sin override)
      final container = ProviderContainer(
        overrides: [
          hymnRepositoryProvider.overrideWithValue(mockRepo),
          windowServiceProvider.overrideWithValue(mockWindowService),
        ],
      );
      addTearDown(() => container.dispose());

      // Modificar apariencia antes de proyectar
      final appearanceNotifier =
          container.read(hymnAppearanceProvider.notifier);
      appearanceNotifier.setTextColor(const Color(0xFFB3261E));
      appearanceNotifier.setChordColor(const Color(0xFF1A6B8A));
      appearanceNotifier.setFontFamily('Lora');
      appearanceNotifier.setIsBold(true);
      appearanceNotifier.setFontScale(1.3);
      appearanceNotifier.setBgColor(const Color(0xFF1D6F42));
      // Forzar una pump para que el notifier actualice su estado interno
      await tester.pump();

      Map<String, dynamic>? capturedSetConfig;
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((invocation) async {
        final msg =
            invocation.positionalArguments[0] as Map<String, dynamic>;
        if (msg['type'] == 'SET_CONFIG') capturedSetConfig = msg;
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: _ProjectHymnLauncher(
              himno: himno,
              onResult: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedSetConfig, isNotNull);
      expect(capturedSetConfig!['type'], 'SET_CONFIG');
      expect(capturedSetConfig!['textColor'], '#FFB3261E');
      expect(capturedSetConfig!['chordColor'], '#FF1A6B8A');
      expect(capturedSetConfig!['fontFamily'], 'Lora');
      expect(capturedSetConfig!['isBold'], true);
      expect(capturedSetConfig!['fontScale'], 1.3);
      expect(capturedSetConfig!['bgColor'], '#FF1D6F42');
      // Campos legacy
      expect(capturedSetConfig!['backgroundColor'], '#FF1D6F42');
      expect(capturedSetConfig!['fontSize'], 'large'); // 1.3 → large
      expect(capturedSetConfig!['transitionSpeed'], 0.5);
      expect(capturedSetConfig!['background'], 'color');
    });

    testWidgets('SET_CONFIG envía "black" cuando bgColor es transparente',
        (tester) async {
      final himno = Himno(
        id: 3,
        titulo: 'Test',
        tipo: HimnoTipo.oficial,
      );

      when(() => mockRepo.getHymnById(3)).thenAnswer((_) async => himno);
      when(() => mockRepo.getStanzas(any())).thenAnswer((_) async => []);
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((_) async {});

      Map<String, dynamic>? capturedSetConfig;
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((invocation) async {
        final msg =
            invocation.positionalArguments[0] as Map<String, dynamic>;
        if (msg['type'] == 'SET_CONFIG') capturedSetConfig = msg;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hymnRepositoryProvider.overrideWithValue(mockRepo),
            windowServiceProvider.overrideWithValue(mockWindowService),
          ],
          child: MaterialApp(
            home: _ProjectHymnLauncher(
              himno: himno,
              onResult: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedSetConfig, isNotNull);
      expect(capturedSetConfig!['background'], 'black');
    });

    testWidgets('retorna null en éxito y mensaje de error en fallo',
        (tester) async {
      final himno = Himno(
        id: 99,
        titulo: 'Fallo',
        tipo: HimnoTipo.oficial,
      );

      when(() => mockRepo.getHymnById(99))
          .thenThrow(Exception('DB error'));
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((_) async {});

      String? capturedResult;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hymnRepositoryProvider.overrideWithValue(mockRepo),
            windowServiceProvider.overrideWithValue(mockWindowService),
          ],
          child: MaterialApp(
            home: _ProjectHymnLauncher(
              himno: himno,
              onResult: (r) => capturedResult = r,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedResult, isNotNull);
      expect(capturedResult, contains('DB error'));
    });
  });
}
