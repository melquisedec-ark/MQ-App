// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_pais_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionPaisModel _$VersionPaisModelFromJson(Map<String, dynamic> json) =>
    VersionPaisModel(
      id: (json['id'] as num).toInt(),
      himnoId: (json['himno_id'] as num).toInt(),
      paisId: (json['pais_id'] as num).toInt(),
      paisNombre: json['pais_nombre'] as String?,
      paisCodigo: json['pais_codigo'] as String?,
      tonalidadOriginal: json['tonalidad_original'] as String,
      activo: json['activo'] as bool? ?? true,
      estrofas: (json['estrofas'] as List<dynamic>?)
          ?.map((e) => EstrofaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VersionPaisModelToJson(VersionPaisModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'himno_id': instance.himnoId,
      'pais_id': instance.paisId,
      'pais_nombre': instance.paisNombre,
      'pais_codigo': instance.paisCodigo,
      'tonalidad_original': instance.tonalidadOriginal,
      'activo': instance.activo,
      'estrofas': instance.estrofas,
    };
