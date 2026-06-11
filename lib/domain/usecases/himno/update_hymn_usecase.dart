import '../../../core/errors/auth_exception.dart';
import '../../../core/errors/failures.dart';
import '../../entities/himno.dart';
import '../../repositories/hymn_repository.dart';

/// Caso de uso para actualizar un himno completo con sus versiones,
/// estrofas y categorías.
///
/// Requiere que el usuario esté autenticado (administrador).
class UpdateHymnUseCase {
  final HymnRepository _repository;

  UpdateHymnUseCase(this._repository);

  /// Actualiza un himno y todos sus datos asociados.
  ///
  /// [himno] entidad de dominio con los datos actualizados del himno.
  ///   El campo [Himno.id] se usa para identificar el himno a modificar.
  /// [versiones] lista de mapas con datos de versiones de país.
  /// [estrofas] lista de mapas con datos de estrofas (cada una debe incluir
  ///   `version_idx` apuntando al índice en [versiones]).
  /// [categoriaIds] IDs de categorías a asociar.
  /// [isAdmin] indica si el usuario tiene permisos de administrador.
  ///
  /// Lanza [AuthException] si el usuario no está autenticado.
  /// Lanza [InvalidArgumentFailure] si los datos son inválidos.
  /// Lanza [DatabaseFailure] si ocurre un error en la base de datos.
  Future<void> execute(
    Himno himno,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds, {
    required bool isAdmin,
  }) async {
    if (!isAdmin) {
      throw const AuthException(
        'Solo administradores pueden actualizar himnos',
      );
    }

    if (himno.id <= 0) {
      throw const InvalidArgumentFailure('ID de himno inválido');
    }

    if (himno.titulo.trim().isEmpty) {
      throw const InvalidArgumentFailure('El título del himno es obligatorio');
    }

    if (versiones.isEmpty) {
      throw const InvalidArgumentFailure(
        'Debe proporcionar al menos una versión de país',
      );
    }

    await _repository.updateHymn(himno, versiones, estrofas, categoriaIds);
  }
}


