import '../../../core/enums/usuario_rol.dart';
import '../../../core/errors/auth_exception.dart';
import '../../entities/usuario.dart';
import '../../entities/pista_audio.dart';
import '../../repositories/pista_audio_repository.dart';

// ─────────────────────────────────────────────────────────────
// GetPistasByHimnoUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para obtener todas las pistas de audio de un himno.
class GetPistasByHimnoUseCase {
  final PistaAudioRepository _repository;

  GetPistasByHimnoUseCase(this._repository);

  /// Retorna la lista de [PistaAudio] asociadas al himno con [himnoId].
  Future<List<PistaAudio>> execute(int himnoId) async {
    return await _repository.getByHimno(himnoId);
  }
}

// ─────────────────────────────────────────────────────────────
// CreatePistaUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para crear una nueva pista de audio.
///
/// Requiere permisos de administrador.
class CreatePistaUseCase {
  final PistaAudioRepository _repository;

  CreatePistaUseCase(this._repository);

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

    return await _repository.create(
      himnoId: himnoId,
      rutaArchivo: rutaArchivo.trim(),
      descripcion: descripcion?.trim(),
      duracionSegundos: duracionSegundos,
      formato: formato?.trim(),
      origen: origen,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DeletePistaUseCase
// ─────────────────────────────────────────────────────────────

/// Caso de uso para eliminar una pista de audio.
///
/// Requiere permisos de administrador.
class DeletePistaUseCase {
  final PistaAudioRepository _repository;

  DeletePistaUseCase(this._repository);

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
    await _repository.delete(id);
  }
}
