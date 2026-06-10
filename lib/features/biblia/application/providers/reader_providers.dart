import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/biblia_config_repository.dart';
import '../../presentation/widgets/verse_card.dart' show BibleReaderViewMode;
import 'biblia_config_provider.dart';
import 'current_libro_provider.dart';

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
///
/// Usa el flag [_hydrated] para evitar que la carga asíncrona desde BD
/// sobrescriba un cambio que el usuario haya hecho mientras tanto
/// (race condition reportada por @arqui en auditoría v1.0.3).
class ReaderViewModeNotifier extends StateNotifier<BibleReaderViewMode> {
  final Ref _ref;
  bool _hydrated = false;

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
      if (!_hydrated) {
        _hydrated = true;
        state = _parseMode(raw);
      }
    } catch (_) {
      _hydrated = true;
      // Mantener default (chapter)
    }
  }

  /// Cambia el modo de vista y lo persiste en BD.
  Future<void> setViewMode(BibleReaderViewMode mode) async {
    state = mode;
    _hydrated = true;
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

/// Composite key that changes on any (libroId, capitulo) tuple change.
///
/// Used to detect chapter/book transitions for auto-sync to the projection
/// window. Emits a string like `"42:3"` (libroId:capitulo).
final currentBibleAnchorProvider = Provider<String>((ref) {
  final libroId = ref.watch(currentLibroIdProvider) ?? 0;
  final capitulo = ref.watch(currentCapituloProvider) ?? 0;
  return '$libroId:$capitulo';
});
