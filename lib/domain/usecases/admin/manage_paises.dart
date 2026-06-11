import '../../../core/enums/usuario_rol.dart';
import '../../../core/errors/auth_exception.dart';
import '../../entities/usuario.dart';
import '../../entities/pais.dart';
import '../../repositories/pais_repository.dart';

// ─────────────────────────────────────────────────────────────
// GetAllPaisesUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para obtener la lista de países.
class GetAllPaisesUseCase {
  final PaisRepository _dataSource;

  GetAllPaisesUseCase(this._dataSource);

    /// Retorna una lista de [Pais] ordenados alfabéticamente.
  Future<List<Pais>> execute() async {
    return await _dataSource.getAll();
  }
}


// ─────────────────────────────────────────────────────────────
// CreatePaisUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para crear un nuevo país.
///
/// Requiere permisos de administrador.
class CreatePaisUseCase {
  final PaisRepository _dataSource;

  CreatePaisUseCase(this._dataSource);

  /// Crea un país con [nombre] y opcional [codigo].
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  /// Retorna el ID del país creado.
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<int> execute({required String nombre, String? codigo, required Usuario admin}) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden crear países',
      );
    }
    if (nombre.trim().isEmpty) {
      throw const AuthException('El nombre del país no puede estar vacío');
    }
    return await _dataSource.create(nombre: nombre.trim(), codigo: codigo?.trim());
  }
}


// ─────────────────────────────────────────────────────────────
// UpdatePaisUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para actualizar un país existente.
///
/// Requiere permisos de administrador.
class UpdatePaisUseCase {
  final PaisRepository _dataSource;

  UpdatePaisUseCase(this._dataSource);

  /// Actualiza los datos del país con el [id] dado.
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<void> execute({required int id, required String nombre, String? codigo, required Usuario admin}) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden actualizar países',
      );
    }
    if (nombre.trim().isEmpty) {
      throw const AuthException('El nombre del país no puede estar vacío');
    }
    await _dataSource.update(
      id: id,
      nombre: nombre.trim(),
      codigo: codigo?.trim(),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// DeletePaisUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para eliminar un país.
///
/// Requiere permisos de administrador.
class DeletePaisUseCase {
  final PaisRepository _dataSource;

  DeletePaisUseCase(this._dataSource);

  /// Elimina el país con el [id] dado.
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<void> execute(int id, {required Usuario admin}) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden eliminar países',
      );
    }
    await _dataSource.delete(id);
  }
}
