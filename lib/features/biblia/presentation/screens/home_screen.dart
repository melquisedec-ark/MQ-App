import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/connection_state.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../core/window_manager/window_providers.dart';
import '../../../../presentation/shared_widgets/glass_card.dart';
import '../../../../presentation/shared_widgets/theme_mode_toggle_button.dart';
import '../../../../presentation/views_projection/providers/connection_providers.dart';
import '../../../../presentation/views_projection/providers/presentation_providers.dart';
import '../../application/providers/biblia_version_provider.dart';
import '../../application/providers/bible_grpc_client_provider.dart';
import '../../application/providers/current_libro_provider.dart';
import '../../application/providers/current_versiculo_provider.dart';
import '../../application/providers/favoritos_provider.dart';
import '../../application/providers/random_versiculo_provider.dart';
import '../../data/models/biblia_version.dart';
import '../../data/models/favorito_versiculo.dart';
import '../../data/models/versiculo_contexto.dart';
import '../widgets/version_picker_sheet.dart';

/// Pantalla principal (hub) de MQ App.
///
/// Muestra:
/// - Fila superior: ⚙️ Config (izq) + 📡 Conectar (der)
/// - Logo "MQ App" + tagline "Biblia + Himnario"
/// - Card de versículo aleatorio (con favorito, refresh, dropdown de versión)
/// - 2 cards grandes: 📖 Biblia + 🎵 Himnario
///
/// Referencia: `doc/wireframes/01_home_screen.md` y `05_style_guide.md`.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final connectionState = ref.watch(connectionStateProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.pushNamed('config'),
          tooltip: 'Configuración',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _ConnectButton(connectionState: connectionState),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo + tagline ──
                _LogoHeader(colorScheme: colorScheme, textTheme: textTheme),
                const SizedBox(height: 24),

                // ── Card de versículo del día ──
                const _RandomVerseCard(),
                const SizedBox(height: 24),

                // ── 2 cards principales ──
                const _ModuleCardsRow(),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: const ThemeModeToggleButton(),
          ),
        ],
      ),
      floatingActionButton: const _PresentFAB(),
    );
  }
}

/// Logo "MQ App" + tagline, centrados.
class _LogoHeader extends StatelessWidget {
  const _LogoHeader({required this.colorScheme, required this.textTheme});

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Icono + título en fila
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'MQ App',
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Biblia + Himnario',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de conexión (icono circular en top-right).
///
/// Muestra estado visual según el [ConnectionState]:
/// - Disconnected → outline gris
/// - Connecting → spinner gold
/// - Connected → cast_connected gold
/// - ConnectionError → error color
class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.connectionState});

  final ConnectionState connectionState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final IconData icon;
    final Color color;
    final String tooltip;

    switch (connectionState) {
      case Connecting _:
        icon = Icons.cast_connected_rounded;
        color = colorScheme.primary;
        tooltip = 'Buscando displays...';
      case Connected _:
        icon = Icons.cast_connected_rounded;
        color = colorScheme.primary;
        tooltip = 'Conectado';
      case ConnectionError _:
        icon = Icons.cast_rounded;
        color = colorScheme.error;
        tooltip = 'Error de conexión';
      case Disconnected _:
        icon = Icons.cast_rounded;
        color = colorScheme.onSurfaceVariant;
        tooltip = 'Conectar display';
    }

    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () => context.pushNamed('connect'),
      tooltip: tooltip,
    );
  }
}

