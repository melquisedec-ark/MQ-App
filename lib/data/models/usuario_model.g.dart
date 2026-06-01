// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioModel _$UsuarioModelFromJson(Map<String, dynamic> json) => UsuarioModel(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      passwordHash: json['passwordHash'] as String,
      nombre: json['nombre'] as String,
      rol: json['rol'] as String? ?? 'Musico',
    );

Map<String, dynamic> _$UsuarioModelToJson(UsuarioModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'passwordHash': instance.passwordHash,
      'nombre': instance.nombre,
      'rol': instance.rol,
    };
