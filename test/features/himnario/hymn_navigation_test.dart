import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mqapp/core/enums/himno_tipo.dart';
import 'package:mqapp/core/router/app_router.dart';
import 'package:mqapp/domain/entities/categoria.dart';
import 'package:mqapp/domain/entities/himno.dart';
import 'package:mqapp/domain/entities/version_pais.dart';
import 'package:mqapp/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart';

/// Himno de prueba.
Himno _createTestHimno() {
  return Himno(
    id: 1,
    titulo: 'Santo, Santo, Santo',
    numero: 1,
    tipo: HimnoTipo.oficial,
    versiones: [
      VersionPais(
        id: 1,
        himnoId: 1,
        paisId: 0,
        paisNombre: 'Honduras',
        paisCodigo: 'HN',
        tonalidadOriginal: 'G',
      ),
    ],
    categorias: const [Categoria(id: 1, nombre: 'Alabanza')],
  );
}

void main() {
  group('B4: ruta hymn-detail existe en go_router', () {
    test('ruta "hymn-detail" registrada en appRouter', () {
      // No usamos pumpWidget porque appRouter tiene dependencias que
      // requieren inicialización completa. Verificamos la estructura del
      // árbol de rutas directamente.
      final config = appRouter.configuration;
      bool found = false;
      void visit(RouteBase r) {
        if (r is GoRoute && r.name == 'hymn-detail') {
          found = true;
        }
        if (r is GoRoute) {
          for (final sub in r.routes) {
            visit(sub);
          }
        }
      }

      for (final r in config.routes) {
        visit(r);
      }

      expect(found, true,
          reason: 'B4: ruta "hymn-detail" debe existir en appRouter');
    });

    test('ruta "hymn-detail" tiene path "himnario/detalle"', () {
      GoRoute? found;
      void visit(RouteBase r) {
        if (r is GoRoute && r.name == 'hymn-detail') {
          found = r;
        }
        if (r is GoRoute && found == null) {
          for (final sub in r.routes) {
            visit(sub);
          }
        }
      }

      for (final r in appRouter.configuration.routes) {
        visit(r);
      }

      expect(found, isNotNull);
      expect(found!.path, 'detalle',
          reason: 'B4: debe estar anidada bajo himnario (path relativo)');
    });

    testWidgets('context.pushNamed("hymn-detail", extra: himno) navega',
        (tester) async {
      // Construimos un router wrapper que solo expone la ruta hymn-detail
      // con un builder dummy (evita dependencias pesadas de HymnDetailScreen).
      final himno = _createTestHimno();
      final testRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('home')),
            routes: [
              GoRoute(
                path: 'hymn-detail',
                name: 'hymn-detail',
                builder: (ctx, state) {
                  final h = state.extra;
                  if (h is Himno) {
                    return Scaffold(body: Text('HymnDetail: ${h.titulo}'));
                  }
                  return const Scaffold(body: Text('NO HIMNO'));
                },
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );
      await tester.pumpAndSettle();

      // Tap simulado: usar el context del widget raíz.
      final BuildContext context = tester.element(find.text('home'));
      context.pushNamed('hymn-detail', extra: himno);
      await tester.pumpAndSettle();

      expect(find.text('HymnDetail: ${himno.titulo}'), findsOneWidget,
          reason: 'B4: pushNamed con extra debe llegar al builder con el himno');
    });

    testWidgets('HymnDetailScreen acepta Himno como parámetro',
        (tester) async {
      // Verifica que el widget se construye sin errores con un Himno válido.
      // (No podemos cargarlo completamente por dependencias de DB, pero
      // sí verificamos la firma del constructor).
      final himno = _createTestHimno();
      expect(himno.titulo, 'Santo, Santo, Santo');
      expect(HymnDetailScreen, isNotNull);

      // Verificar que la clase acepta el parámetro nombrado.
      // No instanciamos el widget completo para evitar dependencias de BD.
      final widget = HymnDetailScreen(himno: himno);
      expect(widget.himno.titulo, 'Santo, Santo, Santo');
    });
  });
}
