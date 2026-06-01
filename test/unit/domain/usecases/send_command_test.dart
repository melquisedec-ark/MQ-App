import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/core/errors/failures.dart';
import 'package:himnario_id_2/domain/repositories/control_repository.dart';
import 'package:himnario_id_2/domain/usecases/control/send_command_usecase.dart';

// --------------------------------------------------
// Mocks
// --------------------------------------------------
class MockControlRepository extends Mock implements ControlRepository {}

// --------------------------------------------------
// Test suite
// --------------------------------------------------
void main() {
  late MockControlRepository mockRepository;
  late SendCommandUseCase useCase;

  setUp(() {
    mockRepository = MockControlRepository();
    useCase = SendCommandUseCase(mockRepository);
  });

  group('SendCommandUseCase', () {
    group('nextStanza / prevStanza', () {
      test('nextStanza retorna true cuando se ejecuta exitosamente', () async {
        // Arrange
        when(() => mockRepository.sendNextStanza()).thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(ControlCommand.nextStanza);

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendNextStanza()).called(1);
      });

      test('prevStanza retorna true cuando se ejecuta exitosamente', () async {
        // Arrange
        when(() => mockRepository.sendPrevStanza()).thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(ControlCommand.prevStanza);

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendPrevStanza()).called(1);
      });
    });

    group('goToStanza', () {
      test('retorna true cuando se envía stanzaIndex válido', () async {
        // Arrange
        const stanzaIndex = 2;
        when(() => mockRepository.sendGoToStanza(stanzaIndex))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(
          ControlCommand.goToStanza,
          stanzaIndex: stanzaIndex,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendGoToStanza(stanzaIndex)).called(1);
      });

      test('lanza InvalidArgumentFailure si falta stanzaIndex', () async {
        // Act & Assert
        expect(
          () => useCase.execute(ControlCommand.goToStanza),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockRepository.sendGoToStanza(any()));
      });
    });

    group('blackout', () {
      test('blackout envía active=true', () async {
        // Arrange
        when(() => mockRepository.sendBlackout(true))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(ControlCommand.blackout);

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendBlackout(true)).called(1);
      });

      test('clearBlackout envía active=false', () async {
        // Arrange
        when(() => mockRepository.sendBlackout(false))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(ControlCommand.clearBlackout);

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendBlackout(false)).called(1);
      });
    });

    group('showHimno', () {
      test('retorna true cuando se envía himnoId válido', () async {
        // Arrange
        const himnoId = 42;
        when(() => mockRepository.sendShowHimno(himnoId))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(
          ControlCommand.showHimno,
          himnoId: himnoId,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendShowHimno(himnoId)).called(1);
      });

      test('lanza InvalidArgumentFailure si falta himnoId', () async {
        // Act & Assert
        expect(
          () => useCase.execute(ControlCommand.showHimno),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockRepository.sendShowHimno(any()));
      });
    });

    group('playAudio / stopAudio', () {
      test('playAudio retorna true', () async {
        // Arrange
        when(() => mockRepository.sendPlayAudio()).thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(ControlCommand.playAudio);

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendPlayAudio()).called(1);
      });

      test('stopAudio retorna true', () async {
        // Arrange
        when(() => mockRepository.sendStopAudio()).thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(ControlCommand.stopAudio);

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendStopAudio()).called(1);
      });
    });

    group('setConfig', () {
      test('retorna true cuando se envía configuración completa', () async {
        // Arrange
        const fondo = 'oscuro';
        const tamano = 52.0;
        const config = ConfigParams(fondo: fondo, tamano: tamano);
        when(() => mockRepository.sendSetConfig(fondo: fondo, tamano: tamano))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(
          ControlCommand.setConfig,
          config: config,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendSetConfig(fondo: fondo, tamano: tamano))
            .called(1);
      });

      test('retorna true cuando se envía solo fondo', () async {
        // Arrange
        const fondo = 'claro';
        const config = ConfigParams(fondo: fondo);
        when(() => mockRepository.sendSetConfig(fondo: fondo, tamano: any(named: 'tamano')))
            .thenAnswer((_) async => true);

        // Act
        final result = await useCase.execute(
          ControlCommand.setConfig,
          config: config,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockRepository.sendSetConfig(fondo: fondo, tamano: null))
            .called(1);
      });
    });

    group('manejo de errores', () {
      test('envuelve excepción genérica en NetworkFailure', () async {
        // Arrange
        when(() => mockRepository.sendNextStanza())
            .thenThrow(Exception('Connection refused'));

        // Act & Assert
        expect(
          () => useCase.execute(ControlCommand.nextStanza),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('propaga Failure directo sin envolver', () async {
        // Arrange
        when(() => mockRepository.sendNextStanza())
            .thenThrow(const NetworkFailure('Timeout'));

        // Act & Assert
        expect(
          () => useCase.execute(ControlCommand.nextStanza),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('propaga InvalidArgumentFailure sin envolver', () async {
        // Arrange
        when(() => mockRepository.sendNextStanza())
            .thenThrow(const InvalidArgumentFailure('Comando inválido'));

        // Act & Assert
        expect(
          () => useCase.execute(ControlCommand.nextStanza),
          throwsA(isA<InvalidArgumentFailure>()),
        );
      });
    });
  });
}
