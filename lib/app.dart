import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/dual_mode_wrapper/himnario_dual_app.dart';

/// Widget raíz de la aplicación HimnarioID 2.0.
///
/// Envuelve [HimnarioDualApp] en un [ProviderScope] para que el
/// árbol de widgets tenga acceso a los providers de Riverpod.
class HimnarioApp extends StatelessWidget {
  const HimnarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: HimnarioDualApp(),
    );
  }
}
