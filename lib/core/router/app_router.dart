import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/himno.dart';
import '../../features/biblia/presentation/screens/bible_reader_screen.dart';
import '../../features/biblia/presentation/screens/book_selector_screen.dart';
import '../../features/biblia/presentation/screens/chapter_grid_screen.dart';
import '../../features/biblia/presentation/screens/home_screen.dart';
import '../../features/biblia/presentation/screens/search_screen.dart';
import '../../features/biblia/presentation/screens/settings_screen.dart';
import '../../features/biblia/presentation/screens/about_screen.dart';
import '../../features/himnario/presentation/screens/admin_himnario_screen.dart';
import '../../presentation/views_personal/dashboard/home_screen.dart' as himnario;
import '../../presentation/views_personal/hymn_scroll/hymn_detail_screen.dart';
import '../../presentation/views_projection/controller/widgets/discover_display_sheet.dart';

/// Router principal de la aplicación MQ App v1.0.
///
/// Configurado con [GoRouter] (paquete `go_router ^14.6.0`) para soportar
/// deep links, rutas anidadas y transición nativa entre módulos.
///
/// ## Estructura de rutas
///
/// - `/`            → [HomeScreen] (hub Biblia + Himnario, con versículo aleatorio)
/// - `/biblia`      → [BookSelectorScreen] (selector de libros con 5 tabs)
/// - `/biblia/libro/:libroId`             → [ChapterGridScreen]
/// - `/biblia/libro/:libroId/capitulo/:capitulo` → [BibleReaderScreen]
/// - `/biblia/search`                     → [SearchScreen]
/// - `/himnario`    → himnario.HomeScreen (lista A-Z de himnos, módulo HimnarioID 2.0)
/// - `/config`      → [SettingsScreen] (configuración)
/// - `/connect`     → [DiscoverDisplaySheet] (mDNS, modo emisor/receptor)
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        // Biblia
        GoRoute(
          path: 'biblia',
          name: 'biblia',
          builder: (BuildContext context, GoRouterState state) {
            return const BookSelectorScreen();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'search',
              name: 'biblia_search',
              builder: (BuildContext context, GoRouterState state) {
                return const SearchScreen();
              },
            ),
            GoRoute(
              path: 'libro/:libroId',
              name: 'biblia_libro',
              builder: (BuildContext context, GoRouterState state) {
                final libroId =
                    int.parse(state.pathParameters['libroId']!);
                return ChapterGridScreen(libroId: libroId);
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'capitulo/:capitulo',
                  name: 'biblia_reader',
                  builder: (BuildContext context, GoRouterState state) {
                    final libroId =
                        int.parse(state.pathParameters['libroId']!);
                    final capitulo =
                        int.parse(state.pathParameters['capitulo']!);
                    return BibleReaderScreen(
                      libroId: libroId,
                      capitulo: capitulo,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Himnario (módulo HimnarioID 2.0 reusado)
        GoRoute(
          path: 'himnario',
          name: 'himnario',
          builder: (BuildContext context, GoRouterState state) {
            return const himnario.HomeScreen();
          },
          routes: <RouteBase>[
            // B4: ruta hymn-detail antes faltaba en go_router; antes el
            // Navigator.pushNamed('/hymn-detail') fallaba silenciosamente
            // porque la ruta solo existía en mq_dual_app.dart (código muerto).
            GoRoute(
              path: 'detalle',
              name: 'hymn-detail',
              builder: (BuildContext context, GoRouterState state) {
                final himno = state.extra;
                if (himno is! Himno) {
                  // Fallback: si no llega el himno, vuelve al himnario.
                  return const himnario.HomeScreen();
                }
                return HymnDetailScreen(himno: himno);
              },
            ),
          ],
        ),

        // Configuración
        GoRoute(
          path: 'config',
          name: 'config',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),

        // Conectar (mDNS, modo emisor/receptor)
        GoRoute(
          path: 'connect',
          name: 'connect',
          builder: (BuildContext context, GoRouterState state) {
            // Devolvemos el sheet como pantalla completa. Al cerrarse
            // (back o tap fuera), go_router hace pop automático.
            return const _ConnectScreen();
          },
        ),

        // Acerca de (D7)
        GoRoute(
          path: 'acerca-de',
          name: 'about',
          builder: (BuildContext context, GoRouterState state) {
            return const AboutScreen();
          },
        ),

        // Administrar himnario (D8): himnos + catálogos unificados.
        GoRoute(
          path: 'administrar-himnario',
          name: 'hymn-admin',
          builder: (BuildContext context, GoRouterState state) {
            return const AdminHimnarioScreen();
          },
        ),
      ],
    ),
  ],
);

/// Pantalla wrapper para el sheet de descubrimiento mDNS.
///
/// El wireframe 01 §6 lo define como un bottom sheet, pero en `go_router`
/// necesitamos una pantalla completa. Mostramos un [Scaffold] con un
/// [DiscoverDisplaySheet] embebido y botón "atrás" para cerrarla.
class _ConnectScreen extends StatelessWidget {
  const _ConnectScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar display'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Atrás',
        ),
      ),
      body: const DiscoverDisplaySheet(),
    );
  }
}
