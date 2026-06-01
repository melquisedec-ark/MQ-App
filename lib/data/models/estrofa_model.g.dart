// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estrofa_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EstrofaModel _$EstrofaModelFromJson(Map<String, dynamic> json) => EstrofaModel(
      id: (json['id'] as num).toInt(),
      versionPaisId: (json['version_pais_id'] as num).toInt(),
      tipo: json['tipo'] as String,
      orden: (json['orden'] as num).toInt(),
      contenido: json['contenido'] as String,
    );

Map<String, dynamic> _$EstrofaModelToJson(EstrofaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version_pais_id': instance.versionPaisId,
      'tipo': instance.tipo,
      'orden': instance.orden,
      'contenido': instance.contenido,
    };
