import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/himno_tipo.dart';
import '../../../core/network/connection_state.dart';
import '../../../domain/entities/himno.dart';
import '../../dual_mode_wrapper/dual_mode_providers.dart';
import '../../../core/utils/string_utils.dart';
import '../../shared_widgets/alphabet_index_bar.dart';
import '../../shared_widgets/search_bar.dart';
import '../../shared_widgets/hymn_card.dart';
import '../../views_projection/controller/widgets/discover_display_sheet.dart'
    show DiscoverDisplaySheet;
import '../../views_projection/display/receptor_binding.dart';
import '../../views_projection/providers/connection_providers.dart';
import '../../views_projection/providers/presentation_providers.dart';
import '../../views_projection/providers/projection_actions.dart'
    show projectHymn;
import '../../views_admin/admin_panel_screen.dart';
import '../providers/hymn_providers.dart';
import '../../providers/wakelock_provider.dart';
import 'connected_dashboard.dart';

/// Tipos de filtro para himnos.
enum HymnFilter {
  todos,
  oficiales,
  inspiradas,
  convenciones,
}

/// Orden de clasificación para la lista de himnos.
enum HymnSortOrder {
  numeroAsc,
  tituloAsc,
  tituloDesc,
}

/// Pantalla de inicio / Dashboard del Controlador.
///
/// Según el rol de conexión ([connectionRoleProvider]):
/// - [ConnectionRole.receiver] → [StandbyScreen] envuelto en [ReceptorBinding]
/// - [ConnectionRole.emitter] → [ConnectedDashboard]
/// - [ConnectionRole.none] → Interfaz normal con buscador, filtros y lista
///
/// En modo Desktop con presentación activa ([isPresentingProvider] es `true`),
/// muestra un [PresentControlBar] como overlay en la parte inferior y oculta
/// el FAB "Presentar".
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  HymnFilter _selectedFilter = HymnFilter.todos;
  HymnSortOrder _sortOrder = HymnSortOrder.numeroAsc;
  int? _selectedCategoriaId;
  String? _selectedCategoriaNombre;
  String _searchQuery = '';
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  List<Himno>? _cachedHimnos;
  List<GlobalKey> _itemKeys = [];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Carga un himno en el provider de control en vivo sin navegar.
  ///
  /// Se ejecuta cuando [isPresentingProvider] es `true` y se toca un himno.
  /// Proyecta el himno en la ventana secundaria (a través del provider) y
  /// actualiza el [PresentControlBar] con el título. No se navega a otra
  /// pantalla — el control permanece como overlay en HomeScreen.
  ///
  /// También envía el himno completo a la segunda ventana de proyección
  /// vía [WindowService.sendMessage] usando el protocolo JSON stdin/stdout.
  Future<void> _selectHymnForProjection(
    BuildContext context,
    WidgetRef ref,
    Himno himno,
  ) async {
    final error = await projectHymn(ref, himno);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar himno: $error')),
      );
    }
  }

  /// Obtiene el valor [HimnoTipo] según el filtro seleccionado.
  HimnoTipo? _filterToTipo() {
    switch (_selectedFilter) {
      case HymnFilter.oficiales:
        return HimnoTipo.oficial;
      case HymnFilter.inspiradas:
        return HimnoTipo.inspirada;
      case HymnFilter.convenciones:
        return HimnoTipo.convencion;
      case HymnFilter.todos:
        return null;
    }
  }

  /// Convierte [HymnSortOrder] a la cláusula SQL usada por el repositorio.
  String? _orderByToSql() {
    switch (_sortOrder) {
      case HymnSortOrder.tituloAsc:
        return 'titulo_principal ASC';
      case HymnSortOrder.tituloDesc:
        return 'titulo_principal DESC';
      case HymnSortOrder.numeroAsc:
        return null; // usa el default del repositorio: h.numero_oficial ASC
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final role = ref.watch(connectionRoleProvider);

    // ── Modo Receptor: StandbyScreen ↔ LiveProjectionScreen según himno ──
    if (role == ConnectionRole.receiver) {
      final display = ref.watch(receptorDisplayProvider);
      return ReceptorBinding(child: display);
    }

    // ── Modo Emisor: ConnectedDashboard ──
    if (role == ConnectionRole.emitter) {
      return const ConnectedDashboard();
    }

    // ── Modo normal (sin rol de conexión) ──
    final connectionState = ref.watch(connectionStateProvider);
    final isConnected = connectionState is Connected;

    // Escuchar el provider de himnos con los parámetros actuales
    final hymnQuery = HymnQueryParam(
      text: _searchQuery,
      tipo: _filterToTipo(),
      orderBy: _orderByToSql(),
      categoriaId: _selectedCategoriaId,
    );
    final hymnsAsync = ref.watch(hymnListProvider(hymnQuery));

    final isDesktop = ref.watch(isDesktopModeProvider);
    final isPresenting = ref.watch(isPresentingProvider);

    // Activar wakelock en modo desktop para evitar suspensión del PC
    if (isDesktop) {
      ref.read(wakelockProvider.notifier).enable();
    } else {
      ref.read(wakelockProvider.notifier).disable();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MQ App'),
        leading: IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
          ),
          tooltip: 'Configuración',
        ),
        actions: [
          // Botón de conexión: abre el DiscoverDisplaySheet
          IconButton(
            onPressed: () => _openDiscoverySheet(context),
            icon: Icon(
              connectionState is Connected
                  ? Icons.cast_connected_rounded
                  : Icons.cast_rounded,
              color: connectionState is ConnectionError
                  ? colorScheme.error
                  : isConnected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
            ),
            tooltip: switch (connectionState) {
              final Connected c => 'Conectado a ${c.device.name}',
              ConnectionError _ => 'Error de conexi\u00f3n',
              _ => 'Conectar display',
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: HymnSearchBar(
              controller: _searchController,
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), () {
                  if (mounted) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  }
                });
              },
              onClear: () {
                _debounce?.cancel();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),

          // Chips de filtrado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  'Todos',
                  HymnFilter.todos,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Oficiales',
                  HymnFilter.oficiales,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Inspiradas',
                  HymnFilter.inspiradas,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Convención',
                  HymnFilter.convenciones,
                ),
                const SizedBox(width: 8),
                _buildSortChip(context, 'A-Z', HymnSortOrder.tituloAsc),
                const SizedBox(width: 8),
                _buildSortChip(context, 'Z-A', HymnSortOrder.tituloDesc),
                const SizedBox(width: 8),
                _buildCategoryChip(context),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de himnos con manejo de estados async
          Expanded(
            child: Stack(
              children: [
                hymnsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar himnos',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            // Forzar recarga invalidando el provider
                            ref.invalidate(hymnListProvider(hymnQuery));
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                  data: (himnos) {
                    _cachedHimnos = himnos;
                    if (_itemKeys.length != himnos.length) {
                      _itemKeys = List.generate(himnos.length, (_) => GlobalKey());
                    }
                    if (himnos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No se encontraron himnos para "$_searchQuery"'
                                  : 'No hay himnos disponibles',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: _sortOrder == HymnSortOrder.numeroAsc ? 16 : 40,
                        top: 0,
                        bottom: 0,
                      ),
                      itemCount: himnos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final himno = himnos[index];
                        return HymnCard(
                          key: _itemKeys[index],
                          himno: himno,
                          onTap: () {
                            if (isPresenting && isDesktop) {
                              _selectHymnForProjection(
                                context,
                                ref,
                                himno,
                              );
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/hymn-detail',
                                arguments: himno,
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
                _buildAlphabetScrollbar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlphabetScrollbar() {
    if (_sortOrder == HymnSortOrder.numeroAsc) return const SizedBox.shrink();

    return Positioned(
      right: 2,
      top: 0,
      bottom: 0,
      child: AlphabetIndexBar(
        onLetterSelected: _scrollToLetter,
      ),
    );
  }

  void _scrollToLetter(String letter) {
    final himnos = _cachedHimnos;
    if (himnos == null || himnos.isEmpty || !_scrollController.hasClients) return;

    final targetLetter = letter.toUpperCase();
    final index = himnos.indexWhere((h) {
      final normalized = StringUtils.normalizeForSort(h.titulo);
      return normalized.isNotEmpty &&
          normalized[0].toUpperCase() == targetLetter;
    });

    if (index == -1 || index >= _itemKeys.length) return;

    final key = _itemKeys[index];

    // Calcular offset usando maxScrollExtent como referencia precisa
    final maxScroll = _scrollController.position.maxScrollExtent;
    final itemCount = himnos.length;
    // Estimación basada en el scroll total real (más precisa que un height fijo)
    final estimatedOffset = (maxScroll / itemCount) * index;
    _scrollController.jumpTo(estimatedOffset.clamp(0.0, maxScroll));

    // ensureVisible para precisión exacta post-frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null && key.currentContext!.mounted) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    });
  }

  /// Abre el BottomSheet de descubrimiento y conexión de displays.
  void _openDiscoverySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const DiscoverDisplaySheet(),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    HymnFilter filter,
  ) {
    final isSelected = _selectedFilter == filter;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: textTheme.labelMedium?.copyWith(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildSortChip(BuildContext context, String label, HymnSortOrder order) {
    final isSelected = _sortOrder == order;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortOrder = selected ? order : HymnSortOrder.numeroAsc;
        });
      },
      selectedColor: colorScheme.tertiaryContainer,
      checkmarkColor: colorScheme.onTertiaryContainer,
      labelStyle: textTheme.labelMedium?.copyWith(
        color: isSelected
            ? colorScheme.onTertiaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      label: Text(_selectedCategoriaNombre ?? 'Categoría'),
      selected: _selectedCategoriaId != null,
      onSelected: (_) {
        _showCategoryPicker(context);
      },
      selectedColor: colorScheme.secondaryContainer,
      checkmarkColor: colorScheme.onSecondaryContainer,
      avatar: _selectedCategoriaId != null
          ? Icon(Icons.close, size: 16, color: colorScheme.onSecondaryContainer)
          : Icon(Icons.arrow_drop_down, size: 20, color: colorScheme.onSurfaceVariant),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        // Envolver en Consumer para que Riverpod pueda reconstruir
        // este subtree independientemente cuando categoriasProvider se resuelva
        return Consumer(
          builder: (context, ref, _) {
            final categoriasAsync = ref.watch(categoriasProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Filtrar por categoría',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Todas las categorías'),
                  selected: _selectedCategoriaId == null,
                  onTap: () {
                    setState(() {
                      _selectedCategoriaId = null;
                      _selectedCategoriaNombre = null;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(),
                categoriasAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $e'),
                  ),
                  data: (categorias) => LimitedBox(
                    maxHeight: 300,
                    child: ListView(
                      shrinkWrap: true,
                      children: categorias.map((cat) {
                        return ListTile(
                          leading: Icon(
                            Icons.label_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(cat.nombre),
                          selected: _selectedCategoriaId == cat.id,
                          trailing: _selectedCategoriaId == cat.id
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCategoriaId = cat.id;
                              _selectedCategoriaNombre = cat.nombre;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }
}
