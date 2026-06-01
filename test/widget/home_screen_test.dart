import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/data/datasources/remote/grpc_control_datasource.dart';
import 'package:himnario_id_2/domain/entities/categoria.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/domain/entities/version_pais.dart';
import 'package:himnario_id_2/presentation/dual_mode_wrapper/dual_mode_providers.dart';
import 'package:himnario_id_2/presentation/views_personal/dashboard/home_screen.dart';
import 'package:himnario_id_2/presentation/views_personal/providers/hymn_providers.dart';
import 'package:himnario_id_2/presentation/views_projection/providers/connection_providers.dart';
import 'package:mocktail/mocktail.dart';

/// Mock NavigatorObserver para verificar navegación.
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

/// Mock de un himno de prueba.
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

/// Mock de GrpcControlDataSource para ConnectionNotifier.
class _MockGrpcControlDataSource extends Mock implements GrpcControlDataSource {}

/// ConnectionNotifier en estado desconectado para pruebas.
final _disconnectedOverride = connectionStateProvider.overrideWith(
  (ref) => ConnectionNotifier(_MockGrpcControlDataSource(), ref),
);

/// Provider override para hymnListProvider que retorna datos mock.
List<Himno> _mockHimnos = [];
final _hymnListOverride = hymnListProvider.overrideWith(
  (ref, HymnQueryParam query) async {
    return _mockHimnos;
  },
);

/// Provider override para isDesktopModeProvider (false = modo phone).
final _phoneModeOverride = isDesktopModeProvider.overrideWith(
  (ref) => false,
);

Widget _buildTestApp({
  List<Override> overrides = const [],
  NavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      _disconnectedOverride,
      _hymnListOverride,
      _phoneModeOverride,
      ...overrides,
    ],
    child: MaterialApp(
      home: const HomeScreen(),
      routes: {
        '/hymn-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Himno) return const SizedBox.shrink();
          return Scaffold(
            appBar: AppBar(title: Text(args.titulo)),
            body: const Text('Hymn Detail'),
          );
        },
      },
      navigatorObservers: navigatorObserver != null
          ? [navigatorObserver]
          : [],
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRoute());
  });

  group('HomeScreen', () {
    testWidgets('Renderiza el buscador de himnos', (tester) async {
      _mockHimnos = [];
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verificar que el buscador está presente
      expect(
        find.byType(TextField),
        findsOneWidget,
        reason: 'Debe haber exactamente un TextField (buscador)',
      );
      // Verificar el hint
      expect(
        find.text('Buscar himno por número o título...'),
        findsOneWidget,
        reason: 'Debe mostrar el hint de búsqueda',
      );
    });

    testWidgets('Renderiza los chips de filtro', (tester) async {
      _mockHimnos = [];
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verificar que los tres chips están presentes
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Oficiales'), findsOneWidget);
      expect(find.text('Inspiradas'), findsOneWidget);

      // Verificar que FilterChip se usa
      // 3 de filtro + 2 de orden + 1 de categoría = 6
      expect(find.byType(FilterChip), findsNWidgets(6));
    });

    testWidgets('Muestra loading state mientras carga himnos', (tester) async {
      // Usar un Completer para controlar cuándo se completa la carga
      final completer = Completer<List<Himno>>();
      final loadingOverride = hymnListProvider.overrideWith(
        (ref, HymnQueryParam query) => completer.future,
      );

      await tester.pumpWidget(_buildTestApp(overrides: [loadingOverride]));
      // Solo pump una vez sin settle para ver el loading state
      await tester.pump();

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
        reason: 'Debe mostrar indicador de carga mientras se cargan himnos',
      );

      // Completar para limpiar el timer y evitar fuga
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('Muestra lista de himnos cuando hay datos', (tester) async {
      _mockHimnos = [
        _createTestHimno(
          id: 1,
          titulo: 'Santo, Santo, Santo',
          numero: 1,
        ),
        _createTestHimno(
          id: 2,
          titulo: 'Grande es Jehová',
          numero: 5,
        ),
      ];

      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verificar que los títulos de los himnos se renderizan
      expect(find.text('Santo, Santo, Santo'), findsOneWidget);
      expect(find.text('Grande es Jehová'), findsOneWidget);

      // Verificar que se usa ListView
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets(
      'Al hacer tap en un himno navega a detalle',
      (tester) async {
        _mockHimnos = [
          _createTestHimno(
            id: 1,
            titulo: 'Santo, Santo, Santo',
            numero: 1,
          ),
        ];

        final observer = MockNavigatorObserver();

        await tester.pumpWidget(
          _buildTestApp(navigatorObserver: observer),
        );
        await tester.pumpAndSettle();

        // Encontrar el HymnCard y hacer tap
        final hymnCard = find.byType(InkWell).first;
        await tester.tap(hymnCard);
        await tester.pumpAndSettle();

        // Verificar que se navegó a /hymn-detail
        verify(
          () => observer.didPush(any(), any()),
        ).called(1);
      },
    );

    testWidgets('Muestra estado vacío cuando no hay himnos', (tester) async {
      _mockHimnos = [];
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('No hay himnos disponibles'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('El botón de conexión está presente', (tester) async {
      _mockHimnos = [];
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verificar que el icono de cast está en la AppBar
      expect(find.byIcon(Icons.cast_rounded), findsOneWidget);
    });
  });
}

/// Fake Route para mocktail registerFallbackValue.
class _FakeRoute extends Fake implements Route<dynamic> {}
