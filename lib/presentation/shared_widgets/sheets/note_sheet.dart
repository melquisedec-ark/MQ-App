import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/pista_audio.dart';
import '../../dual_mode_wrapper/dual_mode_providers.dart';
import '../../views_personal/providers/audio_providers.dart';

// =============================================================================
// 2. Note (Nota) — Audio tracks sheet
// =============================================================================

/// Muestra el sheet de pistas de audio para un himno.
void showNoteSheet(
  BuildContext context, {
  required WidgetRef ref,
  required int himnoId,
  int? currentPistaId,
  required ValueChanged<int> onPlayPista,
  required VoidCallback onStop,
}) {
  final isDesktop = ref.read(isDesktopModeProvider);

  if (isDesktop) {
    // ── Desktop: Dialog sin drag handle ──
    showDialog<void>(
      context: context,
      builder: (_) {
        final colorScheme = Theme.of(_).colorScheme;
        final textTheme = Theme.of(_).textTheme;
        final isPlaying = ref.watch(isAudioPlayingProvider);

        return Dialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: _noteSheetContent(
                colorScheme: colorScheme,
                textTheme: textTheme,
                ref: ref,
                himnoId: himnoId,
                currentPistaId: currentPistaId,
                isPlaying: isPlaying,
                onPlayPista: onPlayPista,
                onStop: onStop,
              ),
            ),
          ),
        );
      },
    );
  } else {
    // ── Móvil: ModalBottomSheet ──
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        final colorScheme = Theme.of(_).colorScheme;
        final textTheme = Theme.of(_).textTheme;
        final isPlaying = ref.watch(isAudioPlayingProvider);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Handle (solo móvil)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _noteSheetContent(
                colorScheme: colorScheme,
                textTheme: textTheme,
                ref: ref,
                himnoId: himnoId,
                currentPistaId: currentPistaId,
                isPlaying: isPlaying,
                onPlayPista: onPlayPista,
                onStop: onStop,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Contenido compartido del sheet Nota (título + pistas).
Widget _noteSheetContent({
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  required WidgetRef ref,
  required int himnoId,
  int? currentPistaId,
  required bool isPlaying,
  required ValueChanged<int> onPlayPista,
  required VoidCallback onStop,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Icon(
            Icons.audiotrack,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Pistas de audio',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<PistaAudio>>(
        future: ref.read(audioRepositoryProvider).getByHimno(himnoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Error al cargar pistas',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          }

          final pistas = snapshot.data ?? <PistaAudio>[];

          if (pistas.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.audio_file,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay pistas de audio disponibles para este himno',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: pistas.map((PistaAudio pista) {
              final fileName = pista.rutaArchivo.split('/').last;
              final isThisPistaPlaying = isPlaying && currentPistaId == pista.id;
              return ListTile(
                leading: IconButton(
                  icon: Icon(
                    isThisPistaPlaying
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: isThisPistaPlaying
                        ? colorScheme.error
                        : colorScheme.secondary,
                  ),
                  onPressed: () {
                    if (isThisPistaPlaying) {
                      onStop();
                    } else {
                      onPlayPista(pista.id);
                    }
                  },
                ),
                title: Text(
                  pista.descripcion ?? fileName,
                  style: textTheme.bodyLarge,
                ),
                subtitle: pista.duracionSegundos != null
                    ? Text(
                        _formatDuration(pista.duracionSegundos!),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.music_note),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

String _formatDuration(double seconds) {
  final totalSec = seconds.round();
  final min = totalSec ~/ 60;
  final sec = totalSec % 60;
  return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}