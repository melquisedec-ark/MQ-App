import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/domain/repositories/control_repository.dart';
import 'package:himnario_id_2/presentation/shared_widgets/providers/appearance_provider.dart';
import 'package:himnario_id_2/presentation/views_projection/display/projection_app.dart';
import 'package:himnario_id_2/presentation/views_projection/display/receptor_binding.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/connection_providers.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/projection_providers.dart';

// ═══════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════

class MockControlRepository extends Mock implements ControlRepository {}

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════

/// Construye el widget de prueba con [ProjectionApp] y overrides
/// para los providers que dependen de servicios externos.
Widget _buildTestApp({Stream<String>? stdinOverride}) {
  return ProviderScope(
    overrides: [
      // controlRepositoryProvider → mock
      controlRepositoryProvider.overrideWithProvider(
        Provider<ControlRepository>((ref) => MockControlRepository()),
      ),
      // receptorInfoProvider → valor fijo (no necesita servidor gRPC real)
      receptorInfoProvider.overrideWithProvider(
        Provider<ReceptorInfo>(
          (ref) => const ReceptorInfo(
            isRunning: false,
            port: 50051,
            displayName: 'Test',
          ),
        ),
      ),
    ],
    child: MaterialApp(
      home: ProjectionApp(stdinOverride: stdinOverride),
    ),
  );
}

/// Crea un mensaje LOAD_HYMN con un himno de prueba y sus estrofas.
Map<String, dynamic> _loadHymnMessage({
  int id = 1,
  String titulo = 'Santo, Santo, Santo',
  int? numero = 1,
  String tipo = 'oficial',
  int stanzaCount = 3,
}) {
  return {
    'type': 'LOAD_HYMN',
    'himno_id': id,
    'titulo': titulo,
    'numero': numero,
    'tipo': tipo,
    'estrofas': List.generate(stanzaCount, (i) {
      return {
        'id': i + 1,
        'version_pais_id': 1,
        'tipo': i == 1 ? 'coro' : 'estrofa',
        'orden': i + 1,
        'contenido': 'Estrofa ${i + 1} de prueba',
      };
    }),
    'currentIndex': 0,
  };
}

// ═══════════════════════════════════════════════════════════════
// Test suite
// ═══════════════════════════════════════════════════════════════

