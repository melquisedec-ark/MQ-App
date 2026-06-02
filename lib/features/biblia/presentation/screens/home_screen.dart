import 'package:flutter/material.dart';

/// Pantalla principal de MQ App (PLACEHOLDER temporal en Fase 1).
///
/// La implementación completa llega en la Fase 2. Por ahora es un
/// [Scaffold] mínimo para que el router compile.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MQ App')),
      body: const Center(child: Text('Home — pendiente de implementación')),
    );
  }
}
