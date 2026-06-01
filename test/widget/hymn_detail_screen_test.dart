import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/enums/estrofa_tipo.dart';
import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/domain/entities/categoria.dart';
import 'package:himnario_id_2/domain/entities/estrofa.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/domain/entities/version_pais.dart';
import 'package:himnario_id_2/domain/repositories/audio_repository.dart';
import 'package:himnario_id_2/domain/repositories/control_repository.dart';
import 'package:himnario_id_2/domain/repositories/hymn_repository.dart';
import 'package:himnario_id_2/presentation/dual_mode_wrapper/dual_mode_providers.dart';
import 'package:himnario_id_2/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart';
import 'package:himnario_id_2/presentation/views_personal/providers/audio_providers.dart';
import 'package:himnario_id_2/presentation/views_personal/providers/hymn_providers.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/connection_providers.dart';
import 'package:himnario_id_2/core/window_manager/window_providers.dart';
import 'package:himnario_id_2/core/window_manager/window_service.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ─────────────────────────────────────────────────────

class MockHymnRepository extends Mock implements HymnRepository {}

class MockAudioRepository extends Mock implements AudioRepository {}

class MockControlRepository extends Mock implements ControlRepository {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockWindowService extends Mock implements WindowService {}

// ─── Helper: crear himno de prueba ────────────────────────────

Himno _createTestHimno({
  int id = 1,
  String titulo = 'Santo, Santo, Santo',
  int? numero = 1,
  HimnoTipo tipo = HimnoTipo.oficial,
}) {
  return Himno(
    id: id,
    titulo: titulo,
    numero: numero,
    tipo: tipo,
    versiones: [
      VersionPais(id: 1, himnoId: id, paisId: 0, paisNombre: 'Honduras', paisCodigo: 'HN', tonalidadOriginal: 'G'),
    ],
    categorias: [
      const Categoria(id: 1, nombre: 'Alabanza'),
    ],
  );
}

// ─── Provider Overrides ───────────────────────────────────────

/// Provider override para hymnRepositoryProvider
final _hymnRepoOverride = hymnRepositoryProvider.overrideWith(
  (ref) => MockHymnRepository(),
);

/// Provider override para audioRepositoryProvider
final _audioRepoOverride = audioRepositoryProvider.overrideWith(
  (ref) => MockAudioRepository(),
);

/// Provider override para controlRepositoryProvider
final _controlRepoOverride = controlRepositoryProvider.overrideWith(
  (ref) => MockControlRepository(),
);

/// Provider override para stanzasProvider: retorna estrofas mock
List<Estrofa> _mockStanzas = [];
final _stanzasOverride = stanzasProvider.overrideWith(
  (ref, int versionPaisId) async {
    return _mockStanzas;
  },
);

/// Provider override para isConnectedProvider
final _isConnectedOverride = isConnectedProvider.overrideWith(
  (ref) => false,
);

/// Provider override para modo desktop
final _desktopModeOverride = isDesktopModeProvider.overrideWith(
  (ref) => true,
);

/// WindowService mock
final _mockWindowService = MockWindowService();

/// Provider override para windowServiceProvider con mock
final _windowServiceOverride = windowServiceProvider.overrideWith(
  (ref) => _mockWindowService,
);

Widget _buildTestApp({
  required Himno himno,
  List<Override> overrides = const [],
  NavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      _hymnRepoOverride,
      _audioRepoOverride,
      _controlRepoOverride,
      _stanzasOverride,
      _isConnectedOverride,
      _desktopModeOverride,
      _windowServiceOverride,
      ...overrides,
    ],
    child: MaterialApp(
      home: HymnDetailScreen(himno: himno),
      routes: {
        '/live-control': (context) {
          return const Scaffold(
            body: Text('Live Control Screen'),
          );
        },
        '/arrangement-editor': (context) {
          return const Scaffold(
            body: Text('Arrangement Editor'),
          );
        },
      },
      navigatorObservers: navigatorObserver != null
          ? [navigatorObserver]
          : [],
    ),
  );
}

