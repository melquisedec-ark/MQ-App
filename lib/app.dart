import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/shared_widgets/providers/theme_mode_provider.dart';

/// Widget raíz de la aplicación MQ App 2.0.
///
/// Envuelve [MaterialApp.router] (configurado con [appRouter]) en un
/// [ProviderScope] para que el árbol de widgets tenga acceso a los
/// providers de Riverpod.
class MqApp extends ConsumerWidget {
  const MqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return ProviderScope(
      child: MaterialApp.router(
        title: 'MQ App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
