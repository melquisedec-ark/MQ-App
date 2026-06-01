import 'package:flutter_test/flutter_test.dart';

import 'package:himnario_id_2/core/errors/failures.dart';
import 'package:himnario_id_2/domain/usecases/transposicion/transpose_chords_usecase.dart';

/// Suite de tests para [TransposeChordsUseCase].
///
/// El transpositor es una función pura que no depende de repositorios,
/// por lo tanto no necesita mocks.
void main() {
  late TransposeChordsUseCase useCase;

  setUp(() {
    useCase = TransposeChordsUseCase();
  });

  group('TransposeChordsUseCase', () {
    group('transposición positiva', () {
      test('transpone +1 semitono correctamente (C -> C#)', () {
        // Arrange
        const content = '[C]Dios es [G]amor';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[C#]Dios es [G#]amor');
      });

      test('transpone +3 semitonos correctamente (C -> D#)', () {
        // Arrange
        const content = '[C]Dios es [G]amor';
        const semitones = 3;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[D#]Dios es [A#]amor');
      });

      test('transpone +5 semitonos correctamente (C -> F)', () {
        // Arrange
        const content = '[C]Dios es [G]amor';
        const semitones = 5;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[F]Dios es [C]amor');
      });

      test('transpone +6 semitonos (límite superior)', () {
        // Arrange
        const content = '[C]Dios es [G]amor';
        const semitones = 6;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[F#]Dios es [C#]amor');
      });
    });

    group('transposición negativa', () {
      test('transpone -1 semitono correctamente (G -> F#)', () {
        // Arrange
        const content = '[G]Dios es [C]amor';
        const semitones = -1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[F#]Dios es [B]amor');
      });

      test('transpone -3 semitonos correctamente (C -> A)', () {
        // Arrange
        const content = '[C]Dios es [G]amor';
        const semitones = -3;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[A]Dios es [E]amor');
      });

      test('transpone -6 semitonos (límite inferior)', () {
        // Arrange
        const content = '[C]Dios es [G]amor';
        const semitones = -6;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[F#]Dios es [C#]amor');
      });
    });

    group('transposición 0 (sin modificación)', () {
      test('transposición 0 retorna el mismo contenido', () {
        // Arrange
        const content = '[G]Dios es [C]amor';
        const semitones = 0;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, content);
      });

      test('transposición 0 con contenido vacío retorna vacío', () {
        // Arrange
        const content = '';
        const semitones = 0;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '');
      });
    });

    group('límites', () {
      test('lanza InvalidArgumentFailure si semitones > 6', () {
        // Arrange
        const content = '[C]test';
        const semitones = 7;

        // Act & Assert
        expect(
          () => useCase.execute(content, semitones),
          throwsA(isA<InvalidArgumentFailure>()),
        );
      });

      test('lanza InvalidArgumentFailure si semitones < -6', () {
        // Arrange
        const content = '[C]test';
        const semitones = -7;

        // Act & Assert
        expect(
          () => useCase.execute(content, semitones),
          throwsA(isA<InvalidArgumentFailure>()),
        );
      });

      test('+6 es válido (límite superior exacto)', () {
        // Arrange
        const content = '[C]test';
        const semitones = 6;

        // Act & Assert
        expect(
          () => useCase.execute(content, semitones),
          returnsNormally,
        );
      });

      test('-6 es válido (límite inferior exacto)', () {
        // Arrange
        const content = '[C]test';
        const semitones = -6;

        // Act & Assert
        expect(
          () => useCase.execute(content, semitones),
          returnsNormally,
        );
      });
    });

    group('acordes complejos', () {
      test('transpone acordes con séptima (G7 -> G#7)', () {
        // Arrange
        const content = '[G7]Señor [C7]Jesús';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[G#7]Señor [C#7]Jesús');
      });

      test('transpone acordes menores (Am -> A#m)', () {
        // Arrange
        const content = '[Am]Dios [Em]es amor';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[A#m]Dios [Fm]es amor');
      });

      test('transpone acordes suspendidos (Csus4 -> C#sus4)', () {
        // Arrange
        const content = '[Csus4]Dios [Gsus4]es amor';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[C#sus4]Dios [G#sus4]es amor');
      });

      test('transpone acordes disminuidos (Cdim -> C#dim)', () {
        // Arrange
        const content = '[Cdim]Dios [Gdim]es amor';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[C#dim]Dios [G#dim]es amor');
      });

      test('transpone acordes aumentados (Caug -> C#aug)', () {
        // Arrange
        const content = '[Caug]Dios [Gaug]es amor';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[C#aug]Dios [G#aug]es amor');
      });

      test('transpone acordes con séptima menor (Am7 -> A#m7)', () {
        // Arrange
        const content = '[Am7]Dios [Dm7]es amor';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[A#m7]Dios [D#m7]es amor');
      });

      test('transpone acordes con bajo alternado (C/E -> C#/F)', () {
        // Arrange
        const content = '[C/E]Dios [G/B]es amor';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[C#/F]Dios [G#/C]es amor');
      });

      test('transpone acordes con sostenidos (C#m -> Dm)', () {
        // Arrange
        const content = '[C#m]Dios [F#]es amor';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[Dm]Dios [G]es amor');
      });

      test('transpone mezcla de acordes simples y complejos', () {
        // Arrange
        const content = '[G]Canto [Am7]a ti [D7]Señor [Gsus4]Dios';
        const semitones = 1;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[G#]Canto [A#m7]a ti [D#7]Señor [G#sus4]Dios');
      });
    });

    group('casos borde', () {
      test('contenido sin acordes no se modifica', () {
        // Arrange
        const content = 'Dios es amor';
        const semitones = 3;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, content);
      });

      test('contenido vacío retorna vacío', () {
        // Arrange
        const content = '';
        const semitones = 5;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '');
      });

      test('contenido con solo acordes se transpone completamente', () {
        // Arrange
        const content = '[G][C][D]';
        const semitones = 2;

        // Act
        final result = useCase.execute(content, semitones);

        // Assert
        expect(result, '[A][D][E]');
      });
    });
  });
}
