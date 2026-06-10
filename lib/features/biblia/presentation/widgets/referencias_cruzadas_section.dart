import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/app_snackbar.dart';
import '../../application/providers/biblia_version_provider.dart';
import '../../application/providers/cross_referencias_provider.dart';
import '../../application/providers/current_libro_provider.dart';
import '../../application/providers/current_versiculo_provider.dart';
import '../../application/providers/reader_providers.dart';
import '../../data/models/cross_referencia.dart';
import '../../data/models/libro.dart';

/// Versículo + libro destino resueltos (nombre canónico + abreviatura).
///
/// Es la versión "amigable" de [CrossReferencia] que ya tiene
/// `libro.nombre` y `libro.abreviatura` resueltos, lista para
/// mostrarse en la UI sin lookups adicionales.
class CrossReferenciaResuelta extends Equatable {
  const CrossReferenciaResuelta({
    required this.ref,
    required this.libroNombre,
    required this.libroAbreviatura,
    this.previewTexto,
  });

  final CrossReferencia ref;
  final String libroNombre;
  final String libroAbreviatura;

  /// Feature #2: preview del texto del versículo destino (~50 chars).
  final String? previewTexto;

  /// Etiqueta corta para mostrar. "Génesis 22:12" o "1 Juan 4:9-10".
  String get etiquetaCorta {
    final base = '$libroNombre ${ref.toCapitulo}:${ref.toVersiculoInicio}';
    if (ref.esRango) {
      return '$base-${ref.toVersiculoFin}';
    }
    return base;
  }

  /// Etiqueta compacta. Útil para espacios angostos.
  /// "Gn 22:12" o "1Jn 4:9-10".
  String get etiquetaCompacta {
    final base =
        '$libroAbreviatura ${ref.toCapitulo}:${ref.toVersiculoInicio}';
    if (ref.esRango) {
      return '$base-${ref.toVersiculoFin}';
    }
    return base;
  }

  @override
  List<Object?> get props => [ref, libroNombre, libroAbreviatura, previewTexto];
}

/// Provider derivado que combina [crossReferenciasConPreviewProvider] con el
/// nombre del libro destino (resuelto por `BibliaRepository.getLibroById`).
///
/// Feature #2: usa la query con preview para obtener el texto del versículo
/// destino. Esto evita N+1 queries en el widget resolviendo todos los
/// `to_libro_id` en una sola pasada. Si un `to_libro_id` no se encuentra
/// en la versión actual (caso raro: apócrifo), se usa un placeholder
/// "Libro N" en vez de crashear.
final crossReferenciasResueltasProvider = FutureProvider.family
    .autoDispose<List<CrossReferenciaResuelta>, CrossRefQuery>(
        (ref, query) async {
  final refsAsync = ref.watch(crossReferenciasConPreviewProvider(query));
  final refs = refsAsync.valueOrNull;
  if (refs == null || refs.isEmpty) {
    return refsAsync.when(
      data: (_) => const <CrossReferenciaResuelta>[],
      loading: () => const <CrossReferenciaResuelta>[],
      error: (_, __) => const <CrossReferenciaResuelta>[],
    );
  }

  // Batch resolve: una sola pasada por cada to_libro_id único.
  final bibliaRepo = ref.read(bibliaRepositoryProvider);
  final toLibroIds = refs.map((r) => r.toLibroId).toSet();
  final libros = <int, Libro>{};
  for (final id in toLibroIds) {
    final libro = await bibliaRepo.getLibroById(id);
    if (libro != null) {
      libros[id] = libro;
    }
  }

  return refs.map((r) {
    final libro = libros[r.toLibroId];
    return CrossReferenciaResuelta(
      ref: r,
      libroNombre: libro?.nombre ?? 'Libro ${r.toLibroId}',
      libroAbreviatura: libro?.abreviatura ?? '?${r.toLibroId}',
      previewTexto: r.previewTexto,
    );
  }).toList(growable: false);
});

/// Sección colapsable de cross-references para verse mode.
///
/// Se muestra DESPUÉS del texto del versículo y ANTES de la sección
/// de nota (orden: texto → refs → nota). Si no hay refs, no se
/// renderiza (espacio vacío).
///
/// Comportamiento:
/// - 0 refs → invisible (`SizedBox.shrink`).
/// - 1 ref → se muestra inline (header + la ref).
/// - 2+ refs → se muestran 2, luego "Ver todas (N)" expandible.
/// - Tap en cita → expande el preview del versículo.
/// - Tap en preview expandido → navega al capítulo destino (deep link).
class ReferenciasCruzadasSection extends ConsumerStatefulWidget {
  const ReferenciasCruzadasSection({
    super.key,
    required this.libroId,
    required this.capitulo,
    required this.versiculo,
  });

  final int libroId;
  final int capitulo;
  final int versiculo;

  @override
  ConsumerState<ReferenciasCruzadasSection> createState() =>
      _ReferenciasCruzadasSectionState();
}

