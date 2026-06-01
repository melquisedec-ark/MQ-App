import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connection_state.dart';
import '../../views_projection/providers/connection_providers.dart';
import '../../views_projection/providers/live_control_providers.dart';
import 'receptor_binding.dart';

/// Pantalla de Standby (Espera) para Display en modo Receptor.
///
/// Se muestra cuando el dispositivo actúa como Receptor y no hay un himno
/// cargado. Fondo NEGRO intencional (para proyector/pantalla externa).
///
/// Incluye:
/// - Badge "📡 MODO RECEPTOR" en la parte superior
/// - Animación de pulso en el ícono de conexión
/// - Nombre del display y puerto del servidor gRPC
/// - Instrucciones para conectar desde el móvil
/// - Botón visible para salir del modo Receptor
class StandbyScreen extends ConsumerWidget {
  const StandbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final serverInfo = ref.watch(receptorInfoProvider);
    final liveState = ref.watch(liveControlProvider);

    final bool hasActiveSession = liveState.hymn != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Badge: MODO RECEPTOR ──
                _buildReceiverBadge(colors, textTheme),
                const SizedBox(height: 32),

                // ── Logo / ícono principal ──
                _buildLogo(colors),
                const SizedBox(height: 48),

                // ── Título principal ──
                Text(
                  'MQ App',
                  style: textTheme.displayLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Subtítulo ──
                Text(
                  hasActiveSession
                      ? 'Proyección activa'
                      : 'Esperando conexión del controlador...',
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // ── Indicador animado de pulso ──
                if (!hasActiveSession) ...[
                  const _PulseIndicator(),
                  const SizedBox(height: 48),
                ],

                // ── Instrucciones breves ──
                Text(
                  'Conéctate desde tu móvil',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Abre la aplicación MQ App en tu dispositivo móvil '
                  'para conectar y controlar la proyección.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.primary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Información del servidor o estado de no disponible ──
                _buildServerInfo(colors, textTheme, serverInfo),
                const SizedBox(height: 32),

                // ── Botón para salir del modo Receptor ──
                _buildExitButton(colors, textTheme, ref, serverInfo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Badge "📡 MODO RECEPTOR" en la parte superior.
  Widget _buildReceiverBadge(ColorScheme colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        '📡 MODO RECEPTOR',
        style: textTheme.labelLarge?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Contenedor con información del servidor (nombre y puerto).
  ///
  /// Cuando el servidor gRPC no está disponible ([ReceptorInfo.isRunning] es
  /// `false`), muestra un estado alternativo con indicador amarillo/naranja
  /// y el mensaje "Servidor gRPC no disponible".
  Widget _buildServerInfo(
    ColorScheme colors,
    TextTheme textTheme,
    ReceptorInfo serverInfo,
  ) {
    if (!serverInfo.isRunning) {
      // ── Estado: servidor gRPC no disponible ──
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: colors.tertiary.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 18,
                  color: colors.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Servidor gRPC no disponible',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'El modo Receptor requiere un PC con Linux, macOS o Windows.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.primary.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // ── Estado normal: servidor disponible ──
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cast_rounded,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                serverInfo.displayName,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_rounded,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Puerto: ${serverInfo.port}',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Botón para salir del modo Receptor, con estilo visible.
  ///
  /// Resetea [ConnectionRole] a `none` (no [DeviceMode]) para evitar
  /// el crash descrito en Bug 2.
  ///
  /// Cuando el servidor gRPC no está disponible, muestra "Volver" en
  /// lugar de "Salir del modo Receptor".
  Widget _buildExitButton(
    ColorScheme colors,
    TextTheme textTheme,
    WidgetRef ref,
    ReceptorInfo serverInfo,
  ) {
    final String label;
    final IconData icon;

    if (!serverInfo.isRunning) {
      label = 'Volver';
      icon = Icons.arrow_back_rounded;
    } else {
      label = 'Salir del modo Receptor';
      icon = Icons.exit_to_app_rounded;
    }

    return OutlinedButton.icon(
      onPressed: () {
        ref.read(connectionRoleProvider.notifier).state = ConnectionRole.none;
        ref.read(connectionStateProvider.notifier).disconnect();
      },
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.error,
        side: BorderSide(color: colors.error.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
      ),
    );
  }

  /// Construye un círculo con el ícono de nota musical.
  Widget _buildLogo(ColorScheme colors) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: 64,
        color: colors.primary.withValues(alpha: 0.4),
      ),
    );
  }
}

/// Indicador de pulso animado que oscila la opacidad infinitamente.
///
/// Se compone de un ícono [Icons.cast_connected] que pulsa
/// entre opacidad 0.3 y 1.0, y un texto "Esperando controlador..."
class _PulseIndicator extends StatefulWidget {
  const _PulseIndicator();

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _pulseAnimation,
          child: Icon(
            Icons.cast_connected,
            size: 48,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Esperando controlador...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.primary.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}
