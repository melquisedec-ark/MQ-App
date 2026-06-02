import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../presentation/shared_widgets/glass_card.dart';
import '../../data/models/biblia_version.dart';
import '../../data/models/nota.dart';
import '../../application/providers/biblia_config_provider.dart';
import '../../application/providers/biblia_version_provider.dart';

/// Pantalla de Configuración del módulo Biblia.
///
/// Lee/escribe en la tabla `config` de `biblia.db` vía [bibliaConfigRepositoryProvider].
/// Todos los cambios se persisten automáticamente (cada provider notifier
/// llama `repo.set(...)` en su setter).
///
/// Secciones (siguiendo wireframe 01 §settings):
/// - **Biblia**: versión por defecto, auto-historial, color de nota default
/// - **Emisor**: modo de vista por defecto (Compact/Preview)
/// - **Apariencia**: tema (Claro/Oscuro/Sistema), glassmorphism
/// - **Acerca de**: versión, link a GitHub
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Atrás',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          children: [
            // ── Biblia ──
            const _SectionHeader(title: 'Biblia'),
            const _Card(
              children: [
                _VersionDefaultTile(),
                _Divider(),
                _AutoHistorialTile(),
                _Divider(),
                _NotaColorDefaultTile(),
              ],
            ),
            const SizedBox(height: 24),

            // ── Emisor ──
            const _SectionHeader(title: 'Emisor'),
            const _Card(
              children: [
                _EmitterViewModeTile(),
              ],
            ),
            const SizedBox(height: 24),

            // ── Apariencia ──
            const _SectionHeader(title: 'Apariencia'),
            const _Card(
              children: [
                _ThemeModeTile(),
                _Divider(),
                _GlassmorphismTile(),
              ],
            ),
            const SizedBox(height: 24),

            // ── Acerca de ──
            const _SectionHeader(title: 'Acerca de'),
            _Card(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Versión'),
                  subtitle: const Text('1.0.0-dev+1'),
                ),
                const _Divider(),
                ListTile(
                  leading: Icon(
                    Icons.code_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Repositorio'),
                  subtitle: Text(
                    'github.com/melquisedec-ark/MQ-App',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _launchGitHub(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGitHub(BuildContext context) async {
    final uri = Uri.parse('https://github.com/melquisedec-ark/MQ-App');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el navegador')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el navegador')),
        );
      }
    }
  }
}

// ───────────────────────────────────────────────────────────────
// Widgets auxiliares
// ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
      indent: 56,
    );
  }
}

// ── Biblia ────────────────────────────────────────────────────

class _VersionDefaultTile extends ConsumerWidget {
  const _VersionDefaultTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(preferredBibliaVersionProvider);
    final versionsAsync = ref.watch(activeBibliaVersionsProvider);
    return ListTile(
      leading: const Icon(Icons.translate_rounded),
      title: const Text('Versión por defecto'),
      subtitle: Text(_labelFor(current, versionsAsync.valueOrNull)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _showVersionPicker(context, ref, versionsAsync, current),
    );
  }

  String _labelFor(String abreviatura, List<BibliaVersion>? versions) {
    if (versions == null) return abreviatura;
    final match = versions.firstWhere(
      (v) => v.abreviatura == abreviatura,
      orElse: () => versions.first,
    );
    return match.nombre;
  }

  void _showVersionPicker(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BibliaVersion>> versionsAsync,
    String current,
  ) {
    versionsAsync.whenData((versions) {
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Versión por defecto',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              for (final v in versions)
                RadioListTile<String>(
                  title: Text(v.nombre),
                  subtitle: Text(v.abreviatura),
                  value: v.abreviatura,
                  groupValue: current,
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(preferredBibliaVersionProvider.notifier)
                          .setVersion(val);
                      Navigator.pop(ctx);
                    }
                  },
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _AutoHistorialTile extends ConsumerWidget {
  const _AutoHistorialTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(autoHistorialProvider);
    return SwitchListTile(
      secondary: const Icon(Icons.history_rounded),
      title: const Text('Registrar historial'),
      subtitle: const Text('Guarda cada versículo que lees'),
      value: value,
      onChanged: (v) =>
          ref.read(autoHistorialProvider.notifier).setEnabled(v),
    );
  }
}

class _NotaColorDefaultTile extends ConsumerWidget {
  const _NotaColorDefaultTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(notaColorDefaultProvider);
    return ListTile(
      leading: const Icon(Icons.palette_rounded),
      title: const Text('Color de nota por defecto'),
      subtitle: Text(_labelFor(current)),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _colorFor(current),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      onTap: () => _showColorPicker(context, ref, current),
    );
  }

  String _labelFor(NotaColor color) {
    switch (color) {
      case NotaColor.amarillo:
        return 'Amarillo';
      case NotaColor.verde:
        return 'Verde';
      case NotaColor.azul:
        return 'Azul';
      case NotaColor.ninguno:
        return 'Ninguno (sin color)';
    }
  }

  Color _colorFor(NotaColor color) {
    switch (color) {
      case NotaColor.amarillo:
        return const Color(0xFFF59E0B);
      case NotaColor.verde:
        return const Color(0xFF10B981);
      case NotaColor.azul:
        return const Color(0xFF3B82F6);
      case NotaColor.ninguno:
        return Colors.transparent;
    }
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, NotaColor current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Color por defecto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            for (final c in NotaColor.values)
              ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _colorFor(c),
                ),
                title: Text(_labelFor(c)),
                trailing: c == current
                    ? const Icon(Icons.check_rounded, color: AppColors.gold)
                    : null,
                onTap: () {
                  ref.read(notaColorDefaultProvider.notifier).setColor(c);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Emisor ────────────────────────────────────────────────────

class _EmitterViewModeTile extends ConsumerWidget {
  const _EmitterViewModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(emitterViewModeDefaultProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_agenda_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Modo de vista del emisor'),
                    Text(
                      'Cambia entre Compact y Preview',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'compact',
                label: Text('Compact'),
                icon: Icon(Icons.short_text_rounded),
              ),
              ButtonSegment(
                value: 'preview',
                label: Text('Preview'),
                icon: Icon(Icons.article_outlined),
              ),
            ],
            selected: {current},
            onSelectionChanged: (sel) {
              ref
                  .read(emitterViewModeDefaultProvider.notifier)
                  .setMode(sel.first);
            },
          ),
        ],
      ),
    );
  }
}

// ── Apariencia ────────────────────────────────────────────────

class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(current)),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Tema de la aplicación'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Claro'),
                icon: Icon(Icons.light_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Oscuro'),
                icon: Icon(Icons.dark_mode_rounded),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Sistema'),
                icon: Icon(Icons.brightness_auto_rounded),
              ),
            ],
            selected: {current},
            onSelectionChanged: (sel) {
              ref.read(themeModeProvider.notifier).setThemeMode(sel.first);
            },
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }
}

class _GlassmorphismTile extends ConsumerWidget {
  const _GlassmorphismTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(glassmorphismEnabledProvider);
    return SwitchListTile(
      secondary: const Icon(Icons.blur_on_rounded),
      title: const Text('Glassmorphism'),
      subtitle: const Text('Efectos de cristal en cards y surfaces'),
      value: value,
      onChanged: (v) =>
          ref.read(glassmorphismEnabledProvider.notifier).setEnabled(v),
    );
  }
}
