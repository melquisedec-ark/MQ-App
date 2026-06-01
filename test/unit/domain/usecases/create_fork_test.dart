import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:himnario_id_2/core/enums/estrofa_tipo.dart';
import 'package:himnario_id_2/core/errors/failures.dart';
import 'package:himnario_id_2/domain/entities/arreglo_musical.dart';
import 'package:himnario_id_2/domain/entities/estrofa_arreglo.dart';
import 'package:himnario_id_2/domain/entities/estrofa.dart';
import 'package:himnario_id_2/domain/repositories/arreglo_repository.dart';
import 'package:himnario_id_2/domain/repositories/hymn_repository.dart';
import 'package:himnario_id_2/domain/usecases/arreglo/create_fork_usecase.dart';

// --------------------------------------------------
// Mocks
// --------------------------------------------------
class MockHymnRepository extends Mock implements HymnRepository {}

class MockArregloRepository extends Mock implements ArregloRepository {}

/// Fake para ArregloMusical usado como fallback en `registerFallbackValue`.
/// No se interactúa con él, solo se pasa como argumento.
class _FakeArregloMusical extends Fake implements ArregloMusical {}

/// Fake para List<EstrofaArreglo> usado como fallback en `registerFallbackValue`.
class _FakeEstrofaArregloList extends Fake implements List<EstrofaArreglo> {}

