import 'package:flutter_test/flutter_test.dart';
import 'package:himnario_id_2/core/enums/estrofa_tipo.dart';
import 'package:himnario_id_2/core/enums/himno_tipo.dart';
import 'package:himnario_id_2/domain/entities/estrofa.dart';
import 'package:himnario_id_2/domain/entities/himno.dart';
import 'package:himnario_id_2/domain/entities/projection_slide.dart';

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
      ];

      for (final slide in slides) {
        final label = switch (slide) {
          TitleSlide() => 'portada',
          LyricsSlide() => 'letra',
          AmenSlide() => 'amen',
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
}
