import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mqapp/features/himnario/presentation/screens/admin_himnario_screen.dart';

import '../biblia/helpers/bible_db_test_helper.dart';

/// Helper que construye el router de prueba.
GoRouter _buildRouter({String initialLocation = '/admin'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const AdminHimnarioScreen(),
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  group('AdminHimnarioScreen (D8)', () {
    testWidgets('renderiza AppBar con título y 2 tabs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: _buildRouter()),
        ),
      );
      // Usamos pump en vez de pumpAndSettle porque HymnListScreen/CatalogPanelScreen
      // tienen async providers que nunca "settlean" (timers, streams, etc.)
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // AppBar
      expect(find.text('Administrar himnario'), findsOneWidget);

      // Tabs
      expect(find.text('Himnos'), findsOneWidget);
      expect(find.text('Catálogos'), findsOneWidget);

      // PopupMenuButton (3 puntos) está en el AppBar
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('PopupMenuButton muestra Importar/Exportar/Acerca de',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: _buildRouter()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Abrir el menú de 3 puntos.
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Importar'), findsOneWidget);
      expect(find.text('Exportar'), findsOneWidget);
      expect(find.text('Acerca de catálogos'), findsOneWidget);
    });

    testWidgets('TabBar muestra los 2 tabs (Himnos/Catálogos)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: _buildRouter()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // El TabBarView debe tener 2 hijos.
      final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
      expect(tabBarView.children.length, 2);
    });
  });
}
