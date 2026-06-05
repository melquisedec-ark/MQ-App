import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mqapp/presentation/views_projection/providers/bible_appearance_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Tests para BibleAppearanceProvider
// ═══════════════════════════════════════════════════════════════

void main() {
  group('BibleAppearanceState', () {
    test('valores por defecto son papel y 1.0', () {
      const state = BibleAppearanceState();

      expect(state.theme, 'papel');
      expect(state.fontScale, 1.0);
    });

    test('copyWith cambia solo el tema', () {
      const state = BibleAppearanceState();
      final updated = state.copyWith(theme: 'noche');

      expect(updated.theme, 'noche');
      expect(updated.fontScale, 1.0); // sin cambios
    });

    test('copyWith cambia solo la escala', () {
      const state = BibleAppearanceState();
      final updated = state.copyWith(fontScale: 2.0);

      expect(updated.theme, 'papel'); // sin cambios
      expect(updated.fontScale, 2.0);
    });

    test('copyWith cambia ambos valores', () {
      const state = BibleAppearanceState();
      final updated = state.copyWith(theme: 'sepia', fontScale: 1.5);

      expect(updated.theme, 'sepia');
      expect(updated.fontScale, 1.5);
    });
  });

  group('BibleAppearanceNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    test('estado inicial es papel con escala 1.0', () {
      final state = container.read(bibleAppearanceProvider);

      expect(state.theme, 'papel');
      expect(state.fontScale, 1.0);
    });

    test('setTheme cambia el tema', () {
      container.read(bibleAppearanceProvider.notifier).setTheme('noche');

      final state = container.read(bibleAppearanceProvider);
      expect(state.theme, 'noche');
    });

    test('setTheme soporta todos los temas', () {
      final temas = ['papel', 'sepia', 'noche', 'dark', 'azulNoche', 'altoContraste'];
      final notifier = container.read(bibleAppearanceProvider.notifier);

      for (final tema in temas) {
        notifier.setTheme(tema);
        expect(container.read(bibleAppearanceProvider).theme, tema);
      }
    });

    test('setFontScale cambia la escala', () {
      container.read(bibleAppearanceProvider.notifier).setFontScale(2.0);

      final state = container.read(bibleAppearanceProvider);
      expect(state.fontScale, 2.0);
    });

    test('setFontScale clamp a mínimo 0.8', () {
      container.read(bibleAppearanceProvider.notifier).setFontScale(0.1);

      final state = container.read(bibleAppearanceProvider);
      expect(state.fontScale, 0.8);
    });

    test('setFontScale clamp a máximo 4.0', () {
      container.read(bibleAppearanceProvider.notifier).setFontScale(10.0);

      final state = container.read(bibleAppearanceProvider);
      expect(state.fontScale, 4.0);
    });

    test('setFontScale acepta valores en rango', () {
      final notifier = container.read(bibleAppearanceProvider.notifier);

      notifier.setFontScale(0.8);
      expect(container.read(bibleAppearanceProvider).fontScale, 0.8);

      notifier.setFontScale(4.0);
      expect(container.read(bibleAppearanceProvider).fontScale, 4.0);

      notifier.setFontScale(2.5);
      expect(container.read(bibleAppearanceProvider).fontScale, 2.5);
    });

    test('múltiples cambios se acumulan correctamente', () {
      final notifier = container.read(bibleAppearanceProvider.notifier);

      notifier.setTheme('dark');
      notifier.setFontScale(1.5);

      final state = container.read(bibleAppearanceProvider);
      expect(state.theme, 'dark');
      expect(state.fontScale, 1.5);

      // Cambiar solo el tema mantiene la escala
      notifier.setTheme('azulNoche');
      final state2 = container.read(bibleAppearanceProvider);
      expect(state2.theme, 'azulNoche');
      expect(state2.fontScale, 1.5);
    });
  });
}
