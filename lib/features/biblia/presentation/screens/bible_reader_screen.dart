import 'package:flutter/material.dart';

/// Reader bíblico con 1 versículo a la vez (PLACEHOLDER temporal en Fase 1).
///
/// Implementación completa llega en la Fase 5.
class BibleReaderScreen extends StatelessWidget {
  const BibleReaderScreen({
    super.key,
    required this.libroId,
    required this.capitulo,
  });

  final int libroId;
  final int capitulo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('L$libroId C$capitulo')),
      body: const Center(child: Text('Bible Reader — pendiente')),
    );
  }
}
