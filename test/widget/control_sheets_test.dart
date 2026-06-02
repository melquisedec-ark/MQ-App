import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mqapp/core/window_manager/window_service.dart';
import 'package:mqapp/presentation/shared_widgets/control_sheets.dart';
import 'package:mqapp/core/window_manager/window_providers.dart';

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
      // Phase 2a.4: el BrushSheet tiene múltiples sliders (cardOpacity,
      // glassBlurSigma, fontScale). El fontScale está debajo del fold
      // en el ListView, por lo que usamos byWidgetPredicate para
      // identificarlo por su `min` único (0.7 — los demás usan 0.0).
      // Hacemos scroll primero para asegurar que esté renderizado.
      final fontScaleFinder = find.byWidgetPredicate(
        (w) => w is Slider && w.min == 0.7,
        description: 'Slider with min=0.7 (font scale)',
      );
      await tester.scrollUntilVisible(
        fontScaleFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      // Encontrar el thumb del slider (no el track) para hacer tap directo
      // en una posición que registre el cambio. El Slider de fontScale
      // ocupa un ancho dado por Row>Expanded>Slider.
      final sliderCenter = tester.getCenter(fontScaleFinder);
      // Tap a la derecha del centro para que el slider registre el cambio
      // (mover el valor hacia el max).
      await tester.tapAt(sliderCenter + const Offset(40, 0));
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
      // Phase 2a.4: mismo patrón que el test anterior — el fontScale
      // slider está debajo del fold, hay que hacer scroll.
      final fontScaleFinder2 = find.byWidgetPredicate(
        (w) => w is Slider && w.min == 0.7,
        description: 'Slider with min=0.7 (font scale)',
      );
      await tester.scrollUntilVisible(
        fontScaleFinder2,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final sliderCenter2 = tester.getCenter(fontScaleFinder2);
      await tester.tapAt(sliderCenter2 + const Offset(40, 0));
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
