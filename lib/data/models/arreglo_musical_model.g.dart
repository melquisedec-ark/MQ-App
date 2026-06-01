// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arreglo_musical_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArregloMusicalModel _$ArregloMusicalModelFromJson(Map<String, dynamic> json) =>
    ArregloMusicalModel(
      id: (json['id'] as num).toInt(),
      versionPaisId: (json['version_pais_id'] as num).toInt(),
      usuarioId: (json['usuario_id'] as num).toInt(),
      nombreArreglo: json['nombre_arreglo'] as String,
      tonalidadBase: json['tonalidad_base'] as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      estrofas: (json['estrofas'] as List<dynamic>?)
          ?.map((e) => EstrofaArregloModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ArregloMusicalModelToJson(
        ArregloMusicalModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version_pais_id': instance.versionPaisId,
      'usuario_id': instance.usuarioId,
      'nombre_arreglo': instance.nombreArreglo,
      'tonalidad_base': instance.tonalidadBase,
      'version': instance.version,
      'estrofas': instance.estrofas,
    };
