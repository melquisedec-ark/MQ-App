import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/usuario_rol.dart';
import '../../../core/errors/auth_exception.dart';
import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../../data/models/pista_audio_model.dart';
import '../../entities/usuario.dart';
import '../../entities/pista_audio.dart';

// ─────────────────────────────────────────────────────────────
// GetPistasByHimnoUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para obtener todas las pistas de audio de un himno.
class GetPistasByHimnoUseCase {
  final CatalogLocalDataSource _dataSource;

  GetPistasByHimnoUseCase(this._dataSource);

  /// Retorna la lista de [PistaAudio] asociadas al himno con [himnoId].
  Future<List<PistaAudio>> execute(int himnoId) async {
    final models = await _dataSource.getPistasByHimno(himnoId);
    return models.map((m) => m.toEntity()).toList();
  }
}

final getPistasByHimnoUseCaseProvider =
    Provider<GetPistasByHimnoUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return GetPistasByHimnoUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// CreatePistaUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para crear una nueva pista de audio.
///
/// Requiere permisos de administrador.
class CreatePistaUseCase {
  final CatalogLocalDataSource _dataSource;

  CreatePistaUseCase(this._dataSource);

  /// Crea una nueva pista de audio para el himno con [himnoId].
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  /// Retorna el ID de la pista creada.
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<int> execute({
    required int himnoId,
    required String rutaArchivo,
    String? descripcion,
    double? duracionSegundos,
    String? formato,
    String origen = 'local',
    required Usuario admin,
  }) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden crear pistas de audio',
      );
    }
    if (rutaArchivo.trim().isEmpty) {
      throw const AuthException('La ruta del archivo no puede estar vacía');
    }

    final model = PistaAudioModel(
      id: 0, // SQLite auto-incrementa
      himnoId: himnoId,
      rutaArchivo: rutaArchivo.trim(),
      descripcion: descripcion?.trim(),
      duracionSegundos: duracionSegundos,
      formato: formato?.trim(),
      origen: origen,
    );

    return await _dataSource.insertPista(model);
  }
}

final createPistaUseCaseProvider = Provider<CreatePistaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return CreatePistaUseCase(dataSource);
});

// ─────────────────────────────────────────────────────────────
// DeletePistaUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para eliminar una pista de audio.
///
/// Requiere permisos de administrador.
class DeletePistaUseCase {
  final CatalogLocalDataSource _dataSource;

  DeletePistaUseCase(this._dataSource);

  /// Elimina la pista de audio con el [id] dado.
  ///
  /// [admin] es el usuario que ejecuta la operación; debe tener rol [UsuarioRol.admin].
  ///
  /// Lanza [AuthException] si [admin] no es administrador.
  Future<void> execute(int id, {required Usuario admin}) async {
    if (admin.rol != UsuarioRol.admin) {
      throw const AuthException(
        'Solo administradores pueden eliminar pistas de audio',
      );
    }
    await _dataSource.deletePista(id);
  }
}

final deletePistaUseCaseProvider = Provider<DeletePistaUseCase>((ref) {
  final dataSource = CatalogLocalDataSource();
  return DeletePistaUseCase(dataSource);
});
