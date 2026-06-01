import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/usuario_rol.dart';
import '../../../core/errors/auth_exception.dart';
import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../entities/usuario.dart';
import '../../entities/categoria.dart';

// ─────────────────────────────────────────────────────────────
// GetAllCategoriasUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para obtener todas las categorías.
class GetAllCategoriasUseCase {
  final CatalogLocalDataSource _dataSource;

  GetAllCategoriasUseCase(this._dataSource);

  /// Retorna la lista completa de [Categoria] ordenadas alfabéticamente.
  Future<List<Categoria>> execute() async {
    final models = await _dataSource.getAllCategorias();
    return models.map((m) => m.toEntity()).toList();
  }
}

final getAllCategoriasUseCaseProvider =
    Provider<GetAllCategoriasUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return GetAllCategoriasUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// CreateCategoriaUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para crear una nueva categoría.
///
/// Requiere permisos de administrador.
class CreateCategoriaUseCase {
  final CatalogLocalDataSource _dataSource;

  CreateCategoriaUseCase(this._dataSource);

  /// Crea una categoría con el [nombre] dado.
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  /// Retorna el ID de la categoría creada.
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<int> execute(String nombre, {required Usuario admin}) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden crear categorías',
      );
    }
    if (nombre.trim().isEmpty) {
      throw const AuthException('El nombre de la categoría no puede estar vacío');
    }
    return await _dataSource.insertCategoria(nombre.trim());
  }
}

final createCategoriaUseCaseProvider =
    Provider<CreateCategoriaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return CreateCategoriaUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// DeleteCategoriaUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para eliminar una categoría.
///
/// Requiere permisos de administrador.
class DeleteCategoriaUseCase {
  final CatalogLocalDataSource _dataSource;

  DeleteCategoriaUseCase(this._dataSource);

  /// Elimina la categoría con el [id] dado.
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<void> execute(int id, {required Usuario admin}) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden eliminar categorías',
      );
    }
    await _dataSource.deleteCategoria(id);
  }
}

final deleteCategoriaUseCaseProvider =
    Provider<DeleteCategoriaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return DeleteCategoriaUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// UpdateCategoriaUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para actualizar el nombre de una categoría.
///
/// Requiere permisos de administrador.
class UpdateCategoriaUseCase {
  final CatalogLocalDataSource _dataSource;

  UpdateCategoriaUseCase(this._dataSource);

  /// Actualiza el nombre de la categoría con [id].
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<void> execute(int id, String nombre, {required Usuario admin}) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden actualizar categorías',
      );
    }
    if (nombre.trim().isEmpty) {
      throw const AuthException(
        'El nombre de la categoría no puede estar vacío',
      );
    }
    await _dataSource.updateCategoria(id, nombre.trim());
  }
}

final updateCategoriaUseCaseProvider =
    Provider<UpdateCategoriaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return UpdateCategoriaUseCase(dataSource);
});
