import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mqapp/core/window_manager/window_providers.dart';
import 'package:mqapp/core/window_manager/window_service.dart';
import 'package:mqapp/data/datasources/remote/grpc_display_server.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_libro_provider.dart';
import 'package:mqapp/features/biblia/application/providers/current_versiculo_provider.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/data/models/biblia_version.dart';
import 'package:mqapp/features/biblia/data/models/capitulo.dart';
import 'package:mqapp/features/biblia/data/models/libro.dart';
import 'package:mqapp/features/biblia/data/models/versiculo.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/presentation/views_projection/providers/live_control_providers.dart';
import 'package:mqapp/proto/generated/hymn_control.pbgrpc.dart';

// ── Mocks ────────────────────────────────────────────────────────

class MockWindowService extends Mock implements WindowService {}

class MockBibliaRepository extends Mock implements BibliaRepository {}

class MockFavoritosRepository extends Mock implements FavoritosRepository {}

// ── Helpers ────────────────────────────────────────────────────────

/// Crea un ProviderContainer con providers mockeados para los tests de gRPC.
ProviderContainer createTestContainer({
  required MockWindowService windowService,
  required MockBibliaRepository bibleRepo,
  required MockFavoritosRepository favoritosRepo,
}) {
  final container = ProviderContainer(
    overrides: [
      windowServiceProvider.overrideWithValue(windowService),
      bibliaRepositoryProvider.overrideWithValue(bibleRepo),
      favoritosRepositoryProvider.overrideWithValue(favoritosRepo),
    ],
  );
  return container;
}

/// Datos bíblicos de prueba: Génesis 1 con 5 versículos.
class TestBibleData {
  static final version = BibliaVersion(
    id: 1,
    nombre: 'Reina-Valera 1909',
    abreviatura: 'RVR1909',
    idioma: 'es',
    activa: true,
  );

  static final libro = Libro(
    id: 1,
    versionId: 1,
    nombre: 'Génesis',
    abreviatura: 'Gn',
    testamento: Testamento.at,
    numero: 1,
    totalCapitulos: 50,
  );

  static Capitulo capitulo({int totalVersiculos = 5, int numero = 1}) => Capitulo(
        id: numero,
        libroId: 1,
        numero: numero,
        totalVersiculos: totalVersiculos,
      );

  static Capitulo capitulo2({int totalVersiculos = 3}) => Capitulo(
        id: 10,
        libroId: 1,
        numero: 2,
        totalVersiculos: totalVersiculos,
      );

  static List<Versiculo> versiculos({int count = 5}) => List.generate(
        count,
        (i) => Versiculo(
          id: i + 1,
          capituloId: 1,
          numero: i + 1,
          texto: 'Versículo ${i + 1} de prueba',
        ),
      );

  static final libroExodo = Libro(
    id: 2,
    versionId: 1,
    nombre: 'Éxodo',
    abreviatura: 'Ex',
    testamento: Testamento.at,
    numero: 2,
    totalCapitulos: 40,
  );

  static final capituloExodo = Capitulo(
    id: 2,
    libroId: 2,
    numero: 1,
    totalVersiculos: 3,
  );

