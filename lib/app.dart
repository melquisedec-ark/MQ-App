import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/biblia/application/providers/biblia_config_provider.dart';
import 'presentation/dual_mode_wrapper/dual_mode_providers.dart';
import 'presentation/views_projection/controller/present_control_bar.dart';
import 'presentation/views_projection/providers/presentation_providers.dart';

/// Widget raíz de la aplicación MQ App 2.0.
///
/// Envuelve [MaterialApp.router] (configurado con [appRouter]) en un
/// [ProviderScope] para que el árbol de widgets tenga acceso a los
/// providers de Riverpod.
///
/// En modo presentación desktop, muestra [PresentControlBar] como overlay
/// inferior fijo sobre todas las pantallas, centralizando el control de
/// proyección en un solo lugar.
class MqApp extends ConsumerWidget {
  const MqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isPresenting = ref.watch(isPresentingProvider);
    final isDesktop = ref.watch(isDesktopModeProvider);
    return ProviderScope(
      child: MaterialApp.router(
        title: 'MQ App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: appRouter,
        builder: (context, child) {
          final safeChild = child ?? const SizedBox.shrink();
          // Altura estimada del PresentControlBar para reservar espacio
          // y evitar que el overlay obstruya contenido interactivo (últimos
          // libros, capítulos, versículos, botones inferiores).
          const controlBarHeight = 200.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Contenido principal con padding inferior cuando el overlay
              // está activo, para no tapar elementos interactivos del fondo.
              if (isPresenting && isDesktop)
                Padding(
                  padding: const EdgeInsets.only(bottom: controlBarHeight),
                  child: safeChild,
                )
              else
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
      ),
    );
  }
}
