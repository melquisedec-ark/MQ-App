import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../core/enums/usuario_rol.dart';
import '../../../core/errors/auth_exception.dart';
import '../../../core/utils/file_storage_service.dart';
import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../../data/models/fondo_pantalla_model.dart';
import '../../entities/usuario.dart';
import '../../entities/fondo_pantalla.dart';

// ─────────────────────────────────────────────────────────────
// GetAllFondosUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para obtener todos los fondos de pantalla.
class GetAllFondosUseCase {
  final CatalogLocalDataSource _dataSource;

  GetAllFondosUseCase(this._dataSource);

  /// Retorna la lista completa de [FondoPantalla] ordenados por nombre.
  Future<List<FondoPantalla>> execute() async {
    final models = await _dataSource.getAllFondos();
    return models.map((m) => m.toEntity()).toList();
  }
}

final getAllFondosUseCaseProvider = Provider<GetAllFondosUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return GetAllFondosUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// CreateFondoUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para crear un nuevo fondo de pantalla.
///
/// Requiere permisos de administrador.
class CreateFondoUseCase {
  final CatalogLocalDataSource _dataSource;

  CreateFondoUseCase(this._dataSource);

  /// Crea un nuevo fondo de pantalla con los datos proporcionados.
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  /// Retorna el ID del fondo creado.
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<int> execute({
    required String nombre,
    required FondoPantallaTipo tipo,
    String? rutaArchivo,
    String? colorHex,
    bool esPredeterminado = false,
    bool activo = true,
    required Usuario admin,
  }) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden crear fondos de pantalla',
      );
    }
    if (nombre.trim().isEmpty) {
      throw const AuthException('El nombre del fondo no puede estar vacío');
    }

    final model = FondoPantallaModel(
      id: 0, // SQLite auto-incrementa
      nombre: nombre.trim(),
      tipo: tipo.value,
      ruta_archivo: rutaArchivo?.trim(),
      color_hex: colorHex?.trim(),
      es_predeterminado: esPredeterminado ? 1 : 0,
      activo: activo ? 1 : 0,
    );

    return await _dataSource.insertFondo(model);
  }
}

final createFondoUseCaseProvider = Provider<CreateFondoUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return CreateFondoUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// UpdateFondoUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para actualizar un fondo de pantalla existente.
///
/// Requiere permisos de administrador.
class UpdateFondoUseCase {
  final CatalogLocalDataSource _dataSource;

  UpdateFondoUseCase(this._dataSource);

  /// Actualiza el fondo de pantalla con los datos proporcionados.
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<void> execute({
    required int id,
    required String nombre,
    required FondoPantallaTipo tipo,
    String? rutaArchivo,
    String? colorHex,
    required bool esPredeterminado,
    required bool activo,
    required Usuario admin,
  }) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden actualizar fondos de pantalla',
      );
    }
    if (nombre.trim().isEmpty) {
      throw const AuthException('El nombre del fondo no puede estar vacío');
    }

    final model = FondoPantallaModel(
      id: id,
      nombre: nombre.trim(),
      tipo: tipo.value,
      ruta_archivo: rutaArchivo?.trim(),
      color_hex: colorHex?.trim(),
      es_predeterminado: esPredeterminado ? 1 : 0,
      activo: activo ? 1 : 0,
    );

    await _dataSource.updateFondo(model);
  }
}

final updateFondoUseCaseProvider = Provider<UpdateFondoUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return UpdateFondoUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// DeleteFondoUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para eliminar un fondo de pantalla.
///
/// Requiere permisos de administrador.
class DeleteFondoUseCase {
  final CatalogLocalDataSource _dataSource;

  DeleteFondoUseCase(this._dataSource);

  /// Elimina el fondo de pantalla con el [id] dado.
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  ///
  /// Además de eliminar el registro en BD, también borra el archivo físico
  /// (imagen/video) del almacenamiento local si existe.
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<void> execute(int id, {required Usuario admin}) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden eliminar fondos de pantalla',
      );
    }

    // 1. Obtener el modelo antes de eliminar (para conocer ruta_archivo)
    final model = await _dataSource.getFondoById(id);

    // 2. Eliminar registro de BD
    await _dataSource.deleteFondo(id);

    // 3. Eliminar archivo físico si está dentro del directorio de la app.
    //    Si el archivo está fuera (galería, etc.), no se toca.
    if (model?.ruta_archivo != null && model!.ruta_archivo!.isNotEmpty) {
      await FileStorageService.deleteIfAppFile(model.ruta_archivo!);
    }
  }
}

final deleteFondoUseCaseProvider = Provider<DeleteFondoUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return DeleteFondoUseCase(dataSource);
});
