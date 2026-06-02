import 'package:flutter/material.dart';

/// Selector de libros con 5 tabs (PLACEHOLDER temporal en Fase 1).
///
/// Implementación completa llega en la Fase 3.
class BookSelectorScreen extends StatelessWidget {
  const BookSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biblia')),
      body: const Center(child: Text('Book Selector — pendiente')),
    );
  }
}