class _ReferenciasCruzadasSectionState
    extends ConsumerState<ReferenciasCruzadasSection> {
  /// Modo de colapso: `false` = solo se ven las primeras 2 refs.
  bool _expandido = false;

  /// Índice de la referencia con preview expandido o -1 si ninguna.
  int _expandedRefIndex = -1;

  /// Cantidad de refs a mostrar sin expandir.
  static const int _refsVisiblesIniciales = 2;

  @override
  Widget build(BuildContext context) {
    final query = CrossRefQuery(
      libroId: widget.libroId,
      capitulo: widget.capitulo,
      versiculo: widget.versiculo,
    );
    final asyncResueltas = ref.watch(crossReferenciasResueltasProvider(query));

    // Loading y error: silenciosos (verse mode no debe mostrar spinner
    // por una feature secundaria como refs).
    final resueltas = asyncResueltas.maybeWhen(
      data: (list) => list,
      orElse: () => const <CrossReferenciaResuelta>[],
    );
    if (resueltas.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final refsVisibles = _expandido
        ? resueltas
        : resueltas.take(_refsVisiblesIniciales).toList(growable: false);
    final hayMas = resueltas.length > _refsVisiblesIniciales;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${resueltas.length} '
                  '${resueltas.length == 1 ? 'referencia' : 'referencias'}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Lista de refs: tap → expandir preview, tap en preview → navegar
          ...refsVisibles.asMap().entries.map(
            (entry) => _ReferenciaTile(
              resuelta: entry.value,
              expanded: _expandedRefIndex == entry.key,
              onTap: () => _handleRefTap(entry.key, entry.value, context),
            ),
          ),
          // Botón "Ver todas (N)" / "Ver menos"
          if (hayMas)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                onTap: () => setState(() => _expandido = !_expandido),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expandido
                            ? 'Ver menos'
                            : 'Ver todas (${resueltas.length})',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expandido
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Tap en una referencia: si no está expandida, la expande. Si ya está
  /// expandida, navega al capítulo destino.
  void _handleRefTap(int index, CrossReferenciaResuelta resuelta, BuildContext context) {
    if (_expandedRefIndex == index) {
      // Ya expandida → navegar
      _navigateTo(resuelta, context);
    } else {
      // Expandir esta, colapsar la anterior
      setState(() => _expandedRefIndex = index);
    }
  }
  ///
  /// Bug #1 fix: salva y restaura el estado global de providers alrededor
  /// de la navegación para que al volver (pop) el lector original conserve
  /// su posición y modo de vista.
  ///
  /// Si `to_libro_id` no existe en la versión actual, muestra SnackBar
  /// "Versículo no disponible en esta versión" y NO navega.
  Future<void> _navigateTo(
    CrossReferenciaResuelta resuelta,
    BuildContext context,
  ) async {
    final bibliaRepo = ref.read(bibliaRepositoryProvider);
    final toLibro = await bibliaRepo.getLibroById(resuelta.ref.toLibroId);
    if (!context.mounted) return;
    if (toLibro == null) {
      showAppSnackBar(
        context,
        'Versículo no disponible en esta versión',
        type: AppSnackBarType.warning,
      );
      return;
    }
    // Salvar estado actual de los providers globales antes de navegar.
    final prevLibroId = ref.read(currentLibroIdProvider);
    final prevCapitulo = ref.read(currentCapituloProvider);
    final prevVersiculo = ref.read(currentVersiculoNumeroProvider);
    final prevViewMode = ref.read(readerViewModeProvider);
    final prevCurrentVerse = ref.read(currentVerseProvider);

    try {
      // pushNamed a la misma ruta con nuevos params. go_router apila
      // una nueva entrada en el stack; context.pop() vuelve al lector
      // anterior (verificado por el wireframe 02 del Bible module).
      await context.pushNamed(
        'biblia_reader',
        pathParameters: <String, String>{
          'libroId': '${toLibro.id}',
          'capitulo': '${resuelta.ref.toCapitulo}',
        },
        queryParameters: <String, String>{
          'v': '${resuelta.ref.toVersiculoInicio}',
        },
      );
    } finally {
      // Restaurar estado global al volver de la navegación.
      if (context.mounted) {
        ref.read(currentLibroIdProvider.notifier).state = prevLibroId;
        ref.read(currentCapituloProvider.notifier).state = prevCapitulo;
        ref.read(currentVersiculoNumeroProvider.notifier).state = prevVersiculo;
        ref.read(readerViewModeProvider.notifier).setViewMode(prevViewMode);
        ref.read(currentVerseProvider.notifier).state = prevCurrentVerse;
      }
    }
  }
}

/// Tile tappable individual de una cross-reference.
///
/// Muestra la cita bíblica. Si está expandido, muestra el preview del
/// versículo debajo. Comportamiento:
/// - Tap en cita → expande/colapsa el preview.
/// - Tap en preview expandido → navega al capítulo destino.
class _ReferenciaTile extends StatelessWidget {
  const _ReferenciaTile({
    required this.resuelta,
    required this.expanded,
    required this.onTap,
  });

  final CrossReferenciaResuelta resuelta;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: expanded ? 'Toca para ir al capítulo' : resuelta.etiquetaCorta,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cita (siempre visible)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      resuelta.etiquetaCorta,
                      style: textTheme.bodyMedium?.copyWith(
                        color: expanded
                            ? colorScheme.primary
                            : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (resuelta.ref.esRango) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${resuelta.ref.votos}★',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.open_in_new_rounded : Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ],
              ),
              // Preview del versículo (solo visible si expandido)
              if (expanded && resuelta.previewTexto != null) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    resuelta.previewTexto!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
