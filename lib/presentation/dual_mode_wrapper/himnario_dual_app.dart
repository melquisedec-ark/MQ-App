import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/himno.dart';
import '../../core/network/connection_state.dart';
import '../../core/theme/app_theme.dart';
import '../shared_widgets/fullscreen_handler.dart';
import '../shared_widgets/theme_mode_toggle_button.dart';
import '../shared_widgets/providers/theme_mode_provider.dart';
import '../views_personal/dashboard/home_screen.dart';
import '../views_personal/dashboard/present_button.dart';
import '../views_personal/hymn_scroll/arrangement_editor_screen.dart';
import '../views_personal/hymn_scroll/arrangement_list_screen.dart';
import '../views_personal/hymn_scroll/hymn_detail_screen.dart';
import '../views_projection/controller/live_control_screen.dart';
import '../views_projection/controller/present_control_bar.dart';
import '../views_projection/providers/connection_providers.dart';
import '../views_projection/providers/presentation_providers.dart';
import 'device_mode.dart';
import 'device_switch.dart';
import 'dual_mode_providers.dart';

/// Widget raíz que renderiza la aplicación según el modo (PC/Celular).
///
/// [HomeScreen] es la base SIEMPRE. En modo desktop + presentación activa,
/// se superpone [PresentControlBar]. El modo Receptor (StandbyScreen) se
/// maneja dentro de [HomeScreen] según [connectionRoleProvider].
///
/// Preserva las rutas de navegación existentes:
/// - `/hymn-detail` → [HymnDetailScreen]
/// - `/live-control` → [LiveControlScreen]
/// - `/arrangement-editor` → [ArrangementEditorScreen]
class HimnarioDualApp extends ConsumerWidget {
  const HimnarioDualApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(deviceModeProvider);
    final isDesktop = mode == DeviceMode.desktop;
    final isPresenting = ref.watch(isPresentingProvider);
    final themeMode = ref.watch(themeModeProvider);
    final role = ref.watch(connectionRoleProvider);

    return FullscreenHandler(
      child: MaterialApp(
        title: 'MQ App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,

        // Rutas de la aplicación
        routes: {
          '/hymn-detail': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args is! Himno) return const HomeScreen();
            return HymnDetailScreen(himno: args);
          },
          '/live-control': (context) {
            return const LiveControlScreen();
          },
          '/arrangement-editor': (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args is Himno) {
              return ArrangementEditorScreen(himno: args);
            } else if (args is int) {
              return ArrangementEditorScreen(arregloId: args);
            }
            return const HomeScreen();
          },
          '/arrangement-list': (context) => const ArrangementListScreen(),
        },

        // Punto de entrada basado en el modo dual y estado de presentación
        // HomeScreen es SIEMPRE la base (phone, desktop, desktop+presenting).
        // El overlay de control (PresentControlBar) se muestra solo cuando
        // el dispositivo está en modo desktop y el modo presentación activo.
        // StandbyScreen se maneja DENTRO de HomeScreen según ConnectionRole.
        home: Stack(
          children: [
            const HomeScreen(),
            if (isDesktop && isPresenting)
              const PresentControlBar(),
            const DeviceSwitch(),
            if (role != ConnectionRole.receiver)
              const _BottomRightButtons(),
          ],
        ),
      ),
    );
  }
}

/// Botones flotantes en la esquina inferior derecha.
///
/// Contiene el toggle de tema y el botón Presentar, posicionados
/// con 5px de separación para evitar superposición.
class _BottomRightButtons extends ConsumerWidget {
  const _BottomRightButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ref.watch(deviceModeProvider) == DeviceMode.desktop;
    final isPresenting = ref.watch(isPresentingProvider);

    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const ThemeModeToggleButton(),
          if (isDesktop && !isPresenting) ...[
            const SizedBox(height: 5),
            const PresentButton(),
          ],
        ],
      ),
    );
  }
}
