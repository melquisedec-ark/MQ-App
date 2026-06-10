import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mqapp/core/window_manager/window_providers.dart';
import 'package:mqapp/core/window_manager/window_service.dart';
import 'package:mqapp/data/datasources/remote/grpc_display_server.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/data/models/biblia_version.dart';
import 'package:mqapp/features/biblia/data/models/capitulo.dart';
import 'package:mqapp/features/biblia/data/models/libro.dart';
import 'package:mqapp/features/biblia/data/models/versiculo.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/proto/generated/hymn_control.pbgrpc.dart';

// ── Mocks ────────────────────────────────────────────────────────

class MockWindowService extends Mock implements WindowService {}
class MockBibliaRepository extends Mock implements BibliaRepository {}
class MockFavoritosRepository extends Mock implements FavoritosRepository {}

// ── Helpers ────────────────────────────────────────────────────────

ProviderContainer createTestContainer({
  required MockWindowService windowService,
  required MockBibliaRepository bibleRepo,
  required MockFavoritosRepository favoritosRepo,
}) {
  return ProviderContainer(
    overrides: [
      windowServiceProvider.overrideWithValue(windowService),
      bibliaRepositoryProvider.overrideWithValue(bibleRepo),
      favoritosRepositoryProvider.overrideWithValue(favoritosRepo),
    ],
  );
}

/// Datos bíblicos de prueba.
class TestBibleData {
  static final version = BibliaVersion(
    id: 1, nombre: 'Reina-Valera 1909', abreviatura: 'RVR1909',
    idioma: 'es', activa: true,
  );

  static final libro = Libro(
    id: 1, versionId: 1, nombre: 'Génesis', abreviatura: 'Gn',
    testamento: Testamento.at, numero: 1, totalCapitulos: 50,
  );

  static final libroExodo = Libro(
    id: 2, versionId: 1, nombre: 'Éxodo', abreviatura: 'Ex',
    testamento: Testamento.at, numero: 2, totalCapitulos: 40,
  );

  static Capitulo capitulo({int totalVersiculos = 5, int numero = 1}) =>
      Capitulo(id: numero, libroId: 1, numero: numero, totalVersiculos: totalVersiculos);

  static Capitulo capitulo2({int totalVersiculos = 3}) =>
      Capitulo(id: 10, libroId: 1, numero: 2, totalVersiculos: totalVersiculos);

  static List<Versiculo> versiculos({int count = 5}) => List.generate(
        count,
        (i) => Versiculo(id: i + 1, capituloId: 1, numero: i + 1, texto: 'Versículo ${i + 1}'),
      );

  static List<Versiculo> versiculosCap2({int count = 3}) => List.generate(
        count,
        (i) => Versiculo(id: 100 + i + 1, capituloId: 10, numero: i + 1, texto: 'Cap 2 v ${i + 1}'),
      );
}

