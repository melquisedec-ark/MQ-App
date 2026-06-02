import 'package:flutter/material.dart';

/// Grid de capítulos (PLACEHOLDER temporal en Fase 1).
///
/// Implementación completa llega en la Fase 4.
class ChapterGridScreen extends StatelessWidget {
  const ChapterGridScreen({super.key, required this.libroId});

  final int libroId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Libro #$libroId')),
      body: const Center(child: Text('Chapter Grid — pendiente')),
    );
  }
}