void main() {
  group('ProjectionApp', () {
    testWidgets('1. Estado inicial — "Esperando proyección..."',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Esperando proyección...'), findsOneWidget);
    });

    testWidgets('2. LOAD_HYMN — muestra el TitleSlide (portada)',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Enviar mensaje LOAD_HYMN
      stdinCtrl.add(jsonEncode(_loadHymnMessage()));
      await tester.pumpAndSettle();

      // Verificar que el TitleSlide se muestra con el título del himno
      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
      // El contenido de la estrofa NO debe mostrarse porque es el TitleSlide
      expect(find.text('Estrofa 1 de prueba'), findsNothing);
      await stdinCtrl.close();
    });

    testWidgets('3. NEXT_SLIDE — avanza al LyricsSlide', (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cargar himno con 3 estrofas
      stdinCtrl.add(jsonEncode(_loadHymnMessage(stanzaCount: 3)));
      await tester.pumpAndSettle();

      // Avanzar al primer LyricsSlide (slide 1)
      stdinCtrl.add(jsonEncode({'type': 'NEXT_SLIDE'}));
      await tester.pumpAndSettle();

      // Ahora debe mostrar el contenido de la primera estrofa
      expect(find.text('Estrofa 1 de prueba'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('4. NEXT_STANZA (legacy) — avanza al LyricsSlide',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cargar himno con 3 estrofas
      stdinCtrl.add(jsonEncode(_loadHymnMessage(stanzaCount: 3)));
      await tester.pumpAndSettle();

      // NEXT_STANZA debe avanzar al primer LyricsSlide
      stdinCtrl.add(jsonEncode({'type': 'NEXT_STANZA'}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 1 de prueba'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('5. PREV_SLIDE — retrocede al TitleSlide', (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cargar himno con 3 estrofas
      stdinCtrl.add(jsonEncode(_loadHymnMessage(stanzaCount: 3)));
      await tester.pumpAndSettle();

      // Avanzar 2 veces para llegar al slide 2 (LyricsSlide, estrofa 2)
      stdinCtrl.add(jsonEncode({'type': 'NEXT_SLIDE'}));
      await tester.pumpAndSettle();
      stdinCtrl.add(jsonEncode({'type': 'NEXT_SLIDE'}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 2 de prueba'), findsOneWidget);

      // Retroceder al slide 1 (LyricsSlide, estrofa 1)
      stdinCtrl.add(jsonEncode({'type': 'PREV_SLIDE'}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 1 de prueba'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('6. GO_TO_STANZA (legacy) — va a un índice específico',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cargar himno con 3 estrofas
      stdinCtrl.add(jsonEncode(_loadHymnMessage(stanzaCount: 3)));
      await tester.pumpAndSettle();

      // GO_TO_STANZA mapea a goToSlide(index + 1). index 2 → slide 3
      stdinCtrl.add(jsonEncode({'type': 'GO_TO_STANZA', 'index': 2}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 3 de prueba'), findsOneWidget);

      // Volver a index 0 → slide 1 (estrofa 1)
      stdinCtrl.add(jsonEncode({'type': 'GO_TO_STANZA', 'index': 0}));
      await tester.pumpAndSettle();

      expect(find.text('Estrofa 1 de prueba'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('7. BLACKOUT — activa/desactiva pantalla negra',
        (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Cargar himno primero
      stdinCtrl.add(jsonEncode(_loadHymnMessage()));
      await tester.pumpAndSettle();

      // Activar blackout
      stdinCtrl.add(jsonEncode({'type': 'BLACKOUT', 'enabled': true}));
      await tester.pumpAndSettle();

      // Con blackout activado, el título del himno NO debe mostrarse
      expect(find.text('Santo, Santo, Santo'), findsNothing);

      // Desactivar blackout
      stdinCtrl.add(jsonEncode({'type': 'BLACKOUT', 'enabled': false}));
      await tester.pumpAndSettle();

      // El himno debe volver a mostrarse
      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
      await stdinCtrl.close();
    });

    testWidgets('8. Mensaje mal formado — no crashea', (tester) async {
      final stdinCtrl = StreamController<String>.broadcast();
      await tester.pumpWidget(
        _buildTestApp(stdinOverride: stdinCtrl.stream),
      );
      await tester.pumpAndSettle();

      // Enviar texto no-JSON
      stdinCtrl.add('esto no es json');
      await tester.pumpAndSettle();

      // La app debe seguir mostrando el estado inicial
      expect(find.text('Esperando proyección...'), findsOneWidget);

      // Enviar tipo de mensaje desconocido (JSON válido, pero no handler)
      stdinCtrl.add('{"type": "UNKNOWN"}');
      await tester.pumpAndSettle();

      // Sigue mostrando estado inicial
      expect(find.text('Esperando proyección...'), findsOneWidget);

      // Después del malformed, un mensaje válido debe seguir funcionando
      stdinCtrl.add(jsonEncode(_loadHymnMessage()));
      await tester.pumpAndSettle();

      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
      await stdinCtrl.close();
    });

    group('SET_CONFIG — nuevos campos de apariencia', () {
      testWidgets('9. textColor — actualiza el color del texto',
          (tester) async {
        final stdinCtrl = StreamController<String>.broadcast();
        await tester.pumpWidget(
          _buildTestApp(stdinOverride: stdinCtrl.stream),
        );
        await tester.pumpAndSettle();

        // Enviar SET_CONFIG con textColor
        stdinCtrl.add(jsonEncode({
          'type': 'SET_CONFIG',
          'textColor': '#FFB3261E',
        }));
        await tester.pumpAndSettle();

        // Leer el estado del provider
        final container =
            ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
        final appearance = container.read(hymnAppearanceProvider);

        expect(appearance.textColor, const Color(0xFFB3261E));
        await stdinCtrl.close();
      });

      testWidgets('10. chordColor — actualiza el color de acordes',
          (tester) async {
        final stdinCtrl = StreamController<String>.broadcast();
        await tester.pumpWidget(
          _buildTestApp(stdinOverride: stdinCtrl.stream),
        );
        await tester.pumpAndSettle();

        stdinCtrl.add(jsonEncode({
          'type': 'SET_CONFIG',
          'chordColor': '#FF1A6B8A',
        }));
        await tester.pumpAndSettle();

        final container =
            ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
        final appearance = container.read(hymnAppearanceProvider);

        expect(appearance.chordColor, const Color(0xFF1A6B8A));
        await stdinCtrl.close();
      });

      testWidgets('11. fontFamily — actualiza la tipografía', (tester) async {
        final stdinCtrl = StreamController<String>.broadcast();
        await tester.pumpWidget(
          _buildTestApp(stdinOverride: stdinCtrl.stream),
        );
        await tester.pumpAndSettle();

        stdinCtrl.add(jsonEncode({
          'type': 'SET_CONFIG',
          'fontFamily': 'Lora',
        }));
        await tester.pumpAndSettle();

        final container =
            ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
        final appearance = container.read(hymnAppearanceProvider);

        expect(appearance.fontFamily, 'Lora');
        await stdinCtrl.close();
      });

      testWidgets('12. isBold — activa/desactiva negritas', (tester) async {
        final stdinCtrl = StreamController<String>.broadcast();
        await tester.pumpWidget(
          _buildTestApp(stdinOverride: stdinCtrl.stream),
        );
        await tester.pumpAndSettle();

        // Activar bold
        stdinCtrl.add(jsonEncode({
          'type': 'SET_CONFIG',
          'isBold': true,
        }));
        await tester.pumpAndSettle();

        final container =
            ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
        expect(container.read(hymnAppearanceProvider).isBold, true);

        // Desactivar bold
        stdinCtrl.add(jsonEncode({
          'type': 'SET_CONFIG',
          'isBold': false,
        }));
        await tester.pumpAndSettle();

        expect(container.read(hymnAppearanceProvider).isBold, false);
        await stdinCtrl.close();
      });

      testWidgets('13. fontScale — actualiza la escala de fuente',
          (tester) async {
        final stdinCtrl = StreamController<String>.broadcast();
        await tester.pumpWidget(
          _buildTestApp(stdinOverride: stdinCtrl.stream),
        );
        await tester.pumpAndSettle();

        stdinCtrl.add(jsonEncode({
          'type': 'SET_CONFIG',
          'fontScale': 1.5,
        }));
        await tester.pumpAndSettle();

        final container =
            ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
        final appearance = container.read(hymnAppearanceProvider);

        expect(appearance.fontScale, 1.5);
        await stdinCtrl.close();
      });

      testWidgets('14. bgColor — SET_CONFIG ya no procesa bgColor (fix fondo)',
          (tester) async {
        final stdinCtrl = StreamController<String>.broadcast();
        await tester.pumpWidget(
          _buildTestApp(stdinOverride: stdinCtrl.stream),
        );
        await tester.pumpAndSettle();

        // bgColor en SET_CONFIG ya no se procesa (ver BUG_FONDO_RESET.md).
        // El fondo solo se cambia mediante mensajes dedicados (SET_BACKGROUND).
        stdinCtrl.add(jsonEncode({
          'type': 'SET_CONFIG',
          'bgColor': '#FF1D6F42',
        }));
        await tester.pumpAndSettle();

        final container =
            ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));

        // bgColor NO debe cambiar; permanece en default (transparent)
        final appearance = container.read(hymnAppearanceProvider);
        expect(appearance.bgColor, Colors.transparent);

        await stdinCtrl.close();
      });

      testWidgets('15. Campos legacy coexisten con nuevos campos',
          (tester) async {
        final stdinCtrl = StreamController<String>.broadcast();
        await tester.pumpWidget(
          _buildTestApp(stdinOverride: stdinCtrl.stream),
        );
        await tester.pumpAndSettle();

        // Enviar mensaje legacy + nuevo
        stdinCtrl.add(jsonEncode({
          'type': 'SET_CONFIG',
          'backgroundColor': '#FF000000',
          'fontSize': 'large',
          'transitionSpeed': 0.8,
          'background': 'color',
          'textColor': '#FFFFFFFF',
          'fontFamily': 'Cinzel',
        }));
        await tester.pumpAndSettle();

        final container =
            ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));

        // Campos legacy
        final config = container.read(projectionConfigProvider);
        expect(config.backgroundColor, const Color(0xFF000000));
        expect(config.fontSize, ProjectionFontSize.large);
        expect(config.transitionSpeed, 0.8);
        expect(config.background, ProjectionBackground.color);

        // Campos nuevos
        final appearance = container.read(hymnAppearanceProvider);
        expect(appearance.textColor, const Color(0xFFFFFFFF));
        expect(appearance.fontFamily, 'Cinzel');

        await stdinCtrl.close();
      });

      testWidgets('16. Color hex inválido — no crashea', (tester) async {
        final stdinCtrl = StreamController<String>.broadcast();
        await tester.pumpWidget(
          _buildTestApp(stdinOverride: stdinCtrl.stream),
        );
        await tester.pumpAndSettle();

        // Enviar hex inválido
        stdinCtrl.add(jsonEncode({
          'type': 'SET_CONFIG',
          'textColor': 'no-es-un-color',
          'bgColor': 'inválido',
        }));
        await tester.pumpAndSettle();

        // La app no debe crashear, estado debe permanecer default
        final container =
            ProviderScope.containerOf(tester.element(find.byType(ProjectionApp)));
        final appearance = container.read(hymnAppearanceProvider);
        // Valores por defecto
        expect(appearance.textColor, const Color(0xFF1C1B1F));
        expect(appearance.bgColor, Colors.transparent);

        await stdinCtrl.close();
      });
    });
  });
}
