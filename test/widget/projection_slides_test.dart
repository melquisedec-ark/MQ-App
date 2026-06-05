import 'package:flutter_test/flutter_test.dart';
import 'package:mqapp/core/enums/estrofa_tipo.dart';
import 'package:mqapp/core/enums/himno_tipo.dart';
import 'package:mqapp/domain/entities/estrofa.dart';
import 'package:mqapp/domain/entities/himno.dart';
import 'package:mqapp/domain/entities/projection_slide.dart';
import 'package:mqapp/presentation/views_projection/providers/presentation_providers.dart';

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════

Himno _createHimno({int id = 1, String titulo = 'Santo, Santo, Santo', int? numero = 1}) {
  return Himno(
    id: id,
    titulo: titulo,
    numero: numero,
    tipo: HimnoTipo.oficial,
  );
}

List<Estrofa> _createEstrofas() {
  return [
    const Estrofa(id: 1, versionPaisId: 1, tipo: EstrofaTipo.estrofa, orden: 1, contenido: 'Estrofa uno'),
    const Estrofa(id: 2, versionPaisId: 1, tipo: EstrofaTipo.coro, orden: 2, contenido: 'Coro glorioso'),
    const Estrofa(id: 3, versionPaisId: 1, tipo: EstrofaTipo.estrofa, orden: 3, contenido: 'Estrofa tres'),
  ];
}

/// Construye slides como lo hace LiveControlNotifier._buildSlides.
List<ProjectionSlide> _buildSlides(Himno hymn, List<Estrofa> stanzas) {
  return [
    ProjectionSlide.title(himno: hymn),
    ...stanzas.map((e) => ProjectionSlide.lyrics(estrofa: e)),
    const ProjectionSlide.amen(),
  ];
}

// ═══════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════

