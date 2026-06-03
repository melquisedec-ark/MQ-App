import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/widgets/verse_card.dart' show BibleReaderViewMode;

/// Modo de vista del lector bíblico.
///
/// - [BibleReaderViewMode.verse]   → vista por defecto (1 versículo + flechas).
/// - [BibleReaderViewMode.chapter] → capítulo completo en [ScrollablePositionedList].
final readerViewModeProvider =
    StateProvider<BibleReaderViewMode>((ref) => BibleReaderViewMode.verse);

/// Versículo al que debe hacer auto-scroll la vista de capítulo.
///
/// Se actualiza cuando el usuario navega con las flechas (en modo `verse`)
/// o toca un versículo (en modo `chapter`). Se **preserva** al alternar
/// entre [readerViewModeProvider] para no perder el contexto de lectura.
final currentVerseProvider = StateProvider<int>((ref) => 1);
