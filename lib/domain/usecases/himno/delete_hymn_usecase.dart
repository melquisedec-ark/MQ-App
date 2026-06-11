import '../../../core/errors/auth_exception.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/hymn_repository.dart';

/// Caso de uso para eliminar (soft-delete) un himno.
///
/// Requiere que el usuario esté autenticado (administrador) y verifica
/// que el himno no tenga referencias activas en otras tablas antes de
/// proceder con la eliminación.
class DeleteHymnUseCase {
  final HymnRepository _repository;

  DeleteHymnUseCase(this._repository);

  /// Elimina un himno por su ID.
  ///
  /// Primero verifica que el himno no tenga referencias en arreglos
  /// musicales, pistas de audio o historial de reproducción.
  ///
  /// [himnoId] ID del himno a eliminar.
  /// [isAdmin] indica si el usuario tiene permisos de administrador.
  ///
  /// Lanza [AuthException] si el usuario no está autenticado.
  /// Lanza [InvalidArgumentFailure] si el ID es inválido.
  /// Lanza [DatabaseFailure] si el himno tiene referencias activas
  ///   o si ocurre un error en la base de datos.
  Future<void> execute(
    int himnoId, {
    required bool isAdmin,
  }) async {
    if (!isAdmin) {
      throw const AuthException(
        'Solo administradores pueden eliminar himnos',
      );
    }

    if (himnoId <= 0) {
      throw const InvalidArgumentFailure('ID de himno inválido');
    }

    // Verificar referencias antes de eliminar
    final hasReferences = await _repository.hymnHasReferences(himnoId);
    if (hasReferences) {
      throw const DatabaseFailure(
        'No se puede eliminar el himno porque tiene referencias en '
        'arreglos musicales, pistas de audio o historial de reproducción',
      );
    }

    await _repository.deleteHymn(himnoId);
  }
}


