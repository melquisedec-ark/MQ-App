import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/pista_audio.dart';

part 'pista_audio_model.g.dart';

/// Modelo serializable de PistaAudio.
@JsonSerializable()
class PistaAudioModel {
  final int id;
  @JsonKey(name: 'himno_id')
  final int himnoId;
  @JsonKey(name: 'ruta_archivo')
  final String rutaArchivo;
  final String? descripcion;
  @JsonKey(name: 'duracion_segundos')
  final double? duracionSegundos;
  final String? formato;
  final String origen;

  const PistaAudioModel({
    required this.id,
    required this.himnoId,
    required this.rutaArchivo,
    this.descripcion,
    this.duracionSegundos,
    this.formato,
    this.origen = 'local',
  });

  factory PistaAudioModel.fromJson(Map<String, dynamic> json) =>
      _$PistaAudioModelFromJson(json);

  Map<String, dynamic> toJson() => _$PistaAudioModelToJson(this);

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

  factory PistaAudioModel.fromMap(Map<String, dynamic> map) {
    return PistaAudioModel(
      id: map['id'] as int,
      himnoId: map['himno_id'] as int,
      rutaArchivo: map['ruta_archivo'] as String,
      descripcion: map['descripcion'] as String?,
      duracionSegundos: (map['duracion_segundos'] as num?)?.toDouble(),
      formato: map['formato'] as String?,
      origen: map['origen'] as String? ?? 'local',
    );
  }
}
