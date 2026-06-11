import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../core/enums/usuario_rol.dart';
import '../../../core/errors/auth_exception.dart';
import '../../../core/utils/file_storage_service.dart';
import '../../entities/usuario.dart';
import '../../entities/fondo_pantalla.dart';
import '../../repositories/fondo_pantalla_repository.dart';

// ─────────────────────────────────────────────────────────────
// GetAllFondosUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para obtener todos los fondos de pantalla.
class GetAllFondosUseCase {
  final FondoPantallaRepository _repository;

  GetAllFondosUseCase(this._repository);

  /// Retorna la lista completa de [FondoPantalla] ordenados por nombre.
  Future<List<FondoPantalla>> execute() async {
    return await _repository.getAll();
  }
}

// ─────────────────────────────────────────────────────────────
// CreateFondoUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para crear un nuevo fondo de pantalla.
///
/// Requiere permisos de administrador.
class CreateFondoUseCase {
  final FondoPantallaRepository _repository;

  CreateFondoUseCase(this._repository);

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

    return await _repository.create(
      nombre: nombre.trim(),
      tipo: tipo,
      rutaArchivo: rutaArchivo?.trim(),
      colorHex: colorHex?.trim(),
      esPredeterminado: esPredeterminado,
      activo: activo,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// UpdateFondoUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para actualizar un fondo de pantalla existente.
///
/// Requiere permisos de administrador.
class UpdateFondoUseCase {
  final FondoPantallaRepository _repository;

  UpdateFondoUseCase(this._repository);

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

    await _repository.update(
      id: id,
      nombre: nombre.trim(),
      tipo: tipo,
      rutaArchivo: rutaArchivo?.trim(),
      colorHex: colorHex?.trim(),
      esPredeterminado: esPredeterminado,
      activo: activo,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DeleteFondoUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para eliminar un fondo de pantalla.
///
/// Requiere permisos de administrador.
class DeleteFondoUseCase {
  final FondoPantallaRepository _repository;

  DeleteFondoUseCase(this._repository);

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

    // 1. Obtener el fondo antes de eliminar (para conocer ruta_archivo)
    final fondo = await _repository.getById(id);

    // 2. Eliminar registro de BD
    await _repository.delete(id);

    // 3. Eliminar archivo físico si está dentro del directorio de la app.
    //    Si el archivo está fuera (galería, etc.), no se toca.
    if (fondo?.rutaArchivo != null && fondo!.rutaArchivo!.isNotEmpty) {
      await FileStorageService.deleteIfAppFile(fondo.rutaArchivo!);
    }
  }
}
