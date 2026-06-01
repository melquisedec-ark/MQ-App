import 'package:json_annotation/json_annotation.dart';

import '../../core/enums/usuario_rol.dart';
import '../../domain/entities/usuario.dart';

part 'usuario_model.g.dart';

/// Modelo serializable de Usuario.
@JsonSerializable()
class UsuarioModel {
  final int id;
  final String username;
  final String passwordHash;
  final String nombre;
  final String rol;

  const UsuarioModel({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.nombre,
    this.rol = 'Musico',
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) =>
      _$UsuarioModelFromJson(json);

  Map<String, dynamic> toJson() => _$UsuarioModelToJson(this);

  Usuario toEntity() {
    return Usuario(
      id: id,
      username: username,
      passwordHash: passwordHash,
      nombre: nombre,
      rol: _mapRol(rol),
    );
  }

  UsuarioRol _mapRol(String value) {
    return UsuarioRol.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UsuarioRol.musico,
    );
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] as int,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      nombre: map['nombre'] as String,
      rol: map['rol'] as String? ?? 'Musico',
    );
  }

  /// Convierte a mapa para SQLite (columnas snake_case).
  /// Si [includeId] es `false`, omite el campo `id` (útil para inserts
  /// donde SQLite debe auto-incrementar).
  Map<String, dynamic> toMap({bool includeId = true}) {
    final map = <String, dynamic>{
      'username': username,
      'password_hash': passwordHash,
      'nombre': nombre,
      'rol': rol,
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }
}