// --------------------------------------------------
// Test suite
// --------------------------------------------------
void main() {
  late MockHymnRepository mockHymnRepository;
  late MockArregloRepository mockArregloRepository;
  late CreateForkUseCase useCase;

  setUpAll(() {
    registerFallbackValue(_FakeArregloMusical());
    registerFallbackValue(_FakeEstrofaArregloList());
  });

  setUp(() {
    mockHymnRepository = MockHymnRepository();
    mockArregloRepository = MockArregloRepository();
    useCase = CreateForkUseCase(mockHymnRepository, mockArregloRepository);
  });

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------
  List<Estrofa> createOriginalStanzas() {
    return [
      const Estrofa(
        id: 1,
        versionPaisId: 10,
        tipo: EstrofaTipo.estrofa,
        orden: 1,
        contenido: '[G]Santo, [C]Santo, [G]Santo',
      ),
      const Estrofa(
        id: 2,
        versionPaisId: 10,
        tipo: EstrofaTipo.coro,
        orden: 2,
        contenido: '[G]Gloria a [D]ti, Señor',
      ),
    ];
  }

  group('CreateForkUseCase', () {
    group('creación exitosa', () {
      test('crea un fork correctamente con datos válidos', () async {
        // Arrange
        const versionPaisId = 10;
        const usuarioId = 1;
        const nombreArreglo = 'Mi Arreglo Personal';
        const tonalidadBase = 'C';

        final estrofasOriginales = createOriginalStanzas();
        final arregloCreado = ArregloMusical(
          id: 100,
          versionPaisId: versionPaisId,
          usuarioId: usuarioId,
          nombreArreglo: nombreArreglo,
          tonalidadBase: tonalidadBase,
          version: 1,
          estrofas: estrofasOriginales.asMap().entries.map((entry) {
            final estrofa = entry.value;
            return EstrofaArreglo(
              id: 0,
              arregloMusicalId: 0,
              tipo: estrofa.tipo,
              orden: estrofa.orden,
              contenido: estrofa.contenido,
            );
          }).toList(),
        );

        when(() => mockHymnRepository.getStanzas(versionPaisId))
            .thenAnswer((_) async => estrofasOriginales);
        when(() => mockArregloRepository.createArreglo(
              any(),
              any(),
            ),).thenAnswer((_) async => arregloCreado);

        // Act
        final result = await useCase.execute(
          versionPaisId: versionPaisId,
          usuarioId: usuarioId,
          nombreArreglo: nombreArreglo,
          tonalidadBase: tonalidadBase,
        );

        // Assert
        expect(result, equals(arregloCreado));
        expect(result.id, greaterThan(0));
        expect(result.nombreArreglo, nombreArreglo);
        expect(result.version, 1);
        verify(() => mockHymnRepository.getStanzas(versionPaisId)).called(1);
        verify(() => mockArregloRepository.createArreglo(any(), any())).called(1);
      });

      test('el arreglo creado copia las estrofas originales', () async {
        // Arrange
        const versionPaisId = 10;
        const usuarioId = 1;
        const nombreArreglo = 'Arreglo Copia';
        const tonalidadBase = 'D';

        final estrofasOriginales = createOriginalStanzas();
        final arregloCreado = ArregloMusical(
          id: 101,
          versionPaisId: versionPaisId,
          usuarioId: usuarioId,
          nombreArreglo: nombreArreglo,
          tonalidadBase: tonalidadBase,
          version: 1,
          estrofas: estrofasOriginales.asMap().entries.map((entry) {
            final estrofa = entry.value;
            return EstrofaArreglo(
              id: 0,
              arregloMusicalId: 0,
              tipo: estrofa.tipo,
              orden: estrofa.orden,
              contenido: estrofa.contenido,
            );
          }).toList(),
        );

        when(() => mockHymnRepository.getStanzas(versionPaisId))
            .thenAnswer((_) async => estrofasOriginales);
        when(() => mockArregloRepository.createArreglo(
              any(),
              any(),
            ),).thenAnswer((_) async => arregloCreado);

        // Act
        final result = await useCase.execute(
          versionPaisId: versionPaisId,
          usuarioId: usuarioId,
          nombreArreglo: nombreArreglo,
          tonalidadBase: tonalidadBase,
        );

        // Assert
        expect(result.estrofas.length, estrofasOriginales.length);
        expect(result.estrofas[0].contenido, estrofasOriginales[0].contenido);
        expect(result.estrofas[1].tipo, estrofasOriginales[1].tipo);
        expect(result.estrofas[0].orden, estrofasOriginales[0].orden);
      });
    });

    group('validaciones', () {
      test('lanza InvalidArgumentFailure si versionPaisId es 0', () async {
        expect(
          () => useCase.execute(
            versionPaisId: 0,
            usuarioId: 1,
            nombreArreglo: 'Test',
            tonalidadBase: 'C',
          ),
          throwsA(isA<InvalidArgumentFailure>()),
        );
        verifyNever(() => mockHymnRepository.getStanzas(any()));
        verifyNever(() => mockArregloRepository.createArreglo(any(), any()));
      });

      test('lanza InvalidArgumentFailure si versionPaisId es negativo', () async {
        expect(
          () => useCase.execute(
            versionPaisId: -1,
            usuarioId: 1,
            nombreArreglo: 'Test',
            tonalidadBase: 'C',
          ),
          throwsA(isA<InvalidArgumentFailure>()),
        );
      });

      test('lanza InvalidArgumentFailure si usuarioId es 0', () async {
        expect(
          () => useCase.execute(
            versionPaisId: 10,
            usuarioId: 0,
            nombreArreglo: 'Test',
            tonalidadBase: 'C',
          ),
          throwsA(isA<InvalidArgumentFailure>()),
        );
      });

      test('lanza InvalidArgumentFailure si usuarioId es negativo', () async {
        expect(
          () => useCase.execute(
            versionPaisId: 10,
            usuarioId: -5,
            nombreArreglo: 'Test',
            tonalidadBase: 'C',
          ),
          throwsA(isA<InvalidArgumentFailure>()),
        );
      });

      test('lanza InvalidArgumentFailure si nombreArreglo está vacío', () async {
        expect(
          () => useCase.execute(
            versionPaisId: 10,
            usuarioId: 1,
            nombreArreglo: '   ',
            tonalidadBase: 'C',
          ),
          throwsA(isA<InvalidArgumentFailure>()),
        );
      });

      test('lanza InvalidArgumentFailure si nombreArreglo es cadena vacía', () async {
        expect(
          () => useCase.execute(
            versionPaisId: 10,
            usuarioId: 1,
            nombreArreglo: '',
            tonalidadBase: 'C',
          ),
          throwsA(isA<InvalidArgumentFailure>()),
        );
      });
    });

    group('manejo de errores del repositorio', () {
      test('propaga error de HymnRepository.getStanzas', () async {
        // Arrange
        const versionPaisId = 10;
        when(() => mockHymnRepository.getStanzas(versionPaisId))
            .thenThrow(const DatabaseFailure('Error al obtener estrofas'));

        // Act & Assert
        expect(
          () => useCase.execute(
            versionPaisId: versionPaisId,
            usuarioId: 1,
            nombreArreglo: 'Test',
            tonalidadBase: 'C',
          ),
          throwsA(isA<DatabaseFailure>()),
        );
        verifyNever(() => mockArregloRepository.createArreglo(any(), any()));
      });

      test('propaga error de ArregloRepository.createArreglo', () async {
        // Arrange
        const versionPaisId = 10;
        when(() => mockHymnRepository.getStanzas(versionPaisId))
            .thenAnswer((_) async => createOriginalStanzas());
        when(() => mockArregloRepository.createArreglo(any(), any()))
            .thenThrow(const DatabaseFailure('Error al crear arreglo'));

        // Act & Assert
        expect(
          () => useCase.execute(
            versionPaisId: versionPaisId,
            usuarioId: 1,
            nombreArreglo: 'Test',
            tonalidadBase: 'C',
          ),
          throwsA(isA<DatabaseFailure>()),
        );
      });
    });
  });
}
