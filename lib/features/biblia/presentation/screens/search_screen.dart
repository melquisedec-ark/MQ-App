import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/shared_widgets/glass_card.dart';
import '../../application/providers/biblia_version_provider.dart';
import '../../application/providers/current_libro_provider.dart';
import '../../application/providers/current_versiculo_provider.dart';
import '../../application/providers/derived_providers.dart';
import '../../application/providers/reader_providers.dart';
import '../../data/models/versiculo_contexto.dart';
import '../widgets/verse_card.dart' show BibleReaderViewMode;
import '../widgets/version_picker_sheet.dart';

/// Pantalla de búsqueda FTS5 con debounce.
///
/// Referencia: `doc/wireframes/02_bible_module.md` (Pantalla 2c - búsqueda).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
          decoration: const InputDecoration(
            hintText: 'Buscar versículos...',
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
      ),
      body: SafeArea(
        child: _buildBody(context, versionId),
      ),
    );
  }

  Widget _buildBody(BuildContext context, int versionId) {
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