// ─── Tests ─────────────────────────────────────────────────────

void main() {
  group('HymnDetailScreen', () {
    final testHimno = _createTestHimno();

    setUp(() {
      _mockStanzas = [
        const Estrofa(
          id: 1,
          versionPaisId: 1,
          tipo: EstrofaTipo.estrofa,
          orden: 1,
          contenido:
              '[G]Santo, [C]Santo, [G]Santo\nSeñor [D]Dios de los [G]ejércitos',
        ),
        const Estrofa(
          id: 2,
          versionPaisId: 1,
          tipo: EstrofaTipo.coro,
          orden: 2,
          contenido: '[C]Santo, [G]Santo, [D]Santo\nToda la [G]tierra',
        ),
      ];
    });

    testWidgets('Renderiza el título del himno', (tester) async {
      await tester.pumpWidget(_buildTestApp(himno: testHimno));
      await tester.pumpAndSettle();

      // Verificar que el título del himno aparece en el header
      // Nota: también aparece en letra de estrofas, por eso findsWidgets
      expect(find.text('Santo, Santo, Santo'), findsWidgets);

      // Verificar que el AppBar muestra "Himno 1"
      expect(find.text('Himno 1'), findsOneWidget);
    });

    testWidgets('Renderiza las estrofas del himno', (tester) async {
      await tester.pumpWidget(_buildTestApp(himno: testHimno));
      await tester.pumpAndSettle();

      // Verificar que las estrofas se renderizan (contenido limpio, sin ChordPro)
      expect(find.textContaining('Santo'), findsWidgets);

      // Verificar que la etiqueta de tipo de estrofa aparece
      expect(find.textContaining('ESTROFA'), findsOneWidget);
      expect(find.text('CORO'), findsOneWidget);
    });

    testWidgets('El botón de transposición (-) funciona', (tester) async {
      await tester.pumpWidget(_buildTestApp(himno: testHimno));
      await tester.pumpAndSettle();

      // Buscar el botón de bajar tono (tooltip: 'Bajar tono')
      final downButton = find.byTooltip('Bajar tono');
      expect(downButton, findsOneWidget);

      // Hacer tap en bajar tono
      await tester.tap(downButton);
      await tester.pumpAndSettle();

      // La interacción no debe lanzar error
    });

    testWidgets('El botón de transposición (+) funciona', (tester) async {
      await tester.pumpWidget(_buildTestApp(himno: testHimno));
      await tester.pumpAndSettle();

      // Buscar el botón de subir tono
      final upButton = find.byTooltip('Subir tono');
      expect(upButton, findsOneWidget);

      // Hacer tap en subir tono
      await tester.tap(upButton);
      await tester.pumpAndSettle();
    });

    testWidgets('Muestra el botón Presentar en el AppBar (modo desktop)',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(himno: testHimno));
      await tester.pump();

      // En modo desktop, el botón Presentar es un IconButton con tooltip
      expect(find.byTooltip('Presentar'), findsOneWidget);
    });

    testWidgets(
      'Muestra el FAB con opciones de himno',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            himno: testHimno,
          ),
        );
        await tester.pump();

        // Verificar que el FAB está presente
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets('Muestra loading state mientras cargan estrofas',
        (tester) async {
      // Usar un Completer para controlar cuándo se completa la carga
      final completer = Completer<List<Estrofa>>();
      final loadingOverride = stanzasProvider.overrideWith(
        (ref, int versionPaisId) => completer.future,
      );

      await tester.pumpWidget(
        _buildTestApp(himno: testHimno, overrides: [loadingOverride]),
      );
      await tester.pump();

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'Debe mostrar indicador de carga mientras se cargan estrofas',
      );

      // Completar para limpiar el timer y evitar fuga
      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });
}
