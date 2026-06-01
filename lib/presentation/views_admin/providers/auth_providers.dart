import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/usuario_rol.dart';
import '../../../domain/entities/usuario.dart';

/// Provider que siempre retorna un usuario admin por defecto.
/// La app es local, no requiere autenticación.
final currentUserProvider = Provider<Usuario?>((_) {
  return const Usuario(
    id: 1,
    username: 'admin',
    passwordHash: '',
    nombre: 'Admin',
    rol: UsuarioRol.admin,
  );
});

/// Provider booleano que siempre indica sesión activa.
final isAuthenticatedProvider = Provider<bool>((_) => true);
