// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fondo_pantalla_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FondoPantallaModel _$FondoPantallaModelFromJson(Map<String, dynamic> json) =>
    FondoPantallaModel(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      ruta_archivo: json['ruta_archivo'] as String?,
      color_hex: json['color_hex'] as String?,
      es_predeterminado: (json['es_predeterminado'] as num?)?.toInt() ?? 0,
      activo: (json['activo'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$FondoPantallaModelToJson(FondoPantallaModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'tipo': instance.tipo,
      'ruta_archivo': instance.ruta_archivo,
      'color_hex': instance.color_hex,
      'es_predeterminado': instance.es_predeterminado,
      'activo': instance.activo,
    };