void main() {
  group('ProjectionSlide — construcción', () {
    test('TitleSlide se crea con un Himno', () {
      final himno = _createHimno();
      final slide = ProjectionSlide.title(himno: himno);

      expect(slide, isA<TitleSlide>());
      expect((slide as TitleSlide).himno.titulo, 'Santo, Santo, Santo');
      expect(slide.displayLabel, 'Portada');
    });

    test('LyricsSlide se crea con una Estrofa', () {
      final estrofa = _createEstrofas()[0];
      final slide = ProjectionSlide.lyrics(estrofa: estrofa);

      expect(slide, isA<LyricsSlide>());
      final lyrics = slide as LyricsSlide;
      expect(lyrics.estrofa.contenido, 'Estrofa uno');
      expect(lyrics.estrofa.isChorus, false);
      expect(slide.displayLabel, 'Letra');
    });

    test('AmenSlide se crea sin parámetros', () {
      final slide = const ProjectionSlide.amen();

      expect(slide, isA<AmenSlide>());
      expect(slide.displayLabel, 'Amén');
    });
  });

  group('ProjectionSlide — helpers por extensión', () {
    test('TitleSlideHelpers agrega titulo y numero', () {
      final himno = _createHimno(numero: 42);
      final slide = ProjectionSlide.title(himno: himno) as TitleSlide;

      expect(slide.titulo, 'Santo, Santo, Santo');
      expect(slide.numero, 42);
    });

    test('TitleSlideHelpers.numero es null cuando himno no tiene número', () {
      final himno = _createHimno(numero: null);
      final slide = ProjectionSlide.title(himno: himno) as TitleSlide;

      expect(slide.numero, isNull);
    });

    test('LyricsSlideHelpers agrega contenido y isChorus', () {
      final estrofa = _createEstrofas()[1]; // coro
      final slide = ProjectionSlide.lyrics(estrofa: estrofa) as LyricsSlide;

      expect(slide.contenido, 'Coro glorioso');
      expect(slide.isChorus, true);
    });

    test('LyricsSlideHelpers.isChorus es false para estrofas normales', () {
      final estrofa = _createEstrofas()[0]; // estrofa
      final slide = ProjectionSlide.lyrics(estrofa: estrofa) as LyricsSlide;

      expect(slide.isChorus, false);
    });
  });

  group('ProjectionSlide — construcción de slides desde himno', () {
    test('_buildSlides crea la secuencia correcta: [Title, Lyrics..., Amen]', () {
      final himno = _createHimno();
      final estrofas = _createEstrofas(); // 3 estrofas
      final slides = _buildSlides(himno, estrofas);

      expect(slides.length, 5); // Title + 3 Lyrics + Amen
      expect(slides[0], isA<TitleSlide>());
      expect(slides[1], isA<LyricsSlide>());
      expect(slides[2], isA<LyricsSlide>());
      expect(slides[3], isA<LyricsSlide>());
      expect(slides[4], isA<AmenSlide>());
    });

    test('La lista de slides mantiene el orden correcto de estrofas', () {
      final himno = _createHimno();
      final estrofas = _createEstrofas();
      final slides = _buildSlides(himno, estrofas);

      for (var i = 0; i < estrofas.length; i++) {
        final lyricsSlide = slides[i + 1] as LyricsSlide;
        expect(lyricsSlide.estrofa.contenido, estrofas[i].contenido);
      }
    });

    test('Con 0 estrofas: slides = [Title, Amen]', () {
      final himno = _createHimno();
      final slides = _buildSlides(himno, []);

      expect(slides.length, 2);
      expect(slides[0], isA<TitleSlide>());
      expect(slides[1], isA<AmenSlide>());
    });
  });

  group('ProjectionSlide — sealed class exhaustividad', () {
    test('switch cubre todos los tipos de ProjectionSlide', () {
      final slides = [
        ProjectionSlide.title(himno: _createHimno()),
        ProjectionSlide.lyrics(estrofa: _createEstrofas()[0]),
        const ProjectionSlide.amen(),
        const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 1),
        const ProjectionSlide.verse(
          numero: 1, texto: 'Texto', referencia: 'Génesis 1:1', totalVersiculos: 1,
        ),
        const ProjectionSlide.bibleEnd(libroNombre: 'Génesis', capitulo: 1),
      ];

      for (final slide in slides) {
        final label = switch (slide) {
          TitleSlide() => 'portada',
          LyricsSlide() => 'letra',
          AmenSlide() => 'amen',
          BibleTitleSlide() => 'titulo',
          VerseSlide() => 'versiculo',
          BibleEndSlide() => 'fin',
        };
        expect(label, isNotEmpty);
      }
    });

    test('displayLabel retorna valores correctos', () {
      expect(
        ProjectionSlide.title(himno: _createHimno()).displayLabel,
        'Portada',
      );
      expect(
        ProjectionSlide.lyrics(estrofa: _createEstrofas()[0]).displayLabel,
        'Letra',
      );
      expect(
        const ProjectionSlide.amen().displayLabel,
        'Amén',
      );
    });
  });

  group('ProjectionSlide — igualdad (freezed)', () {
    test('TitleSlide con mismo himno son iguales', () {
      final h1 = _createHimno(id: 1);
      final h2 = _createHimno(id: 1);
      expect(
        ProjectionSlide.title(himno: h1),
        ProjectionSlide.title(himno: h2),
      );
    });

    test('TitleSlide con diferente himno son diferentes', () {
      final h1 = _createHimno(id: 1);
      final h2 = _createHimno(id: 2);
      expect(
        ProjectionSlide.title(himno: h1),
        isNot(ProjectionSlide.title(himno: h2)),
      );
    });

    test('Todos los AmenSlide son iguales', () {
      expect(
        const ProjectionSlide.amen(),
        const ProjectionSlide.amen(),
      );
    });

    test('Tipos diferentes no son iguales', () {
      expect(
        ProjectionSlide.title(himno: _createHimno()),
        isNot(ProjectionSlide.lyrics(estrofa: _createEstrofas()[0])),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Tests de slides bíblicos
  // ═══════════════════════════════════════════════════════════════

  group('ProjectionSlide — tipos bíblicos', () {
    test('BibleTitleSlide se crea con libro y capítulo', () {
      final slide = ProjectionSlide.bibleTitle(
        libroNombre: 'Génesis',
        capitulo: 1,
      );

      expect(slide, isA<BibleTitleSlide>());
      final title = slide as BibleTitleSlide;
      expect(title.libroNombre, 'Génesis');
      expect(title.capitulo, 1);
      expect(slide.displayLabel, 'Título');
    });

    test('VerseSlide se crea con número, texto, referencia y total', () {
      final slide = ProjectionSlide.verse(
        numero: 1,
        texto: 'En el principio creó Dios los cielos y la tierra.',
        referencia: 'Génesis 1:1',
        totalVersiculos: 31,
      );

      expect(slide, isA<VerseSlide>());
      final verse = slide as VerseSlide;
      expect(verse.numero, 1);
      expect(verse.texto, 'En el principio creó Dios los cielos y la tierra.');
      expect(verse.referencia, 'Génesis 1:1');
      expect(verse.totalVersiculos, 31);
      expect(slide.displayLabel, 'Versículo');
    });

    test('BibleEndSlide se crea con libro y capítulo', () {
      final slide = ProjectionSlide.bibleEnd(
        libroNombre: 'Génesis',
        capitulo: 1,
      );

      expect(slide, isA<BibleEndSlide>());
      final end = slide as BibleEndSlide;
      expect(end.libroNombre, 'Génesis');
      expect(end.capitulo, 1);
      expect(slide.displayLabel, 'Fin');
    });
  });

  group('ProjectionSlide — helpers bíblicos', () {
    test('BibleTitleSlideHelpers.formatea referencia', () {
      final slide = ProjectionSlide.bibleTitle(
        libroNombre: 'Juan',
        capitulo: 3,
      ) as BibleTitleSlide;

      expect(slide.referencia, 'Juan 3');
    });

    test('VerseSlideHelpers.formatea progreso', () {
      final slide = ProjectionSlide.verse(
        numero: 16,
        texto: 'Porque de tal manera amó Dios al mundo...',
        referencia: 'Juan 3:16',
        totalVersiculos: 21,
      ) as VerseSlide;

      expect(slide.progreso, '16/21');
    });

    test('BibleEndSlideHelpers.formatea referencia con fin', () {
      final slide = ProjectionSlide.bibleEnd(
        libroNombre: 'Juan',
        capitulo: 3,
      ) as BibleEndSlide;

      expect(slide.referencia, 'Juan 3 — Fin');
    });
  });

  group('ProjectionSlide — construcción bíblica completa', () {
    test('_buildBibleSlides crea secuencia: [Título, Versículos..., Fin]', () {
      const versiculos = [
        'En el principio creó Dios los cielos y la tierra.',
        'Y la tierra estaba desordenada y vacía.',
        'Y dijo Dios: Sea la luz; y fue la luz.',
      ];

      final slides = <ProjectionSlide>[
        const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 1),
        ...versiculos.asMap().entries.map((e) => ProjectionSlide.verse(
          numero: e.key + 1,
          texto: e.value,
          referencia: 'Génesis 1:${e.key + 1}',
          totalVersiculos: versiculos.length,
        )),
        const ProjectionSlide.bibleEnd(libroNombre: 'Génesis', capitulo: 1),
      ];

      expect(slides.length, 5); // Título + 3 versículos + Fin
      expect(slides[0], isA<BibleTitleSlide>());
      expect(slides[1], isA<VerseSlide>());
      expect(slides[2], isA<VerseSlide>());
      expect(slides[3], isA<VerseSlide>());
      expect(slides[4], isA<BibleEndSlide>());
    });

    test('Los versículos mantienen orden y referencia correctos', () {
      const versiculos = ['Verso A', 'Verso B'];
      final slides = <ProjectionSlide>[
        const ProjectionSlide.bibleTitle(libroNombre: 'Test', capitulo: 1),
        ...versiculos.asMap().entries.map((e) => ProjectionSlide.verse(
          numero: e.key + 1,
          texto: e.value,
          referencia: 'Test 1:${e.key + 1}',
          totalVersiculos: versiculos.length,
        )),
        const ProjectionSlide.bibleEnd(libroNombre: 'Test', capitulo: 1),
      ];

      final verse1 = slides[1] as VerseSlide;
      expect(verse1.numero, 1);
      expect(verse1.texto, 'Verso A');
      expect(verse1.referencia, 'Test 1:1');

      final verse2 = slides[2] as VerseSlide;
      expect(verse2.numero, 2);
      expect(verse2.texto, 'Verso B');
      expect(verse2.referencia, 'Test 1:2');
    });

    test('Con 0 versículos: slides = [Título, Fin]', () {
      const slides = <ProjectionSlide>[
        ProjectionSlide.bibleTitle(libroNombre: 'Test', capitulo: 1),
        ProjectionSlide.bibleEnd(libroNombre: 'Test', capitulo: 1),
      ];

      expect(slides.length, 2);
      expect(slides[0], isA<BibleTitleSlide>());
      expect(slides[1], isA<BibleEndSlide>());
    });
  });

  group('ProjectionSlide — exhaustividad con tipos bíblicos', () {
    test('switch cubre los 6 tipos de ProjectionSlide', () {
      final slides = <ProjectionSlide>[
        ProjectionSlide.title(himno: _createHimno()),
        ProjectionSlide.lyrics(estrofa: _createEstrofas()[0]),
        const ProjectionSlide.amen(),
        const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 1),
        const ProjectionSlide.verse(
          numero: 1,
          texto: 'Texto',
          referencia: 'Génesis 1:1',
          totalVersiculos: 1,
        ),
        const ProjectionSlide.bibleEnd(libroNombre: 'Génesis', capitulo: 1),
      ];

      for (final slide in slides) {
        final label = switch (slide) {
          TitleSlide() => 'portada',
          LyricsSlide() => 'letra',
          AmenSlide() => 'amen',
          BibleTitleSlide() => 'titulo',
          VerseSlide() => 'versiculo',
          BibleEndSlide() => 'fin',
        };
        expect(label, isNotEmpty);
      }
    });

    test('displayLabel retorna valores correctos para los 6 tipos', () {
      expect(
        ProjectionSlide.title(himno: _createHimno()).displayLabel,
        'Portada',
      );
      expect(
        ProjectionSlide.lyrics(estrofa: _createEstrofas()[0]).displayLabel,
        'Letra',
      );
      expect(
        const ProjectionSlide.amen().displayLabel,
        'Amén',
      );
      expect(
        const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 1).displayLabel,
        'Título',
      );
      expect(
        const ProjectionSlide.verse(
          numero: 1,
          texto: 'Texto',
          referencia: 'Génesis 1:1',
          totalVersiculos: 1,
        ).displayLabel,
        'Versículo',
      );
      expect(
        const ProjectionSlide.bibleEnd(libroNombre: 'Génesis', capitulo: 1).displayLabel,
        'Fin',
      );
    });
  });

  group('ProjectionSlide — igualdad con tipos bíblicos (freezed)', () {
    test('BibleTitleSlide con mismos datos son iguales', () {
      expect(
        const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 1),
        const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 1),
      );
    });

    test('BibleTitleSlide con diferente capítulo son diferentes', () {
      expect(
        const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 1),
        isNot(const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 2)),
      );
    });

    test('VerseSlide con mismos datos son iguales', () {
      const v1 = ProjectionSlide.verse(
        numero: 1, texto: 'Hola', referencia: 'Gen 1:1', totalVersiculos: 5,
      );
      const v2 = ProjectionSlide.verse(
        numero: 1, texto: 'Hola', referencia: 'Gen 1:1', totalVersiculos: 5,
      );
      expect(v1, v2);
    });

    test('VerseSlide con diferente texto son diferentes', () {
      const v1 = ProjectionSlide.verse(
        numero: 1, texto: 'Hola', referencia: 'Gen 1:1', totalVersiculos: 5,
      );
      const v2 = ProjectionSlide.verse(
        numero: 1, texto: 'Mundo', referencia: 'Gen 1:1', totalVersiculos: 5,
      );
      expect(v1, isNot(v2));
    });

    test('BibleEndSlide con mismos datos son iguales', () {
      expect(
        const ProjectionSlide.bibleEnd(libroNombre: 'Génesis', capitulo: 1),
        const ProjectionSlide.bibleEnd(libroNombre: 'Génesis', capitulo: 1),
      );
    });

    test('Tipos bíblicos diferentes no son iguales', () {
      expect(
        const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 1),
        isNot(const ProjectionSlide.bibleEnd(libroNombre: 'Génesis', capitulo: 1)),
      );
    });

    test('Tipos himnario vs biblia no son iguales', () {
      expect(
        ProjectionSlide.title(himno: _createHimno()),
        isNot(const ProjectionSlide.bibleTitle(libroNombre: 'Génesis', capitulo: 1)),
      );
    });
  });

  group('ProjectionModule enum', () {
    test('tiene valores hymnal y bible', () {
      expect(ProjectionModule.values, contains(ProjectionModule.hymnal));
      expect(ProjectionModule.values, contains(ProjectionModule.bible));
      expect(ProjectionModule.values.length, 2);
    });
  });
}
