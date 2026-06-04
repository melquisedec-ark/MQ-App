import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ui/app_snackbar.dart';

/// Pantalla "Acerca de" de MQ-App.
///
/// Muestra:
/// - Logo (placeholder por ahora, no se carga asset).
/// - Nombre app + versión real (leída de [PackageInfo]).
/// - Tagline.
/// - Tarjeta "Información" con repositorio GitHub, página oficial, comunidad,
///   licencia.
/// - Botón "Volver".
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '…';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    // PackageInfo requiere que la inicialización del canal de plataforma
    // haya ocurrido; usamos addPostFrameCallback para diferir la lectura.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final info = await PackageInfo.fromPlatform();
        if (!mounted) return;
        setState(() {
          _version = info.version;
          _buildNumber = info.buildNumber;
        });
      } catch (_) {
        // Si falla (ej. tests), dejamos el placeholder.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Atrás',
        ),
        title: const Text('Acerca de'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo + nombre app ──
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 96,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MQ-App',
                textAlign: TextAlign.center,
                style: textTheme.displayMedium?.copyWith(
                  color: const Color(0xFFCCA43B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'v$_version${_buildNumber.isNotEmpty ? ' ($_buildNumber)' : ''}',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Biblia y Himnario en un solo lugar',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),

              // ── Tarjeta Información ──
              Card(
                elevation: 1,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.code_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Repositorio'),
                      subtitle: const Text(
                        'github.com/melquisedec-ark/MQ-App',
                      ),
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                      ),
                      onTap: () => _launchUrl(
                        context,
                        'https://github.com/melquisedec-ark/MQ-App',
                        'No se pudo abrir el navegador',
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(
                        Icons.language_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Página oficial'),
                      subtitle: const Text('melquisedec-ark.github.io'),
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                      ),
                      onTap: () => _launchUrl(
                        context,
                        'https://melquisedec-ark.github.io',
                        'No se pudo abrir el navegador',
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(
                        Icons.chat_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Comunidad WhatsApp'),
                      subtitle: const Text('Chatea con la comunidad'),
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                      ),
                      onTap: () => _launchUrl(
                        context,
                        'https://chat.whatsapp.com/IjXJP2HUAJjE0Dd4s5TW7I',
                        'No se pudo abrir el navegador',
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Icon(
                        Icons.description_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text('Licencia'),
                      subtitle: const Text(
                        'Permite uso, copia, modificación y distribución del software',
                      ),
                      trailing: Chip(
                        label: const Text('MIT'),
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Atribuciones (C9 follow-up) ──
              // Sección requerida por las licencias de los datasets
              // bundled (openbible.info CC-BY 4.0, scrollmapper MIT).
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.copyright_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Atribuciones',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // CC-BY 4.0
                      Text(
                        'Datos de cross-references bíblicas:',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const _AttributionLine(
                        text:
                            'openbible.info/labs/cross-references/ (CC-BY 4.0)',
                        url: 'https://www.openbible.info/labs/cross-references/',
                      ),
                      const _AttributionLine(
                        text: 'Vía scrollmapper/bible_databases (MIT)',
                        url: 'https://github.com/scrollmapper/bible_databases',
                      ),
                      const _AttributionLine(
                        text:
                            'Derivado de Treasury of Scripture Knowledge '
                            '(dominio público, 1850)',
                      ),
                      const SizedBox(height: 8),
                      // Texto bíblico
                      Text(
                        'Texto bíblico (RV1909):',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Reina Valera 1909 — dominio público',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Botón Volver ──
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(
    BuildContext context,
    String url,
    String errorMsg,
  ) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        _showError(context, errorMsg);
      }
    } catch (_) {
      if (context.mounted) _showError(context, errorMsg);
    }
  }

  void _showError(BuildContext context, String msg) {
    showAppSnackBar(context, msg, type: AppSnackBarType.error);
  }
}

/// Línea de atribución con bullet.
///
/// Si [url] no es `null`, la línea es tappable y abre el navegador.
/// Si es `null`, se muestra como texto plano (sin acción).
class _AttributionLine extends StatelessWidget {
  const _AttributionLine({
    required this.text,
    this.url,
  });

  final String text;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: url != null
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                decoration:
                    url != null ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
    if (url == null) return body;
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url!);
        try {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok && context.mounted) {
            showAppSnackBar(
              context,
              'No se pudo abrir el navegador',
              type: AppSnackBarType.error,
            );
          }
        } catch (_) {
          if (context.mounted) {
            showAppSnackBar(
              context,
              'No se pudo abrir el navegador',
              type: AppSnackBarType.error,
            );
          }
        }
      },
      child: body,
    );
  }
}
