import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mqapp/core/enums/himno_tipo.dart';
import 'package:mqapp/core/window_manager/window_service.dart';
import 'package:mqapp/data/datasources/remote/grpc_control_datasource.dart';
import 'package:mqapp/domain/entities/categoria.dart';
import 'package:mqapp/domain/entities/himno.dart';
import 'package:mqapp/domain/entities/version_pais.dart';
import 'package:mqapp/presentation/dual_mode_wrapper/dual_mode_providers.dart';
import 'package:mqapp/presentation/views_personal/dashboard/home_screen.dart';
import 'package:mqapp/presentation/views_personal/dashboard/present_button.dart';
import 'package:mqapp/presentation/views_personal/providers/hymn_providers.dart';
import 'package:mqapp/presentation/views_projection/controller/present_control_bar.dart';
import 'package:mqapp/presentation/views_projection/providers/connection_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/live_control_providers.dart';
import 'package:mqapp/presentation/views_projection/providers/presentation_providers.dart';

/// Mock de GrpcControlDataSource para ConnectionNotifier.
class _MockGrpcControlDataSource extends Mock implements GrpcControlDataSource {}

/// Mock de WindowService para pruebas de presentación.
class _MockWindowService extends Mock implements WindowService {}

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

/// Provider override para isDesktopModeProvider.
Override _desktopModeOverride(bool isDesktop) =>
    isDesktopModeProvider.overrideWith((ref) => isDesktop);

/// Construye un GoRouter de prueba con HomeScreen.
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
    ],
  );
}

/// Construye la app de prueba con [PresentControlBar] centralizado igual que
/// `MqApp.build()` en `lib/app.dart`.
Widget _buildTestApp({
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      _disconnectedOverride,
      _hymnListOverride,
      ...overrides,
    ],
    child: Consumer(
      builder: (context, ref, child) {
        final isPresenting = ref.watch(isPresentingProvider);
        final isDesktop = ref.watch(isDesktopModeProvider);
        return MaterialApp.router(
          routerConfig: _buildRouter(),
          builder: (ctx, routeChild) {
            final safeChild = routeChild ?? const SizedBox.shrink();
            return Stack(
              fit: StackFit.expand,
              children: [
                safeChild,
                if (isPresenting && isDesktop)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: PresentControlBar(),
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}

void main() {
  group('HomeScreen - Presentación integration', () {
    testWidgets(
      'PresentButton FAB visible cuando NO está presentando (desktop)',
      (tester) async {
        _mockHimnos = [];
        await tester.pumpWidget(_buildTestApp(overrides: [
          _desktopModeOverride(true),
          isPresentingProvider.overrideWith((ref) => false),
        ]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byType(PresentButton),
          findsOneWidget,
          reason: 'PresentButton debe ser visible cuando no se está presentando',
        );
      },
    );

    testWidgets(
      'PresentButton FAB oculto cuando SÍ está presentando (desktop)',
      (tester) async {
        _mockHimnos = [];
        await tester.pumpWidget(_buildTestApp(overrides: [
          _desktopModeOverride(true),
          isPresentingProvider.overrideWith((ref) => true),
        ]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byType(PresentButton),
          findsNothing,
          reason: 'PresentButton debe ocultarse cuando se está presentando',
        );
      },
    );

    testWidgets(
      'PresentControlBar visible cuando SÍ está presentando (desktop)',
      (tester) async {
        _mockHimnos = [];
        await tester.pumpWidget(_buildTestApp(overrides: [
          _desktopModeOverride(true),
          isPresentingProvider.overrideWith((ref) => true),
        ]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byType(PresentControlBar),
          findsOneWidget,
          reason: 'PresentControlBar debe ser visible cuando se está presentando',
        );
      },
    );

    testWidgets(
      'PresentControlBar oculto cuando NO está presentando (desktop)',
      (tester) async {
        _mockHimnos = [];
        await tester.pumpWidget(_buildTestApp(overrides: [
          _desktopModeOverride(true),
          isPresentingProvider.overrideWith((ref) => false),
        ]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byType(PresentControlBar),
          findsNothing,
          reason: 'PresentControlBar debe ocultarse cuando no se está presentando',
        );
      },
    );

    testWidgets(
      'PresentButton oculto en modo phone (no desktop)',
      (tester) async {
        _mockHimnos = [];
        await tester.pumpWidget(_buildTestApp(overrides: [
          _desktopModeOverride(false),
          isPresentingProvider.overrideWith((ref) => false),
        ]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byType(PresentButton),
          findsNothing,
          reason: 'PresentButton solo debe mostrarse en modo desktop',
        );
      },
    );

    testWidgets(
      'PresentControlBar oculto en modo phone aunque isPresenting=true',
      (tester) async {
        _mockHimnos = [];
        await tester.pumpWidget(_buildTestApp(overrides: [
          _desktopModeOverride(false),
          isPresentingProvider.overrideWith((ref) => true),
        ]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byType(PresentControlBar),
          findsNothing,
          reason: 'PresentControlBar solo debe mostrarse en modo desktop',
        );
      },
    );
  });

  group('PresentControlBar - Bible mode', () {
    testWidgets(
      'Muestra ícono de libro y título bíblico cuando módulo es Bible',
      (tester) async {
        final notifier = LiveControlNotifier();
        notifier.loadBibleChapter(
          libroNombre: 'Génesis',
          capitulo: 1,
          versiculos: ['En el principio creó Dios los cielos y la tierra.'],
        );

        _mockHimnos = [];
        await tester.pumpWidget(_buildTestApp(overrides: [
          _desktopModeOverride(true),
          isPresentingProvider.overrideWith((ref) => true),
          liveControlProvider.overrideWith((ref) => notifier),
        ]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verificar que PresentControlBar está visible
        expect(find.byType(PresentControlBar), findsOneWidget);

        // Verificar que muestra el título bíblico
        expect(find.text('Génesis 1'), findsOneWidget);

        // Verificar que muestra el ícono de libro (header + module switch button)
        expect(find.byIcon(Icons.menu_book_outlined), findsWidgets);
      },
    );

    testWidgets(
      'Muestra ícono de música y título de himno cuando módulo es Hymnal',
      (tester) async {
        final notifier = LiveControlNotifier();
        const himno = Himno(
          id: 1,
          titulo: 'Santo, Santo, Santo',
          numero: 1,
          tipo: HimnoTipo.oficial,
        );
        notifier.loadHymn(himno, []);

        _mockHimnos = [];
        await tester.pumpWidget(_buildTestApp(overrides: [
          _desktopModeOverride(true),
          isPresentingProvider.overrideWith((ref) => true),
          liveControlProvider.overrideWith((ref) => notifier),
        ]));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verificar que PresentControlBar está visible
        expect(find.byType(PresentControlBar), findsOneWidget);

        // Verificar que muestra el título del himno
        expect(find.text('Santo, Santo, Santo'), findsOneWidget);

        // Verificar que muestra el ícono de nota musical
        expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      },
    );
  });
}
