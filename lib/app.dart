import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/dual_mode_wrapper/mq_dual_app.dart';

/// Widget raíz de la aplicación MQ App 2.0.
///
/// Envuelve [MqDualApp] en un [ProviderScope] para que el
/// árbol de widgets tenga acceso a los providers de Riverpod.
class MqApp extends StatelessWidget {
  const MqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: MqDualApp(),
    );
  }
}
