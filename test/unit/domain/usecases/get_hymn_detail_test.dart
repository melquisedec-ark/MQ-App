import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/core/errors/failures.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/domain/entities/version_pais.dart';
import 'package:himnario_id_2/domain/entities/estrofa.dart';
import 'package:himnario_id_2/domain/entities/categoria.dart';
import 'package:himnario_id_2/core/enums/estrofa_tipo.dart';
import 'package:himnario_id_2/domain/repositories/hymn_repository.dart';
import 'package:himnario_id_2/domain/usecases/himno/get_hymn_detail_usecase.dart';

// --------------------------------------------------
// Mocks
// --------------------------------------------------
class MockHymnRepository extends Mock implements HymnRepository {}

// --------------------------------------------------
// Test suite
// --------------------------------------------------
void main() {
  late MockHymnRepository mockRepository;
  late GetHymnDetailUseCase useCase;

  setUp(() {
    mockRepository = MockHymnRepository();
    useCase = GetHymnDetailUseCase(mockRepository);
  });

  // ------------------------------------------------------------------
  // Helper: create a full Himno with versions, stanzas, categories
  // ------------------------------------------------------------------
  Himno createFullHimno({int id = 1}) {
    return Himno(
      id: id,
      titulo: 'Santo, Santo, Santo',
      numero: 1,
      tipo: HimnoTipo.oficial,
      versiones: [
        VersionPais(
          id: 10,
          himnoId: id,
          paisId: 1, paisNombre: 'México', paisCodigo: 'MX',
          tonalidadOriginal: 'C',
          estrofas: [
            const Estrofa(
              id: 100,
              versionPaisId: 10,
              tipo: EstrofaTipo.estrofa,
              orden: 1,
              contenido: '[G]Santo, [C]Santo, [G]Santo',
            ),
            const Estrofa(
              id: 101,
              versionPaisId: 10,
              tipo: EstrofaTipo.coro,
              orden: 2,
              contenido: '[G]Gloria a [D]ti, Señor',
            ),
          ],
        ),
      ],
      categorias: [
        const Categoria(id: 1, nombre: 'Alabanza'),
      ],
    );
  }

  group('GetHymnDetailUseCase', () {
    group('himno existente', () {
      test('retorna detalle completo cuando el himno existe', () async {
        // Arrange
        const himnoId = 1;
        final expected = createFullHimno(id: himnoId);

        when(() => mockRepository.getHymnById(himnoId))
            .thenAnswer((_) async => expected);

        // Act
        final result = await useCase.execute(himnoId);

        // Assert
        expect(result, equals(expected));
        expect(result.id, himnoId);
        expect(result.titulo, 'Santo, Santo, Santo');
        expect(result.tipo, HimnoTipo.oficial);
        expect(result.versiones, isNotEmpty);
        expect(result.versiones.first.estrofas.length, 2);
        expect(result.categorias?.first.nombre, 'Alabanza');
        verify(() => mockRepository.getHymnById(himnoId)).called(1);
      });

      test('retorna himno con número opcional nulo', () async {
        // Arrange
        const himnoId = 2;
        const himnoSinNumero = Himno(
          id: himnoId,
          titulo: 'Himno sin número',
          tipo: HimnoTipo.inspirada,
        );

        when(() => mockRepository.getHymnById(himnoId))
            .thenAnswer((_) async => himnoSinNumero);

        // Act
        final result = await useCase.execute(himnoId);

        // Assert
        expect(result.id, himnoId);
        expect(result.numero, isNull);
        expect(result.tipo, HimnoTipo.inspirada);
      });

      test('retorna himno sin versiones', () async {
        // Arrange
        const himnoId = 3;
        const himnoSinVersiones = Himno(
          id: himnoId,
          titulo: 'Himno sin versiones',
          tipo: HimnoTipo.oficial,
        );

        when(() => mockRepository.getHymnById(himnoId))
            .thenAnswer((_) async => himnoSinVersiones);

        // Act
        final result = await useCase.execute(himnoId);

        // Assert
        expect(result.versiones, isEmpty);
        expect(result.primaryVersionPaisId, -1);
      });
    });

    group('himno no existente', () {
      test('lanza NotFoundFailure cuando el himno no existe', () async {
        // Arrange
        const himnoId = 999;
        when(() => mockRepository.getHymnById(himnoId))
            .thenThrow(const NotFoundFailure('Himno no encontrado'));

        // Act & Assert
        expect(
          () => useCase.execute(himnoId),
          throwsA(isA<NotFoundFailure>()),
        );
        verify(() => mockRepository.getHymnById(himnoId)).called(1);
      });
    });

    group('validaciones', () {
      test('lanza InvalidArgumentFailure si ID es 0', () async {
        // Act & Assert
        expect(
          () => useCase.execute(0),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockRepository.getHymnById(any()));
      });

      test('lanza InvalidArgumentFailure si ID es negativo', () async {
        // Act & Assert
        expect(
          () => useCase.execute(-5),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockRepository.getHymnById(any()));
      });
    });

    group('manejo de errores del repositorio', () {
      test('propaga DatabaseFailure del repositorio', () async {
        // Arrange
        const himnoId = 1;
        when(() => mockRepository.getHymnById(himnoId))
            .thenThrow(const DatabaseFailure('Error de conexión a BD'));

        // Act & Assert
        expect(
          () => useCase.execute(himnoId),
          throwsA(isA<DatabaseFailure>()),
        );
      });

      test('propaga cualquier Failure del repositorio', () async {
        // Arrange
        const himnoId = 1;
        when(() => mockRepository.getHymnById(himnoId))
            .thenThrow(const NetworkFailure('Error de red'));

        // Act & Assert
        expect(
          () => useCase.execute(himnoId),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });
  });
}
