// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estrofa_arreglo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EstrofaArregloModel _$EstrofaArregloModelFromJson(Map<String, dynamic> json) =>
    EstrofaArregloModel(
      id: (json['id'] as num).toInt(),
      arregloMusicalId: (json['arreglo_musical_id'] as num).toInt(),
      tipo: json['tipo'] as String,
      orden: (json['orden'] as num).toInt(),
      contenido: json['contenido'] as String,
    );

Map<String, dynamic> _$EstrofaArregloModelToJson(
        EstrofaArregloModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'arreglo_musical_id': instance.arregloMusicalId,
      'tipo': instance.tipo,
      'orden': instance.orden,
      'contenido': instance.contenido,
    };
