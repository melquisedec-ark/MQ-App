import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/usuario_rol.dart';

part 'usuario.freezed.dart';

/// Entidad de dominio que representa un usuario del sistema de arreglos.
@freezed
class Usuario with _$Usuario {
  const factory Usuario({
    required int id,
    required String username,
    required String passwordHash,
    required String nombre,
    @Default(UsuarioRol.musico) UsuarioRol rol,
  }) = _Usuario;
}
