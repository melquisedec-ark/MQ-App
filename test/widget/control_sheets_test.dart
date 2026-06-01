import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/core/window_manager/window_service.dart';
import 'package:himnario_id_2/presentation/shared_widgets/control_sheets.dart';
import 'package:himnario_id_2/core/window_manager/window_providers.dart';

// ═══════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════

class MockWindowService extends Mock implements WindowService {}

// ═══════════════════════════════════════════════════════════════
// Test suite
// ═══════════════════════════════════════════════════════════════

void main() {
  late MockWindowService mockWindowService;

  setUp(() {
    mockWindowService = MockWindowService();
    registerFallbackValue(<String, dynamic>{});
  });

  /// Widget helper que muestra el BrushSheet en un contexto controlado.
  Widget _buildTestApp() {
    return ProviderScope(
      overrides: [
        windowServiceProvider.overrideWithValue(mockWindowService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () => showBrushSheet(context, ref: ref),
              child: const Text('Abrir Brocha'),
            ),
          ),
        ),
      ),
    );
  }

  group('showBrushSheet — _syncAppearanceToProjection', () {
    testWidgets('envía SET_CONFIG al cambiar color de letra',
        (tester) async {
      final sentMessages = <Map<String, dynamic>>[];
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((invocation) async {
        final msg =
            invocation.positionalArguments[0] as Map<String, dynamic>;
        sentMessages.add(msg);
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Abrir el sheet de la Brocha
      await tester.tap(find.text('Abrir Brocha'));
      // Avanzar la animación del ModalBottomSheet sin pumpAndSettle
      // (DraggableScrollableSheet nunca se "settlea" completamente)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Buscar el slider de tamaño de letra y moverlo
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.drag(slider, const Offset(50, 0));
      await tester.pump(const Duration(milliseconds: 300));

      // Verificar que se envió SET_CONFIG
      expect(sentMessages.isNotEmpty, true);
      expect(sentMessages.any((m) => m['type'] == 'SET_CONFIG'), true);
    });

    testWidgets('envía SET_CONFIG con todos los campos requeridos',
        (tester) async {
      Map<String, dynamic>? capturedMessage;
      when(() => mockWindowService.sendMessage(any()))
          .thenAnswer((invocation) async {
        capturedMessage =
            invocation.positionalArguments[0] as Map<String, dynamic>;
      });

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Brocha'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Pulsar el slider para forzar un cambio
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(50, 0));
      await tester.pump(const Duration(milliseconds: 300));

      // Verificar la estructura del mensaje SET_CONFIG
      expect(capturedMessage, isNotNull);
      expect(capturedMessage!['type'], 'SET_CONFIG');
      // Nuevos campos
      for (final key in [
        'textColor',
        'chordColor',
        'fontFamily',
        'isBold',
        'fontScale',
        'bgColor',
      ]) {
        expect(capturedMessage!.containsKey(key), true,
            reason: 'Falta campo $key en SET_CONFIG');
      }
      // Campos legacy
      for (final key in [
        'backgroundColor',
        'fontSize',
        'transitionSpeed',
        'background',
      ]) {
        expect(capturedMessage!.containsKey(key), true,
            reason: 'Falta campo legacy $key en SET_CONFIG');
      }
    });
  });
}
