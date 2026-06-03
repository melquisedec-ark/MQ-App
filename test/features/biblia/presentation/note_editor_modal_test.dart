import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:mqapp/core/database/bible_database_helper.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_config_provider.dart';
import 'package:mqapp/features/biblia/application/providers/biblia_version_provider.dart';
import 'package:mqapp/features/biblia/application/providers/favoritos_provider.dart';
import 'package:mqapp/features/biblia/application/providers/historial_provider.dart';
import 'package:mqapp/features/biblia/application/providers/notas_provider.dart';
import 'package:mqapp/features/biblia/data/models/nota.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_config_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/biblia_search_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/favoritos_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/historial_repository.dart';
import 'package:mqapp/features/biblia/data/repositories/notas_repository.dart';
import 'package:mqapp/features/biblia/presentation/widgets/note_editor_modal.dart';

import '../helpers/bible_db_test_helper.dart';

Widget _buildHarness({
  required BibliaRepository bibliaRepo,
  required FavoritosRepository favRepo,
  required NotasRepository notasRepo,
  required HistorialRepository histRepo,
  required BibliaSearchRepository searchRepo,
  required BibleDatabaseHelper helper,
  BibliaConfigRepository? configRepo,
  int versionId = 1,
  int libroId = 1,
  int capitulo = 1,
  int versiculoNumero = 1,
}) {
  return ProviderScope(
    overrides: <Override>[
      bibleDatabaseHelperProvider.overrideWithValue(helper),
      bibliaRepositoryProvider.overrideWithValue(bibliaRepo),
      favoritosRepositoryProvider.overrideWithValue(favRepo),
      notasRepositoryProvider.overrideWithValue(notasRepo),
      historialRepositoryProvider.overrideWithValue(histRepo),
      notasStreamProvider.overrideWith((_) => notasRepo.watchAll()),
      if (configRepo != null)
        bibliaConfigRepositoryProvider.overrideWithValue(configRepo),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: NoteEditorModal(
          versionId: versionId,
          libroId: libroId,
          capitulo: capitulo,
          versiculoNumero: versiculoNumero,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    initBibleTestFfi();
  });

  late Database db;
  late BibliaRepository bibliaRepo;
  late FavoritosRepository favRepo;
  late NotasRepository notasRepo;
  late HistorialRepository histRepo;
  late BibliaSearchRepository searchRepo;
  late BibleDatabaseHelper helper;

  setUp(() async {
    final bundle = await createBibleReposWithSeed();
    db = bundle.db;
    bibliaRepo = bundle.biblia;
    favRepo = bundle.favoritos;
    notasRepo = bundle.notas;
    histRepo = bundle.historial;
    searchRepo = bundle.search;
    helper = BibleDatabaseHelper.forTesting(db);
  });

  tearDown(() async {
    await closeBibleRepos(
      db: db,
      favoritos: favRepo,
      notas: notasRepo,
      historial: histRepo,
    );
  });

  Widget buildHarness() => _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        searchRepo: searchRepo,
        helper: helper,
      );

  testWidgets('renderiza título, color picker, campo de texto y botones',
      (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    // Título
    expect(find.text('Nota'), findsOneWidget);
    // Subtítulo "v. 1"
    expect(find.text('v. 1'), findsOneWidget);
    // Label de color
    expect(find.text('Color'), findsOneWidget);
    // Campo de texto con hint
    expect(find.text('Escribe tu nota...'), findsOneWidget);
    // Botones
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
    // Sin nota previa → no debe haber botón eliminar
    expect(find.text('Eliminar'), findsNothing);
  });

  testWidgets('guardar persiste la nota en la BD', (tester) async {
    // B1: sembramos el config con amarillo para mantener el comportamiento
    // previo (nota nueva → amarillo). El test nuevo abajo prueba el caso
    // en el que el usuario eligió un color distinto en Configuración.
    final configRepo = BibliaConfigRepository(helper);
    await configRepo.set(BibliaConfigKeys.notaColorDefault, 'amarillo');

    await tester.pumpWidget(
      _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        searchRepo: searchRepo,
        helper: helper,
        configRepo: configRepo,
      ),
    );
    await tester.pumpAndSettle();

    // Escribir contenido
    await tester.enterText(find.byType(TextField), 'Mi reflexión personal');
    await tester.pumpAndSettle();

    // Pulsar guardar
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // Verificar en BD
    final nota = await notasRepo.getNota(1, 1, 1, 1);
    expect(nota, isNotNull);
    expect(nota!.contenido, 'Mi reflexión personal');
    expect(nota.color, NotaColor.amarillo);
  });

  testWidgets('usa el color por defecto del provider cuando NO hay nota',
      (tester) async {
    // Sobrescribir el provider con un repo que ya tiene 'verde' como default.
    final configRepo = BibliaConfigRepository(helper);
    await configRepo.set(BibliaConfigKeys.notaColorDefault, 'verde');

    await tester.pumpWidget(
      _buildHarness(
        bibliaRepo: bibliaRepo,
        favRepo: favRepo,
        notasRepo: notasRepo,
        histRepo: histRepo,
        searchRepo: searchRepo,
        helper: helper,
        configRepo: configRepo,
      ),
    );
    await tester.pumpAndSettle();

    // Escribir y guardar
    await tester.enterText(find.byType(TextField), 'Nota con color verde');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // Verificar: el color guardado es el del provider, NO amarillo
    final nota = await notasRepo.getNota(1, 1, 1, 1);
    expect(nota, isNotNull);
    expect(nota!.color, NotaColor.verde,
        reason: 'B1: debe usar el default del provider (verde), no amarillo');
  });
}
