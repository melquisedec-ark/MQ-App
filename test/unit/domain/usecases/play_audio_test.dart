import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/core/errors/failures.dart';
import 'package:himnario_id_2/domain/entities/pista_audio.dart';
import 'package:himnario_id_2/domain/repositories/audio_repository.dart';
import 'package:himnario_id_2/domain/usecases/audio/play_audio_usecase.dart';

// --------------------------------------------------
// Mocks
// --------------------------------------------------
class MockAudioRepository extends Mock implements AudioRepository {}

// --------------------------------------------------
// Test suite
// --------------------------------------------------
void main() {
  late MockAudioRepository mockRepository;
  late PlayAudioUseCase useCase;

  setUp(() {
    mockRepository = MockAudioRepository();
    useCase = PlayAudioUseCase(mockRepository);
  });

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  PistaAudio createTrack({
    int id = 1,
    int himnoId = 1,
    String ruta = 'assets/audio/himno_01.mp3',
  }) {
    return PistaAudio(
      id: id,
      himnoId: himnoId,
      rutaArchivo: ruta,
      descripcion: 'Pista de prueba',
      duracionSegundos: 180.0,
      formato: 'mp3',
    );
  }

  group('PlayAudioUseCase', () {
    group('getTracks', () {
      test('retorna lista de pistas para un himno existente', () async {
        // Arrange
        const himnoId = 1;
        final expected = [
          createTrack(id: 1, himnoId: himnoId),
          createTrack(id: 2, himnoId: himnoId, ruta: 'assets/audio/himno_01_instrumental.mp3'),
        ];
        when(() => mockRepository.getByHimno(himnoId))
            .thenAnswer((_) async => expected);

        // Act
        final result = await useCase.getTracks(himnoId);

        // Assert
        expect(result, equals(expected));
        expect(result.length, 2);
        expect(result.every((t) => t.himnoId == himnoId), isTrue);
        verify(() => mockRepository.getByHimno(himnoId)).called(1);
      });

      test('retorna lista vacía si el himno no tiene pistas', () async {
        // Arrange
        const himnoId = 99;
        when(() => mockRepository.getByHimno(himnoId))
            .thenAnswer((_) async => []);

        // Act
        final result = await useCase.getTracks(himnoId);

        // Assert
        expect(result, isEmpty);
        verify(() => mockRepository.getByHimno(himnoId)).called(1);
      });

      test('lanza InvalidArgumentFailure si himnoId es 0', () async {
        // Act & Assert
        expect(
          () => useCase.getTracks(0),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockRepository.getByHimno(any()));
      });

      test('lanza InvalidArgumentFailure si himnoId es negativo', () async {
        expect(
          () => useCase.getTracks(-1),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockRepository.getByHimno(any()));
      });
    });

    group('play', () {
      test('inicia reproducción con pistaId válido', () async {
        // Arrange
        const pistaId = 1;
        when(() => mockRepository.play(pistaId))
            .thenAnswer((_) async {});

        // Act
        await useCase.play(pistaId);

        // Assert
        verify(() => mockRepository.play(pistaId)).called(1);
      });

      test('lanza InvalidArgumentFailure si pistaId es 0', () async {
        expect(
          () => useCase.play(0),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockRepository.play(any()));
      });

      test('lanza InvalidArgumentFailure si pistaId es negativo', () async {
        expect(
          () => useCase.play(-3),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockRepository.play(any()));
      });
    });

    group('stop', () {
      test('detiene la reproducción actual', () async {
        // Arrange
        when(() => mockRepository.stop()).thenAnswer((_) async {});

        // Act
        await useCase.stop();

        // Assert
        verify(() => mockRepository.stop()).called(1);
      });

      test('puede llamarse múltiples veces sin error', () async {
        // Arrange
        when(() => mockRepository.stop()).thenAnswer((_) async {});

        // Act
        await useCase.stop();
        await useCase.stop();
        await useCase.stop();

        // Assert
        verify(() => mockRepository.stop()).called(3);
      });
    });

    group('manejo de errores', () {
      test('propaga AudioFailure del repositorio en play', () async {
        // Arrange
        const pistaId = 1;
        when(() => mockRepository.play(pistaId))
            .thenThrow(const AudioFailure('Error al reproducir'));

        // Act & Assert
        expect(
          () => useCase.play(pistaId),
          throwsA(isA<AudioFailure>()),
        );
      });

      test('propaga DatabaseFailure del repositorio en getTracks', () async {
        // Arrange
        const himnoId = 1;
        when(() => mockRepository.getByHimno(himnoId))
            .thenThrow(const DatabaseFailure('Error de BD'));

        // Act & Assert
        expect(
          () => useCase.getTracks(himnoId),
          throwsA(isA<DatabaseFailure>()),
        );
      });

      test('propaga cualquier error del repositorio en stop', () async {
        // Arrange
        when(() => mockRepository.stop())
            .thenThrow(Exception('Error inesperado'));

        // Act & Assert
        expect(
          () => useCase.stop(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
