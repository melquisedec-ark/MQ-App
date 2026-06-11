import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mqapp/core/enums/himno_tipo.dart';
import 'package:mqapp/data/datasources/remote/grpc_control_datasource.dart';
import 'package:mqapp/domain/entities/categoria.dart';
import 'package:mqapp/domain/entities/himno.dart';
import 'package:mqapp/domain/entities/version_pais.dart';
import 'package:mqapp/features/himnario/presentation/screens/admin_himnario_screen.dart';
import 'package:mqapp/presentation/dual_mode_wrapper/dual_mode_providers.dart';
import 'package:mqapp/presentation/views_personal/dashboard/home_screen.dart';
import 'package:mqapp/presentation/views_personal/providers/hymn_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/connection_providers.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_config_provider.dart';

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

/// Override para themeModeProvider — evita que ThemeModeNotifier acceda a
/// la base de datos (sqflite) durante los tests de widgets, eliminando
/// el timer pendiente de 10s que hacía fallar los tests en CI.
final _themeModeOverride = themeModeProvider.overrideWith(
  (ref) => ThemeModeNotifier(ref, autoLoad: false)..state = ThemeMode.light,
);

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

/// Construye un GoRouter de prueba con HomeScreen y hymn-detail.
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/hymn-detail',
        name: 'hymn-detail',
        builder: (_, state) {
          final args = state.extra;
          if (args is! Himno) return const SizedBox.shrink();
          return Scaffold(
            appBar: AppBar(title: Text(args.titulo)),
            body: const Text('Hymn Detail'),
          );
        },
      ),
      GoRoute(
        path: '/hymn-admin',
        name: 'hymn-admin',
        builder: (_, __) => const AdminHimnarioScreen(),
      ),
    ],
  );
}

  Widget _buildTestApp({
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        _disconnectedOverride,
        _hymnListOverride,
        _phoneModeOverride,
        _themeModeOverride,
        ...overrides,
      ],
      child: MaterialApp.router(routerConfig: _buildRouter()),
    );
  }

void main() {
  group('HomeScreen', () {
    testWidgets('Renderiza el buscador de himnos', (tester) async {
      _mockHimnos = [];
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verificar que los cuatro chips de filtro están presentes
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Oficiales'), findsOneWidget);
      expect(find.text('Inspiradas'), findsOneWidget);
      expect(find.text('Convención'), findsOneWidget);

      // Phase 2a.4: el chip "Convención" se añadió a la barra de
      // filtros, así que ahora hay 4 chips de filtro + 2 de orden
      // (A-Z, Z-A) + 1 de categoría = 7 chips en total.
      expect(find.byType(FilterChip), findsNWidgets(7));
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

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

        await tester.pumpWidget(_buildTestApp());
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Encontrar el texto del himno y hacer tap en su InkWell ancestro.
        final hymnText = find.text('Santo, Santo, Santo');
        await tester.tap(hymnText);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verificar que se navegó al detalle: el título ahora aparece en
        // el AppBar de HymnDetailScreen (además mantenemos Hymn Detail).
        expect(find.text('Hymn Detail'), findsOneWidget);
      },
    );

    testWidgets('Muestra estado vacío cuando no hay himnos', (tester) async {
      _mockHimnos = [];
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('No hay himnos disponibles'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('El botón de conexión está presente', (tester) async {
      _mockHimnos = [];
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verificar que el icono de cast está en la AppBar
      expect(find.byIcon(Icons.cast_rounded), findsOneWidget);
    });
  });
}
