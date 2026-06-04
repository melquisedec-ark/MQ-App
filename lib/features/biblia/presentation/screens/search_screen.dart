import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/shared_widgets/glass_card.dart';
import '../../application/providers/biblia_version_provider.dart';
import '../../application/providers/cross_referencias_provider.dart';
import '../../application/providers/current_libro_provider.dart';
import '../../application/providers/current_versiculo_provider.dart';
import '../../application/providers/derived_providers.dart';
import '../../application/providers/reader_providers.dart';
import '../../data/models/cross_referencia.dart';
import '../../data/models/libro.dart';
import '../../data/models/versiculo_contexto.dart';
import '../widgets/verse_card.dart' show BibleReaderViewMode;
import '../widgets/version_picker_sheet.dart';

/// Pantalla de búsqueda FTS5 con debounce + búsqueda de cross-references.
///
/// Referencia: `doc/wireframes/02_bible_module.md` (Pantalla 2c - búsqueda).
///
/// C9: ahora tiene 2 tabs:
///   - **Versículos** (default): búsqueda full-text del texto de los
///     versículos (existente desde Fase 2a).
///   - **Referencias**: el usuario escribe una referencia destino
///     (ej. "Juan 3:16") y ve la lista de versículos que la CITAN
///     (refs FROM → Juan 3:16). Usa `crossReferenciasRepository.getByToVerse()`.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    // Al cambiar de tab, no reseteamos el query: la misma búsqueda puede
    // tener sentido en ambos contextos. Pero sí cambiamos el hint.
    setState(() {});
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() => _query = '');
    _focusNode.requestFocus();
  }

  String get _hint => _tabController.index == 0
      ? 'Buscar versículos...'
      : 'Buscar referencias (ej. Juan 3:16)';

  @override
  Widget build(BuildContext context) {
    final versionId = ref.watch(currentVersionIdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: _hint,
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.titleMedium,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Limpiar',
              onPressed: _clear,
            ),
          _VersionSelectorButton(versionId: versionId),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Versículos', icon: Icon(Icons.menu_book_rounded, size: 18)),
            Tab(text: 'Referencias', icon: Icon(Icons.link_rounded, size: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildVersiculosBody(context, versionId),
            _buildReferenciasBody(context, versionId),
          ],
        ),
      ),
    );
  }

  Widget _buildVersiculosBody(BuildContext context, int versionId) {
    if (_query.trim().isEmpty) {
      return _EmptyHint(
        icon: Icons.search_rounded,
        text: 'Escribe palabras para buscar versículos',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return _ResultsList(
      query: _query,
      versionId: versionId,
    );
  }

  Widget _buildReferenciasBody(BuildContext context, int versionId) {
    if (_query.trim().isEmpty) {
      return _EmptyHint(
        icon: Icons.link_rounded,
        text: 'Escribe una referencia destino (ej. Juan 3:16)\n'
            'para ver qué versículos la citan',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return _RefResultsList(
      query: _query,
      versionId: versionId,
    );
  }
}

class _VersionSelectorButton extends ConsumerWidget {
  const _VersionSelectorButton({required this.versionId});

  final int versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final versionsAsync = ref.watch(activeBibliaVersionsProvider);
    return versionsAsync.maybeWhen(
      data: (versions) {
        final current = versions.firstWhere(
          (v) => v.id == versionId,
          orElse: () => versions.first,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => VersionPickerSheet.show(
                context: context,
                versions: versions,
                currentVersionId: versionId,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  current.abreviatura,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({
    required this.query,
    required this.versionId,
  });

  final String query;
  final int versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchRepo = ref.read(bibliaSearchRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<VersiculoContexto>>(
      future: searchRepo.search(query, versionId: versionId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: TextStyle(color: colorScheme.error),
            ),
          );
        }
        final results = snap.data ?? const <VersiculoContexto>[];
        if (results.isEmpty) {
          return _EmptyHint(
            icon: Icons.search_off_rounded,
            text: 'No se encontraron versículos para "$query"',
            color: colorScheme.onSurfaceVariant,
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${results.length} resultado${results.length == 1 ? '' : 's'} para "$query"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            if (results.length >= 500)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                child: Text(
                  '${results.length} resultados — considera una búsqueda más específica',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _ResultCard(
                  result: results[i],
                  query: query,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultCard extends ConsumerWidget {
  const _ResultCard({
    required this.result,
    required this.query,
  });

  final VersiculoContexto result;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _openReader(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Referencia
          Text(
            result.referencia,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          // Texto con highlights
          _HighlightedText(
            text: result.versiculo.texto,
            query: query,
          ),
        ],
      ),
    );
  }

  void _openReader(BuildContext context, WidgetRef ref) {
    // Resolver libroId desde (versionId, libroNumero)
    ref.read(currentVersionIdProvider.notifier).state = result.versionId;
    // Necesitamos el libroId interno. Lo resolvemos via repo.
    final biblia = ref.read(bibliaRepositoryProvider);
    biblia.getLibroByNumero(result.versionId, result.libroNumero).then((libro) {
      if (libro == null) return;
      ref.read(currentLibroIdProvider.notifier).state = libro.id;
      ref.read(currentCapituloProvider.notifier).state = result.capituloNumero;
      ref.read(currentVersiculoNumeroProvider.notifier).state =
          result.versiculo.numero;
      // Forzar modo capítulo para que el auto-scroll al versículo funcione
      ref.read(readerViewModeProvider.notifier).setViewMode(
        BibleReaderViewMode.chapter,
      );
      if (!context.mounted) return;
      context.pushNamed(
        'biblia_reader',
        pathParameters: <String, String>{
          'libroId': '${libro.id}',
          'capitulo': '${result.capituloNumero}',
        },
        queryParameters: <String, String>{
          'v': '${result.versiculo.numero}',
        },
      );
    });
  }
}

/// Resalta (en bold y color primario) las palabras de [query] dentro de
/// [text]. Búsqueda case-insensitive.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5,
        );

    final tokens = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) {
      return Text(text, style: baseStyle);
    }

    // Construir regex OR con escape
    final pattern = RegExp(
      tokens.map(RegExp.escape).join('|'),
      caseSensitive: false,
    );

    final spans = <TextSpan>[];
    int start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }
}

/// ───────────────────────────────────────────────────────────────────
/// C9: Búsqueda de cross-references (tab "Referencias")
/// ───────────────────────────────────────────────────────────────────

/// Resultado de parsear una referencia tipo "Juan 3:16" o "1 Juan 4:9".
/// Devuelve `null` si el input no matchea el patrón esperado.
class _ParsedReference {
  const _ParsedReference({
    required this.libroNombre,
    required this.capitulo,
    required this.versiculo,
  });

  /// Nombre del libro tal como lo escribió el usuario (puede ser
  /// abreviatura tipo "Jn" o nombre completo "Juan").
  final String libroNombre;
  final int capitulo;
  final int versiculo;
}

/// Parser de referencias bíblicas tipo "Juan 3:16" / "1 Juan 4:9" /
/// "Gn 1:1". Tolera espacios variables y separadores ":" o ".".
_ParsedReference? _parseReference(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  // Regex: nombre (puede tener espacios y dígitos) + cap + : + versículo.
  // Ej: "Juan 3:16", "1 Juan 4:9", "Gn 1:1", "Mt 5.3", "Ap 22:21"
  final regex = RegExp(r'^(.+?)\s+(\d+)[:.](\d+)$');
  final match = regex.firstMatch(trimmed);
  if (match == null) return null;

  final libroNombre = match.group(1)!.trim();
  final cap = int.tryParse(match.group(2)!);
  final versiculo = int.tryParse(match.group(3)!);
  if (cap == null || versiculo == null) return null;

  return _ParsedReference(
    libroNombre: libroNombre,
    capitulo: cap,
    versiculo: versiculo,
  );
}

/// Normaliza un string para matching: minúsculas + sin acentos + trim.
String _normalizeBookName(String s) {
  final lower = s.toLowerCase().trim();
  // Quitar acentos manualmente (sin depender de intl).
  const accents = 'áéíóúñü';
  const noAccents = 'aeiounu';
  final buf = StringBuffer();
  for (final c in lower.runes) {
    final ch = String.fromCharCode(c);
    final idx = accents.indexOf(ch);
    if (idx >= 0) {
      buf.write(noAccents[idx]);
    } else {
      buf.write(ch);
    }
  }
  return buf.toString();
}

/// Encuentra un libro por nombre o abreviatura (case-insensitive,
/// accent-insensitive).
Libro? _findLibro(List<Libro> libros, String query) {
  final normalizedQuery = _normalizeBookName(query);
  // 1) Match exacto por nombre normalizado.
  for (final l in libros) {
    if (_normalizeBookName(l.nombre) == normalizedQuery) return l;
  }
  // 2) Match exacto por abreviatura.
  for (final l in libros) {
    if (_normalizeBookName(l.abreviatura) == normalizedQuery) return l;
  }
  // 3) Match por "startsWith" en el nombre (ej. "Jua" → "Juan").
  for (final l in libros) {
    final n = _normalizeBookName(l.nombre);
    if (n.startsWith(normalizedQuery) || normalizedQuery.startsWith(n)) {
      return l;
    }
  }
  return null;
}

class _RefResultsList extends ConsumerWidget {
  const _RefResultsList({
    required this.query,
    required this.versionId,
  });

  final String query;
  final int versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final bibliaRepo = ref.read(bibliaRepositoryProvider);
    final crossRefsRepo = ref.read(crossReferenciasRepositoryProvider);

    // Primero parsear el query. Si no parsea, mostrar hint.
    final parsed = _parseReference(query);
    if (parsed == null) {
      return _EmptyHint(
        icon: Icons.link_off_rounded,
        text: 'Formato inválido. Usa "Libro cap:ver" '
            '(ej. Juan 3:16, 1 Juan 4:9)',
        color: colorScheme.onSurfaceVariant,
      );
    }

    // Resolver libro desde el nombre.
    return FutureBuilder<List<Libro>>(
      future: bibliaRepo.getLibrosByVersion(versionId),
      builder: (context, libSnap) {
        if (!libSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final libro = _findLibro(libSnap.data!, parsed.libroNombre);
        if (libro == null) {
          return _EmptyHint(
            icon: Icons.search_off_rounded,
            text: 'Libro "${parsed.libroNombre}" no encontrado en esta versión',
            color: colorScheme.onSurfaceVariant,
          );
        }

        // Buscar refs que LLEGAN a este versículo destino.
        return FutureBuilder<List<CrossReferencia>>(
          future: crossRefsRepo.getByToVerse(
            versionId: versionId,
            libroId: libro.id,
            capitulo: parsed.capitulo,
            versiculo: parsed.versiculo,
          ),
          builder: (context, refsSnap) {
            if (refsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (refsSnap.hasError) {
              return Center(
                child: Text(
                  'Error: ${refsSnap.error}',
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            }
            final refs = refsSnap.data ?? const <CrossReferencia>[];
            if (refs.isEmpty) {
              return _EmptyHint(
                icon: Icons.link_off_rounded,
                text: 'Ningún versículo cita a '
                    '${libro.nombre} ${parsed.capitulo}:${parsed.versiculo}',
                color: colorScheme.onSurfaceVariant,
              );
            }
            // Resolver los libros FROM para mostrar "Juan 3:16" etc.
            // Optimización: 1 sola pasada por cada from_libro_id único.
            final fromLibroIds = refs.map((r) => r.fromLibroId).toSet();
            return FutureBuilder<List<Libro>>(
              future: () async {
                final result = <Libro>[];
                for (final id in fromLibroIds) {
                  final l = await bibliaRepo.getLibroById(id);
                  if (l != null) result.add(l);
                }
                return result;
              }(),
              builder: (context, fromLibrosSnap) {
                final fromLibros = fromLibrosSnap.data ?? const <Libro>[];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${refs.length} versículo${refs.length == 1 ? '' : 's'} '
                          'cita${refs.length == 1 ? '' : 'n'} a '
                          '${libro.nombre} ${parsed.capitulo}:${parsed.versiculo}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: refs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _RefResultCard(
                          ref: refs[i],
                          fromLibros: fromLibros,
                          versionId: versionId,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RefResultCard extends ConsumerWidget {
  const _RefResultCard({
    required this.ref,
    required this.fromLibros,
    required this.versionId,
  });

  final CrossReferencia ref;
  final List<Libro> fromLibros;
  final int versionId;

  @override
  Widget build(BuildContext context, WidgetRef refW) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fromLibro = fromLibros.firstWhere(
      (l) => l.id == ref.fromLibroId,
      orElse: () => Libro(
        id: ref.fromLibroId,
        versionId: versionId,
        nombre: 'Libro ${ref.fromLibroId}',
        abreviatura: 'L${ref.fromLibroId}',
        testamento: Testamento.at,
        numero: 0,
        totalCapitulos: 0,
      ),
    );
    // El lado FROM siempre es un versículo único (el schema solo tiene
    // fromVersiculo, sin inicio/fin). El rango está en el lado TO, que
    // es justamente el versículo destino que el usuario buscó.
    final refLabel =
        '${fromLibro.abreviatura} ${ref.fromCapitulo}:${ref.fromVersiculo}';

    return GlassCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _openReader(context, refW, fromLibro),
      child: Row(
        children: [
          Icon(
            Icons.link_rounded,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  refLabel,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cita este versículo',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Badge con votos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${ref.votos}★',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  void _openReader(BuildContext context, WidgetRef refW, Libro fromLibro) {
    refW.read(currentVersionIdProvider.notifier).state = versionId;
    refW.read(currentLibroIdProvider.notifier).state = fromLibro.id;
    refW.read(currentCapituloProvider.notifier).state = ref.fromCapitulo;
    refW.read(currentVersiculoNumeroProvider.notifier).state = ref.fromVersiculo;
    refW
        .read(readerViewModeProvider.notifier)
        .setViewMode(BibleReaderViewMode.chapter);
    if (!context.mounted) return;
    context.pushNamed(
      'biblia_reader',
      pathParameters: <String, String>{
        'libroId': '${fromLibro.id}',
        'capitulo': '${ref.fromCapitulo}',
      },
      queryParameters: <String, String>{
        'v': '${ref.fromVersiculo}',
      },
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
