// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'himno_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HimnoModel _$HimnoModelFromJson(Map<String, dynamic> json) => HimnoModel(
      id: (json['id'] as num).toInt(),
      tituloPrincipal: json['titulo_principal'] as String,
      numeroOficial: (json['numero_oficial'] as num?)?.toInt(),
      tipo: (json['tipo'] as num).toInt(),
      activo: json['activo'] as bool? ?? true,
      versiones: (json['versiones'] as List<dynamic>?)
          ?.map((e) => VersionPaisModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      categorias: (json['categorias'] as List<dynamic>?)
          ?.map((e) => CategoriaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HimnoModelToJson(HimnoModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titulo_principal': instance.tituloPrincipal,
      'numero_oficial': instance.numeroOficial,
      'tipo': instance.tipo,
      'activo': instance.activo,
      'versiones': instance.versiones,
      'categorias': instance.categorias,
    };
