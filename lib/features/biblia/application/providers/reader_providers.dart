import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/biblia_config_repository.dart';
import '../../presentation/widgets/verse_card.dart' show BibleReaderViewMode;
import 'biblia_config_provider.dart';

/// Modo de vista del lector bíblico.
///
/// Hidrata desde BD; las actualizaciones se persisten automáticamente
/// vía [setViewMode]. Sigue el mismo patrón que [themeModeProvider].
final readerViewModeProvider =
    StateNotifierProvider<ReaderViewModeNotifier, BibleReaderViewMode>(
  (ref) => ReaderViewModeNotifier(ref),
);

/// Notifier que persiste [BibleReaderViewMode] en `biblia.db`.
///
/// - Default: [BibleReaderViewMode.chapter] (modo scroll).
/// - Se hidrata desde [BibliaConfigKeys.readerViewMode] al iniciar.
/// - Cada cambio se persiste con [BibliaConfigRepository.set].
class ReaderViewModeNotifier extends StateNotifier<BibleReaderViewMode> {
  final Ref _ref;

  ReaderViewModeNotifier(this._ref) : super(BibleReaderViewMode.chapter) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      final raw = await repo.get(
        BibliaConfigKeys.readerViewMode,
        defaultValue: 'chapter',
      );
      state = _parseMode(raw);
    } catch (_) {
      // Mantener default (chapter)
    }
  }

  /// Cambia el modo de vista y lo persiste en BD.
  Future<void> setViewMode(BibleReaderViewMode mode) async {
    state = mode;
    try {
      final repo = _ref.read(bibliaConfigRepositoryProvider);
      await repo.set(BibliaConfigKeys.readerViewMode, _modeName(mode));
    } catch (_) {
      // Silent fail; el state local ya quedó actualizado
    }
  }

  BibleReaderViewMode _parseMode(String value) {
    switch (value) {
      case 'chapter':
        return BibleReaderViewMode.chapter;
      default:
        return BibleReaderViewMode.verse;
    }
  }

  String _modeName(BibleReaderViewMode mode) {
    switch (mode) {
      case BibleReaderViewMode.chapter:
        return 'chapter';
      case BibleReaderViewMode.verse:
        return 'verse';
    }
  }
}

/// Versículo al que debe hacer auto-scroll la vista de capítulo.
///
/// Se actualiza cuando el usuario navega con las flechas (en modo `verse`)
/// o toca un versículo (en modo `chapter`). Se **preserva** al alternar
/// entre [readerViewModeProvider] para no perder el contexto de lectura.
final currentVerseProvider = StateProvider<int>((ref) => 1);