void main() {
  late MockWindowService mockWindowService;
  late MockBibliaRepository mockBibleRepo;
  late MockFavoritosRepository mockFavoritosRepo;
  late ProviderContainer container;
  late GrpcDisplayServer server;

  setUp(() {
    mockWindowService = MockWindowService();
    mockBibleRepo = MockBibliaRepository();
    mockFavoritosRepo = MockFavoritosRepository();
    container = createTestContainer(
      windowService: mockWindowService,
      bibleRepo: mockBibleRepo,
      favoritosRepo: mockFavoritosRepo,
    );
    server = GrpcDisplayServer(container: container);

    when(() => mockWindowService.sendMessage(any())).thenAnswer((_) async {});
    when(() => mockBibleRepo.getVersionById(1)).thenAnswer((_) async => TestBibleData.version);
    when(() => mockBibleRepo.getLibroByNumero(1, 1)).thenAnswer((_) async => TestBibleData.libro);
    when(() => mockBibleRepo.getLibroByNumero(1, 2)).thenAnswer((_) async => TestBibleData.libroExodo);
    when(() => mockBibleRepo.getCapitulo(1, 1)).thenAnswer((_) async => TestBibleData.capitulo());
    when(() => mockBibleRepo.getCapitulo(1, 2)).thenAnswer((_) async => TestBibleData.capitulo2());
    when(() => mockBibleRepo.getVersiculosByCapitulo(1)).thenAnswer((_) async => TestBibleData.versiculos());
    when(() => mockBibleRepo.getVersiculosByCapitulo(10)).thenAnswer((_) async => TestBibleData.versiculosCap2());
    when(() => mockBibleRepo.getVersiculo(1, any())).thenAnswer(
      (invocation) async {
        final num = invocation.positionalArguments[1] as int;
        return Versiculo(id: num, capituloId: 1, numero: num, texto: 'Versículo $num');
      },
    );
    when(() => mockBibleRepo.getVersiculo(10, any())).thenAnswer(
      (invocation) async {
        final num = invocation.positionalArguments[1] as int;
        return Versiculo(id: 100 + num, capituloId: 10, numero: num, texto: 'Cap 2 v $num');
      },
    );
    when(() => mockBibleRepo.getCapitulosByLibro(1)).thenAnswer(
      (_) async => [TestBibleData.capitulo(), TestBibleData.capitulo2()],
    );
    when(() => mockBibleRepo.getLibrosByVersion(1)).thenAnswer(
      (_) async => [TestBibleData.libro, TestBibleData.libroExodo],
    );
    when(() => mockBibleRepo.getLibroById(1)).thenAnswer((_) async => TestBibleData.libro);
    when(() => mockBibleRepo.getLibroById(2)).thenAnswer((_) async => TestBibleData.libroExodo);
  });

  tearDown(() {
    container.dispose();
  });

  group('GO_TO_VERSE integration with subprocess', () {
    test('GO_TO_VERSE mismo capitulo solo envia GO_TO_SLIDE (no recarga)', () async {
      await server.sendCommand(
        _TestServiceCall(),
        CommandRequest(
          type: CommandType.GO_TO_VERSE,
          targetVerse: VerseReference()
            ..versionId = 1
            ..libroNumero = 1
            ..capitulo = 1
            ..versiculo = 3,
        ),
      );

      // Para mismo capítulo sin biblia cargada, envía LOAD_VERSE primero
      verify(
        () => mockWindowService.sendMessage(
          any(that: isA<Map<String, dynamic>>()
              .having((m) => m['type'], 'type', 'LOAD_VERSE')
              .having((m) => m['libroNombre'], 'libroNombre', 'Génesis')
              .having((m) => m['capitulo'], 'capitulo', 1)),
        ),
      ).called(1);

      // Y también GO_TO_SLIDE
      verify(
        () => mockWindowService.sendMessage(
          any(that: isA<Map<String, dynamic>>()
              .having((m) => m['type'], 'type', 'GO_TO_SLIDE')
              .having((m) => m['index'], 'index', 3)),
        ),
      ).called(1);
    });

    test('GO_TO_VERSE primer carga envia LOAD_VERSE con versiculos completos', () async {
      final capturedMessages = <Map<String, dynamic>>[];
      when(() => mockWindowService.sendMessage(any())).thenAnswer((invocation) async {
        capturedMessages.add(invocation.positionalArguments[0] as Map<String, dynamic>);
      });

      await server.sendCommand(
        _TestServiceCall(),
        CommandRequest(
          type: CommandType.GO_TO_VERSE,
          targetVerse: VerseReference()
            ..versionId = 1
            ..libroNumero = 1
            ..capitulo = 1
            ..versiculo = 1,
        ),
      );

      final loadVerse = capturedMessages.firstWhere(
        (m) => m['type'] == 'LOAD_VERSE',
        orElse: () => <String, dynamic>{},
      );

      expect(loadVerse['versiculos'], isA<List>());
      expect((loadVerse['versiculos'] as List).length, 5);
      expect(loadVerse['versiculos'][0], 'Versículo 1');
    });
  });

  group('NEXT_VERSE / PREV_VERSE chapter boundary', () {
    test('NEXT_VERSE al último versículo envía LOAD_VERSE del siguiente capítulo', () async {
      // Ir al último versículo del capítulo 1
      await server.sendCommand(
        _TestServiceCall(),
        CommandRequest(
          type: CommandType.GO_TO_VERSE,
          targetVerse: VerseReference()
            ..versionId = 1
            ..libroNumero = 1
            ..capitulo = 1
            ..versiculo = 5,
        ),
      );

      // Limpiar las llamadas anteriores
      reset(mockWindowService);
      when(() => mockWindowService.sendMessage(any())).thenAnswer((_) async {});

      // Ahora NEXT_VERSE debe cargar el capítulo 2
      await server.sendCommand(
        _TestServiceCall(),
        CommandRequest(type: CommandType.NEXT_VERSE),
      );

      verify(
        () => mockWindowService.sendMessage(
          any(that: isA<Map<String, dynamic>>().having(
            (m) => m['type'], 'type', 'LOAD_VERSE',
          )),
        ),
      ).called(1);
    });

    test('PREV_VERSE al primer versículo envía LOAD_VERSE del capítulo anterior', () async {
      // Ir al capítulo 2 versículo 1
      await server.sendCommand(
        _TestServiceCall(),
        CommandRequest(
          type: CommandType.GO_TO_VERSE,
          targetVerse: VerseReference()
            ..versionId = 1
            ..libroNumero = 1
            ..capitulo = 2
            ..versiculo = 1,
        ),
      );

      // Limpiar las llamadas anteriores
      reset(mockWindowService);
      when(() => mockWindowService.sendMessage(any())).thenAnswer((_) async {});

      // Ahora PREV_VERSE debe cargar el capítulo 1
      await server.sendCommand(
        _TestServiceCall(),
        CommandRequest(type: CommandType.PREV_VERSE),
      );

      verify(
        () => mockWindowService.sendMessage(
          any(that: isA<Map<String, dynamic>>().having(
            (m) => m['type'], 'type', 'LOAD_VERSE',
          )),
        ),
      ).called(1);
    });
  });
}

/// Implementación concreta de ServiceCall para tests.
class _TestServiceCall implements ServiceCall {
  @override
  Map<String, String>? get clientMetadata => null;
  @override
  Map<String, String>? get headers => null;
  @override
  Map<String, String>? get trailers => null;
  @override
  DateTime? get deadline => null;
  @override
  bool get isTimedOut => false;
  @override
  bool get isCanceled => false;
  @override
  X509Certificate? get clientCertificate => null;
  @override
  InternetAddress? get remoteAddress => null;
  @override
  void sendHeaders() {}
  @override
  void sendTrailers({int? status, String? message}) {}
}
