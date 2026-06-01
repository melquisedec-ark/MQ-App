import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/usuario_rol.dart';
import '../../../core/errors/auth_exception.dart';
import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../../data/models/pais_model.dart';
import '../../entities/usuario.dart';

// ─────────────────────────────────────────────────────────────
// GetAllPaisesUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para obtener la lista de países.
class GetAllPaisesUseCase {
  final CatalogLocalDataSource _dataSource;

  GetAllPaisesUseCase(this._dataSource);

  /// Retorna una lista de [PaisModel] ordenados alfabéticamente.
  Future<List<PaisModel>> execute() async {
    return await _dataSource.getAllPaises();
  }
}

final getAllPaisesUseCaseProvider = Provider<GetAllPaisesUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return GetAllPaisesUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// CreatePaisUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para crear un nuevo país.
///
/// Requiere permisos de administrador.
class CreatePaisUseCase {
  final CatalogLocalDataSource _dataSource;

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
    return await _dataSource.insertPais(nombre.trim(), codigo: codigo?.trim());
  }
}

final createPaisUseCaseProvider = Provider<CreatePaisUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return CreatePaisUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// UpdatePaisUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para actualizar un país existente.
///
/// Requiere permisos de administrador.
class UpdatePaisUseCase {
  final CatalogLocalDataSource _dataSource;

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
    await _dataSource.updatePais(
      PaisModel(id: id, nombre: nombre.trim(), codigo: codigo?.trim()),
    );
  }
}

final updatePaisUseCaseProvider = Provider<UpdatePaisUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return UpdatePaisUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// DeletePaisUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para eliminar un país.
///
/// Requiere permisos de administrador.
class DeletePaisUseCase {
  final CatalogLocalDataSource _dataSource;

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
    await _dataSource.deletePais(id);
  }
}

final deletePaisUseCaseProvider = Provider<DeletePaisUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return DeletePaisUseCase(dataSource);
});
