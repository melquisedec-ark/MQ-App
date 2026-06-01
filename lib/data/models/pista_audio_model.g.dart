// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pista_audio_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PistaAudioModel _$PistaAudioModelFromJson(Map<String, dynamic> json) =>
    PistaAudioModel(
      id: (json['id'] as num).toInt(),
      himnoId: (json['himno_id'] as num).toInt(),
      rutaArchivo: json['ruta_archivo'] as String,
      descripcion: json['descripcion'] as String?,
      duracionSegundos: (json['duracion_segundos'] as num?)?.toDouble(),
      formato: json['formato'] as String?,
      origen: json['origen'] as String? ?? 'local',
    );

Map<String, dynamic> _$PistaAudioModelToJson(PistaAudioModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'himno_id': instance.himnoId,
      'ruta_archivo': instance.rutaArchivo,
      'descripcion': instance.descripcion,
      'duracion_segundos': instance.duracionSegundos,
      'formato': instance.formato,
      'origen': instance.origen,
    };
