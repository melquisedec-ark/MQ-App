import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/core/errors/failures.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/domain/repositories/hymn_repository.dart';
import 'package:himnario_id_2/domain/usecases/himno/search_hymns_usecase.dart';

// --------------------------------------------------
// Mocks
// --------------------------------------------------
class MockHymnRepository extends Mock implements HymnRepository {}

// --------------------------------------------------
// Test suite
// --------------------------------------------------
void main() {
  late MockHymnRepository mockRepository;
  late SearchHymnsUseCase useCase;

  setUp(() {
    mockRepository = MockHymnRepository();
    useCase = SearchHymnsUseCase(mockRepository);
  });

  // ------------------------------------------------------------------
  // Helper: create a sample Himno
  // ------------------------------------------------------------------
  Himno createHimno({
    int id = 1,
    String titulo = 'Santo, Santo, Santo',
    HimnoTipo tipo = HimnoTipo.oficial,
  }) {
    return Himno(id: id, titulo: titulo, tipo: tipo);
  }

  group('SearchHymnsUseCase', () {
    group('búsqueda por texto', () {
      test('retorna resultados cuando el texto coincide', () async {
        // Arrange
        const query = 'Santo';
        final expected = [
          createHimno(id: 1, titulo: 'Santo, Santo, Santo'),
          createHimno(id: 2, titulo: 'Santo Dios'),
        ];
        when(() => mockRepository.searchHymns(query, tipo: any(named: 'tipo')))
            .thenAnswer((_) async => expected);

        // Act
        final result = await useCase.execute(query);

        // Assert
        expect(result, equals(expected));
        expect(result.length, 2);
        verify(() => mockRepository.searchHymns(query, tipo: null)).called(1);
      });

      test('retorna lista vacía cuando no hay resultados', () async {
        // Arrange
        const query = 'xyzNoExiste';
        when(() => mockRepository.searchHymns(query, tipo: any(named: 'tipo')))
            .thenAnswer((_) async => []);

        // Act
        final result = await useCase.execute(query);

        // Assert
        expect(result, isEmpty);
        verify(() => mockRepository.searchHymns(query, tipo: null)).called(1);
      });
    });

    group('búsqueda por tipo', () {
      test('filtra por tipo Oficial', () async {
        // Arrange
        const query = 'Santo';
        const tipo = HimnoTipo.oficial;
        final expected = [
          createHimno(id: 1, titulo: 'Santo, Santo, Santo', tipo: tipo),
          createHimno(id: 3, titulo: 'Santo Espíritu', tipo: tipo),
        ];
        when(() => mockRepository.searchHymns(query, tipo: tipo))
            .thenAnswer((_) async => expected);

        // Act
        final result = await useCase.execute(query, tipo: tipo);

        // Assert
        expect(result, equals(expected));
        expect(result.every((h) => h.tipo == tipo), isTrue);
        verify(() => mockRepository.searchHymns(query, tipo: tipo)).called(1);
      });

      test('filtra por tipo Inspirada', () async {
        // Arrange
        const query = 'Amor';
        const tipo = HimnoTipo.inspirada;
        final expected = [
          createHimno(id: 4, titulo: 'Amor Incomparable', tipo: tipo),
        ];
        when(() => mockRepository.searchHymns(query, tipo: tipo))
            .thenAnswer((_) async => expected);

        // Act
        final result = await useCase.execute(query, tipo: tipo);

        // Assert
        expect(result, equals(expected));
        verify(() => mockRepository.searchHymns(query, tipo: tipo)).called(1);
      });

      test('filtra por tipo Convención', () async {
        // Arrange
        const query = 'Himno';
        const tipo = HimnoTipo.convencion;
        final expected = [
          createHimno(id: 5, titulo: 'Himno de la Convención', tipo: tipo),
        ];
        when(() => mockRepository.searchHymns(query, tipo: tipo))
            .thenAnswer((_) async => expected);

        // Act
        final result = await useCase.execute(query, tipo: tipo);

        // Assert
        expect(result, equals(expected));
        verify(() => mockRepository.searchHymns(query, tipo: tipo)).called(1);
      });
    });

    group('validaciones', () {
      test('lanza InvalidArgumentFailure si query vacío y sin tipo', () async {
        // Arrange
        const query = '   ';

        // Act & Assert
        expect(
          () => useCase.execute(query),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockRepository.searchHymns(any(), tipo: any(named: 'tipo')));
      });

      test('no lanza si query vacío pero tipo está presente', () async {
        // Arrange
        const query = '   ';
        const tipo = HimnoTipo.oficial;
        when(() => mockRepository.searchHymns('', tipo: tipo))
            .thenAnswer((_) async => []);

        // Act
        final result = await useCase.execute(query, tipo: tipo);

        // Assert
        expect(result, isEmpty);
        verify(() => mockRepository.searchHymns('', tipo: tipo)).called(1);
      });

      test('no lanza si tipo es null pero query tiene texto', () async {
        // Arrange
        const query = 'Santo';
        when(() => mockRepository.searchHymns(query, tipo: any(named: 'tipo')))
            .thenAnswer((_) async => []);

        // Act & Assert
        await expectLater(
          useCase.execute(query),
          completes,
        );
      });
    });

    group('manejo de errores del repositorio', () {
      test('propaga DatabaseFailure del repositorio', () async {
        // Arrange
        const query = 'Santo';
        when(() => mockRepository.searchHymns(query, tipo: any(named: 'tipo')))
            .thenThrow(const DatabaseFailure('Error de BD'));

        // Act & Assert
        expect(
          () => useCase.execute(query),
          throwsA(isA<DatabaseFailure>()),
        );
      });

      test('recorta espacios del query antes de buscar', () async {
        // Arrange
        const query = '  Santo  ';
        when(() => mockRepository.searchHymns('Santo', tipo: any(named: 'tipo')))
            .thenAnswer((_) async => []);

        // Act
        await useCase.execute(query);

        // Assert
        verify(() => mockRepository.searchHymns('Santo', tipo: null)).called(1);
      });
    });
  });
}
