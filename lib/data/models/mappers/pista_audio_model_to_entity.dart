import '../../../domain/entities/pista_audio.dart';
import '../pista_audio_model.dart';

/// Extensión para convertir PistaAudioModel a entidad de dominio.
extension PistaAudioModelX on PistaAudioModel {
  PistaAudio toEntity() {
    return PistaAudio(
      id: id,
      himnoId: himnoId,
      rutaArchivo: rutaArchivo,
      descripcion: descripcion,
      duracionSegundos: duracionSegundos,
      formato: formato,
    );
  }
}

extension PistaAudioModelListX on List<PistaAudioModel> {
  List<PistaAudio> toEntities() => map((m) => m.toEntity()).toList();
}