  static List<Versiculo> versiculosExodo({int count = 3}) => List.generate(
        count,
        (i) => Versiculo(
          id: 100 + i + 1,
          capituloId: 2,
          numero: i + 1,
          texto: 'Éxodo versículo ${i + 1}',
        ),
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

    // Configurar stubs comunes
    when(() => mockWindowService.sendMessage(any())).thenAnswer((_) async {});
    when(() => mockBibleRepo.getVersionById(1)).thenAnswer(
      (_) async => TestBibleData.version,
    );
    when(() => mockBibleRepo.getLibroByNumero(1, 1)).thenAnswer(
      (_) async => TestBibleData.libro,
    );
    when(() => mockBibleRepo.getLibroByNumero(1, 2)).thenAnswer(
      (_) async => TestBibleData.libroExodo,
    );
    when(() => mockBibleRepo.getCapitulo(1, 1)).thenAnswer(
      (_) async => TestBibleData.capitulo(),
    );
    when(() => mockBibleRepo.getCapitulo(1, 2)).thenAnswer(
      (_) async => TestBibleData.capitulo2(),
    );
    when(() => mockBibleRepo.getCapitulo(2, 1)).thenAnswer(
      (_) async => TestBibleData.capituloExodo,
    );
    when(() => mockBibleRepo.getVersiculosByCapitulo(1)).thenAnswer(
      (_) async => TestBibleData.versiculos(),
    );
    when(() => mockBibleRepo.getVersiculosByCapitulo(10)).thenAnswer(
      (_) async => TestBibleData.versiculos(count: 3),
    );
    when(() => mockBibleRepo.getVersiculosByCapitulo(2)).thenAnswer(
      (_) async => TestBibleData.versiculosExodo(),
    );
    // Mock getVersiculo para cualquier versículo del capítulo 1
    when(() => mockBibleRepo.getVersiculo(1, any())).thenAnswer(
      (invocation) async {
        final num = invocation.positionalArguments[1] as int;
        return Versiculo(
          id: num,
          capituloId: 1,
          numero: num,
          texto: 'Versículo $num de prueba',
        );
      },
    );
    // Mock getVersiculo para capítulo 2 (id 10)
    when(() => mockBibleRepo.getVersiculo(10, any())).thenAnswer(
      (invocation) async {
        final num = invocation.positionalArguments[1] as int;
        return Versiculo(
          id: 100 + num,
          capituloId: 10,
          numero: num,
          texto: 'Cap 2 versículo $num',
        );
      },
    );
    when(() => mockBibleRepo.getCapitulosByLibro(1)).thenAnswer(
      (_) async => [TestBibleData.capitulo(), TestBibleData.capitulo2()],
    );
    when(() => mockBibleRepo.getCapitulosByLibro(2)).thenAnswer(
      (_) async => [TestBibleData.capituloExodo],
    );
    when(() => mockBibleRepo.getLibrosByVersion(1)).thenAnswer(
      (_) async => [TestBibleData.libro, TestBibleData.libroExodo],
    );
    when(() => mockBibleRepo.getLibroById(1)).thenAnswer(
      (_) async => TestBibleData.libro,
    );
    when(() => mockBibleRepo.getLibroById(2)).thenAnswer(
      (_) async => TestBibleData.libroExodo,
    );
  });

  tearDown(() {
    container.dispose();
  });

  // ── Test 1: NEXT_VERSE envía NEXT_SLIDE al subproceso ──────────
  test('NEXT_VERSE sends NEXT_SLIDE to subprocess', () async {
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(type: CommandType.NEXT_VERSE),
    );

    verify(
      () => mockWindowService.sendMessage({'type': 'NEXT_SLIDE'}),
    ).called(1);
  });

  // ── Test 2: PREV_VERSE envía PREV_SLIDE al subproceso ──────────
  test('PREV_VERSE sends PREV_SLIDE to subprocess', () async {
    // Primero ir al versículo 3 para poder retroceder
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(
        type: CommandType.GO_TO_VERSE,
        targetVerse: VerseReference()
          ..versionId = 1
          ..libroNumero = 1
          ..capitulo = 1
          ..versiculo = 3,
      ),
    );

    // Ahora enviar PREV_VERSE
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(type: CommandType.PREV_VERSE),
    );

    verify(
      () => mockWindowService.sendMessage({'type': 'PREV_SLIDE'}),
    ).called(1);
  });

  // ── Test 3: NEXT_CHAPTER envía LOAD_VERSE con nuevo capítulo ───
  test('NEXT_CHAPTER sends LOAD_VERSE with new chapter', () async {
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(type: CommandType.NEXT_CHAPTER),
    );

    // Debe enviar LOAD_VERSE con el capítulo siguiente
    verify(
      () => mockWindowService.sendMessage(
        any(that: isA<Map<String, dynamic>>().having(
          (m) => m['type'],
          'type',
          'LOAD_VERSE',
        )),
      ),
    ).called(1);
  });

  // ── Test 4: PREV_CHAPTER no crashea en capítulo 1 ──────────────
  test('PREV_CHAPTER does not crash at chapter 1', () async {
    // Estamos en Génesis 1:1, no hay capítulo anterior
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(type: CommandType.PREV_CHAPTER),
    );

    // No debe lanzar excepciones
  });

  // ── Test 5: GO_TO_VERSE envía GO_TO_SLIDE con índice correcto ──
  test('GO_TO_VERSE sends GO_TO_SLIDE with correct index', () async {
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(
        type: CommandType.GO_TO_VERSE,
        targetVerse: VerseReference()
          ..versionId = 1
          ..libroNumero = 1
          ..capitulo = 1
          ..versiculo = 3,
      ),
    );

    verify(
      () => mockWindowService.sendMessage(
        any(that: isA<Map<String, dynamic>>()
            .having((m) => m['type'], 'type', 'GO_TO_SLIDE')
            .having((m) => m['index'], 'index', 2)),
      ),
    ).called(1);
  });

  // ── Test 6: SET_BIBLE_THEME envía SET_BIBLE_THEME ──────────────
  test('SET_BIBLE_THEME sends SET_BIBLE_THEME message', () async {
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(
        type: CommandType.SET_BIBLE_THEME,
        bibleTheme: 'noche',
      ),
    );

    verify(
      () => mockWindowService.sendMessage(
        any(that: isA<Map<String, dynamic>>()
            .having((m) => m['type'], 'type', 'SET_BIBLE_THEME')
            .having((m) => m['theme'], 'theme', 'noche')),
      ),
    ).called(1);
  });

  // ── Test 7: SET_BIBLE_FONT_SCALE envía SET_BIBLE_FONT_SIZE y clampa ─
  test('SET_BIBLE_FONT_SCALE sends SET_BIBLE_FONT_SIZE and clamps', () async {
    // Valor dentro del rango
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(
        type: CommandType.SET_BIBLE_FONT_SCALE,
        bibleFontScale: 2.0,
      ),
    );

    verify(
      () => mockWindowService.sendMessage(
        any(that: isA<Map<String, dynamic>>()
            .having((m) => m['type'], 'type', 'SET_BIBLE_FONT_SIZE')
            .having((m) => m['scale'], 'scale', 2.0)),
      ),
    ).called(1);
  });

  test('SET_BIBLE_FONT_SCALE clamps to minimum 0.8', () async {
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(
        type: CommandType.SET_BIBLE_FONT_SCALE,
        bibleFontScale: 0.3,
      ),
    );

    verify(
      () => mockWindowService.sendMessage(
        any(that: isA<Map<String, dynamic>>()
            .having((m) => m['type'], 'type', 'SET_BIBLE_FONT_SIZE')
            .having((m) => m['scale'], 'scale', 0.8)),
      ),
    ).called(1);
  });

  test('SET_BIBLE_FONT_SCALE clamps to maximum 4.0', () async {
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(
        type: CommandType.SET_BIBLE_FONT_SCALE,
        bibleFontScale: 10.0,
      ),
    );

    verify(
      () => mockWindowService.sendMessage(
        any(that: isA<Map<String, dynamic>>()
            .having((m) => m['type'], 'type', 'SET_BIBLE_FONT_SIZE')
            .having((m) => m['scale'], 'scale', 4.0)),
      ),
    ).called(1);
  });

  // ── Test 8: SWITCH_TO_BIBLE envía LOAD_VERSE con Génesis 1 ─────
  test('SWITCH_TO_BIBLE sends LOAD_VERSE with Genesis 1', () async {
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(type: CommandType.SWITCH_TO_BIBLE),
    );

    verify(
      () => mockWindowService.sendMessage(
        any(that: isA<Map<String, dynamic>>()
            .having((m) => m['type'], 'type', 'LOAD_VERSE')
            .having((m) => m['libroNombre'], 'libroNombre', 'Génesis')
            .having((m) => m['capitulo'], 'capitulo', 1)),
      ),
    ).called(1);
  });

  // ── Test 9: Error cases ────────────────────────────────────────
  test('GO_TO_VERSE with invalid values does nothing', () async {
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(
        type: CommandType.GO_TO_VERSE,
        targetVerse: VerseReference()
          ..versionId = -1
          ..libroNumero = 1
          ..capitulo = 1
          ..versiculo = 1,
      ),
    );

    // No debe enviar ningún mensaje
    verifyNever(
      () => mockWindowService.sendMessage(any()),
    );
  });

  test('GO_TO_VERSE without targetVerse logs warning', () async {
    await server.sendCommand(
      TestServiceCall(),
      CommandRequest(type: CommandType.GO_TO_VERSE),
    );

    // No debe enviar GO_TO_SLIDE sin targetVerse
    verifyNever(
      () => mockWindowService.sendMessage(
        any(that: isA<Map<String, dynamic>>().having(
          (m) => m['type'],
          'type',
          'GO_TO_SLIDE',
        )),
      ),
    );
  });

  // ── Test 10: NEXT_VERSE al último versículo carga siguiente capítulo ─
  test(
    'NEXT_VERSE at last verse of chapter loads next chapter via LOAD_VERSE',
    () async {
      // Ir al último versículo (5) del capítulo 1
      await server.sendCommand(
        TestServiceCall(),
        CommandRequest(
          type: CommandType.GO_TO_VERSE,
          targetVerse: VerseReference()
            ..versionId = 1
            ..libroNumero = 1
            ..capitulo = 1
            ..versiculo = 5,
        ),
      );

      // Reset mock to clear previous calls
      reset(mockWindowService);
      when(() => mockWindowService.sendMessage(any())).thenAnswer((_) async {});

      // Ahora NEXT_VERSE debe ir al siguiente capítulo (Éxodo 1)
      await server.sendCommand(
        TestServiceCall(),
        CommandRequest(type: CommandType.NEXT_VERSE),
      );

      // Debe enviar LOAD_VERSE con el nuevo capítulo
      verify(
        () => mockWindowService.sendMessage(
          any(that: isA<Map<String, dynamic>>().having(
            (m) => m['type'],
            'type',
            'LOAD_VERSE',
          )),
        ),
      ).called(1);
    },
  );
}

/// Implementación concreta de ServiceCall para tests.
class TestServiceCall implements ServiceCall {
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
