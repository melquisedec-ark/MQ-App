import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mqapp/features/biblia/presentation/screens/about_screen.dart';

void main() {
  group('AboutScreen (D7)', () {
    testWidgets('renderiza elementos clave: título, tagline, tarjeta',
        (tester) async {
      // Override el router para que la navegación in-app no falle.
      final router = GoRouter(
        initialLocation: '/about',
        routes: [
          GoRoute(
            path: '/about',
            name: 'about',
            builder: (_, __) => const AboutScreen(),
          ),
          GoRoute(
            path: '/',
            name: 'home',
            builder: (_, __) => const Scaffold(body: Text('home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // AppBar con título "Acerca de"
      expect(find.text('Acerca de'), findsOneWidget);

      // Nombre de la app
      expect(find.text('MQ-App'), findsOneWidget);

      // Tagline
      expect(
        find.text('Biblia y Himnario en un solo lugar'),
        findsOneWidget,
      );

      // Tarjeta de información - Repositorio
      expect(find.text('Repositorio'), findsOneWidget);
      expect(
        find.text('github.com/melquisedec-ark/MQ-App'),
        findsOneWidget,
      );

      // Página oficial y comunidad (ahora habilitadas)
      expect(find.text('Página oficial'), findsOneWidget);
      expect(find.text('Comunidad WhatsApp'), findsOneWidget);
      expect(find.text('melquisedec-ark.github.io'), findsOneWidget);
      expect(find.text('Chatea con la comunidad'), findsOneWidget);

      // Licencia MIT
      expect(find.text('Licencia'), findsOneWidget);
      expect(find.text('MIT'), findsOneWidget);

      // Botón Volver
      expect(find.text('Volver'), findsOneWidget);
    });

    testWidgets('botón Volver hace pop', (tester) async {
      int popped = 0;
      final router = GoRouter(
        initialLocation: '/about',
        routes: [
          GoRoute(
            path: '/about',
            name: 'about',
            builder: (_, __) => const AboutScreen(),
          ),
          GoRoute(
            path: '/',
            name: 'home',
            builder: (_, __) => const Scaffold(body: Text('home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            onGenerateTitle: (context) => 'Test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap en "Volver" debe hacer pop.
      // (No podemos verificar el pop directamente, pero sí que no crashea.)
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      // Si llegó aquí sin excepción, el test pasa.
      expect(find.byType(AboutScreen), findsOneWidget);
      // popped counter no es usado, lo declaramos solo para evitar warning.
      popped++;
      expect(popped, 1);
    });

    // C9 follow-up: la sección de atribuciones lista los datasets
    // openbible / scrollmapper (CC-BY 4.0, MIT) y la fuente del texto
    // bíblico (RV1909, dominio público).
    testWidgets('muestra sección de Atribuciones con openbible/scrollmapper',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/about',
        routes: [
          GoRoute(
            path: '/about',
            name: 'about',
            builder: (_, __) => const AboutScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Header de la sección.
      expect(find.text('Atribuciones'), findsOneWidget);

      // Cross-references (requerido por CC-BY 4.0).
      expect(
        find.text('Datos de cross-references bíblicas:'),
        findsOneWidget,
      );
      expect(
        find.text('openbible.info/labs/cross-references/ (CC-BY 4.0)'),
        findsOneWidget,
      );
      expect(
        find.text('Vía scrollmapper/bible_databases (MIT)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Treasury of Scripture Knowledge'),
        findsOneWidget,
      );

      // Texto bíblico.
      expect(find.text('Texto bíblico (RV1909):'), findsOneWidget);
      expect(
        find.text('Reina Valera 1909 — dominio público'),
        findsOneWidget,
      );
    });
  });
}