/// Card grande con el versículo aleatorio del día.
class _RandomVerseCard extends ConsumerWidget {
  const _RandomVerseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final verseAsync = ref.watch(randomVersiculoProvider);
    final versionsAsync = ref.watch(activeBibliaVersionsProvider);
    final currentVersionId = ref.watch(currentVersionIdProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: título
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Versículo del día',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          verseAsync.when(
            data: (verse) => _VerseContent(verse: verse),
            loading: () => const _VerseLoading(),
            error: (e, _) => _VerseError(
              onRetry: () => ref.invalidate(randomVersiculoProvider),
            ),
          ),
          const SizedBox(height: 12),
          // Versión dropdown + acciones
          Row(
            children: [
              versionsAsync.maybeWhen(
                data: (versions) => _VersionChip(
                  versions: versions,
                  currentVersionId: currentVersionId,
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const Spacer(),
              const _RefreshButton(),
              const SizedBox(width: 8),
              const _FavoriteButton(),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _goToReader(context, ref),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Leer este versículo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navega al reader con el versículo actual.
  Future<void> _goToReader(BuildContext context, WidgetRef ref) async {
    final verse = ref.read(randomVersiculoProvider).valueOrNull;
    if (verse == null) return;
    final repo = ref.read(bibliaRepositoryProvider);
    final libro = await repo.getLibroByNumero(
      verse.versionId,
      verse.libroNumero,
    );
    if (libro == null || !context.mounted) return;
    // Setea estado global para que BibleReaderScreen lo lea
    ref.read(currentLibroIdProvider.notifier).state = libro.id;
    ref.read(currentLibroNumeroProvider.notifier).state = libro.numero;
    ref.read(currentCapituloProvider.notifier).state = verse.capituloNumero;
    ref.read(currentVersiculoNumeroProvider.notifier).state =
        verse.versiculo.numero;
    if (context.mounted) {
      context.pushNamed(
        'biblia_reader',
        pathParameters: {
          'libroId': '${libro.id}',
          'capitulo': '${verse.capituloNumero}',
        },
      );
    }
  }
}

/// Contenido del versículo (texto + referencia).
class _VerseContent extends ConsumerWidget {
  const _VerseContent({required this.verse});

  final VersiculoContexto? verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final v = verse;
    if (v == null) {
      return Text(
        'No hay versículos disponibles',
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto del versículo
        Text(
          '"${v.versiculo.texto}"',
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            height: 1.6,
            color: colorScheme.onSurface,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        // Referencia
        Text(
          v.referenciaLarga,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Estado de carga del versículo.
class _VerseLoading extends StatelessWidget {
  const _VerseLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cargando versículo...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Estado de error al cargar el versículo.
class _VerseError extends StatelessWidget {
  const _VerseError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudo cargar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Chip dropdown de versión (RV1909 ▼).
class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.versions,
    required this.currentVersionId,
  });

  final List<BibliaVersion> versions;
  final int currentVersionId;

  @override
  Widget build(BuildContext context) {
    final current = versions.firstWhere(
      (v) => v.id == currentVersionId,
      orElse: () => versions.first,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => VersionPickerSheet.show(
          context: context,
          versions: versions,
          currentVersionId: currentVersionId,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                current.abreviatura,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de refresh (genera otro versículo aleatorio).
class _RefreshButton extends ConsumerWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.refresh_rounded),
      onPressed: () {
        // Invalida el provider para forzar un nuevo fetch
        ref.invalidate(randomVersiculoProvider);
      },
      tooltip: 'Otro versículo',
      iconSize: 22,
    );
  }
}

/// Botón de favorito (toggle sobre el versículo actual).
class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final verse = ref.watch(randomVersiculoProvider).valueOrNull;
    if (verse == null) {
      return IconButton(
        icon: Icon(
          Icons.star_outline_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        onPressed: null,
        tooltip: 'Favorito (cargando)',
        iconSize: 22,
      );
    }
    final VersiculoContexto verseNonNull = verse;

    final favoritosAsync = ref.watch(favoritosStreamProvider);
    final isFav = favoritosAsync.maybeWhen(
      data: (list) => list.any(
        (f) => _matchesFavorito(
          f,
          versionId: verseNonNull.versionId,
          libroId: null, // No tenemos libroId aquí; usamos número canónico
          libroNumero: verseNonNull.libroNumero,
          capitulo: verseNonNull.capituloNumero,
          numero: verseNonNull.versiculo.numero,
        ),
      ),
      orElse: () => false,
    );

    return IconButton(
      icon: Icon(
        isFav ? Icons.star_rounded : Icons.star_outline_rounded,
        color: isFav ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      onPressed: () =>
          _toggleFavorito(context, ref, verseNonNull, isFav),
      tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
      iconSize: 22,
    );
  }

  /// Verifica si un favorito coincide con el versículo actual.
  ///
  /// Comparamos por número canónico del libro (no por `libroId` que es
  /// por versión). Hacemos un lookup de libroId por número al guardar.
  bool _matchesFavorito(
    FavoritoVersiculo fav, {
    required int versionId,
    required int? libroId,
    required int libroNumero,
    required int capitulo,
    required int numero,
  }) {
    return fav.versionId == versionId &&
        fav.capitulo == capitulo &&
        fav.numero == numero;
  }

  /// Toggle del favorito. Si ya está, lo quita. Si no, lo agrega.
  Future<void> _toggleFavorito(
    BuildContext context,
    WidgetRef ref,
    VersiculoContexto verse,
    bool isFav,
  ) async {
    final repo = ref.read(favoritosRepositoryProvider);
    final biblia = ref.read(bibliaRepositoryProvider);
    final libro = await biblia.getLibroByNumero(verse.versionId, verse.libroNumero);
    if (libro == null || !context.mounted) return;
    if (isFav) {
      await repo.remove(
        verse.versionId,
        libro.id,
        verse.capituloNumero,
        verse.versiculo.numero,
      );
      if (context.mounted) {
        _showSnack(
          context,
          'Quitado de favoritos',
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => repo.add(
              verse.versionId,
              libro.id,
              verse.capituloNumero,
              verse.versiculo.numero,
            ),
          ),
        );
      }
    } else {
      await repo.add(
        verse.versionId,
        libro.id,
        verse.capituloNumero,
        verse.versiculo.numero,
      );
      if (context.mounted) {
        _showSnack(
          context,
          'Agregado a favoritos',
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => repo.remove(
              verse.versionId,
              libro.id,
              verse.capituloNumero,
              verse.versiculo.numero,
            ),
          ),
        );
      }
    }
  }

  void _showSnack(
    BuildContext context,
    String text, {
    SnackBarAction? action,
  }) {
    showAppSnackBar(context, text, action: action);
  }
}

/// Fila con 2 cards: Biblia + Himnario (50/50).
class _ModuleCardsRow extends StatelessWidget {
  const _ModuleCardsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModuleCard(
            icon: Icons.menu_book_rounded,
            title: 'BIBLIA',
            subtitle: 'Reina Valera 1909 / 1569',
            onTap: () => context.pushNamed('biblia'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ModuleCard(
            icon: Icons.music_note_rounded,
            title: 'HIMNARIO',
            subtitle: 'Himnos disponibles',
            onTap: () => context.pushNamed('himnario'),
          ),
        ),
      ],
    );
  }
}

/// Card individual para un módulo principal.
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '$title, botón. Abre el módulo de $title.',
      button: true,
      child: SizedBox(
        height: 160,
        child: GlassCard(
          onTap: onTap,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 40, color: colorScheme.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FAB para iniciar/detener la presentación desde la home de Biblia.
///
/// Alterna la ventana de proyección y el estado [isPresentingProvider].
class _PresentFAB extends ConsumerWidget {
  const _PresentFAB();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPresenting = ref.watch(isPresentingProvider);
    return FloatingActionButton.extended(
      heroTag: 'present_button_bible_home',
      onPressed: () async {
        final windowService = ref.read(windowServiceProvider);
        try {
          if (isPresenting) {
            await windowService.closeProjectionWindow();
            ref.read(isPresentingProvider.notifier).state = false;
          } else {
            await windowService.openProjectionWindow({
              'mode': 'local',
              'source': 'bible_home',
            });
            ref.read(isPresentingProvider.notifier).state = true;
          }
        } catch (e) {
          if (context.mounted) {
            showAppSnackBar(context, 'Error: $e', type: AppSnackBarType.error);
          }
        }
      },
      backgroundColor: isPresenting
          ? Theme.of(context).colorScheme.errorContainer
          : const Color(0xFFCCA43B),
      foregroundColor: const Color(0xFF1A1A1A),
      icon: Icon(isPresenting ? Icons.stop_screen_share : Icons.screen_share),
      label: Text(isPresenting ? 'Detener Presentación' : 'Presentar'),
    );
  }
}
