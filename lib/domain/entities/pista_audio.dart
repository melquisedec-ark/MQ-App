import 'package:freezed_annotation/freezed_annotation.dart';

part 'pista_audio.freezed.dart';

/// Entidad de dominio que representa una pista de audio asociada a un himno.
@freezed
class PistaAudio with _$PistaAudio {
  const factory PistaAudio({
    required int id,
    required int himnoId,
    required String rutaArchivo,
    String? descripcion,
    double? duracionSegundos,
    String? formato,
  }) = _PistaAudio;
}
