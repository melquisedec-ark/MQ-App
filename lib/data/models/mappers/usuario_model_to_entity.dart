import '../../../core/enums/usuario_rol.dart';
import '../../../domain/entities/usuario.dart';
import '../usuario_model.dart';

/// Extensión para convertir UsuarioModel a entidad de dominio.
extension UsuarioModelX on UsuarioModel {
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
}

extension UsuarioModelListX on List<UsuarioModel> {
  List<Usuario> toEntities() => map((m) => m.toEntity()).toList();
}
